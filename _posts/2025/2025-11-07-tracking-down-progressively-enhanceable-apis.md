---
title: "Tracking Down Progressively-Enhanceable APIs"
tags: design crystal
---

Something that I'm a big fan of is [APIs that can be easily modified and hacked with](/2024/02/28/optimising-for-modification/). It's frustrating to have to write fully production-ready code when you actually want to just prototype something, and so I'm happy when there's an API that it's easy to use, which then progresses into a more full-featured API.

In Crystal an example of this is `File.read`. If you want to get the entire contents of a file you can just do:

```crystal
contents = File.read(path)
# process contents as a String
```

Will this cause problems if the file is huge? Probably, but it works fine for a prototype or in something less critical. Then when you want to be a grown-up and do things properly, the API doesn't actually change that much:

```crystal
File.open(path) do |io|
  # use the IO to process the contents of the file
end
```

What I didn't know is that there are a more of these APIs hiding in the Crystal stdlib that I wasn't aware of. I found these after I captured a profile of my [status page library](https://codeberg.org/willhbr/status_page), it's plenty fast enough (especially because I'm the only person ever sending requests) but I was interested to see what it spent its time doing.

I captured the sample using [samply](https://github.com/mstange/samply) which is super convenient. I built it from the main branch so I could use the `--presymbolicate` flag. This dumps the symbol info directly into the profile file, since running a local web server and having the Firefox profiler talk back to it runs into all sorts of security roadblocks, especially when it's not actually running locally.

To get some nice juicy data, I wrote another little program that would just spam a certain URL with HTTP requests, compiled with `--release -Dpreview_mt` to make the most of my cores:

```crystal
require "http/client"

uri = URI.parse ARGV[0]
path = uri.path

8.times do |i|
 Thread.new do
   client = HTTP::Client.new(uri)
   20000.times do
     client.get path
   end
   puts "Done #{i}"
 end
end

sleep
```

Unsurprisingly, after getting the profile I can confirm it spends its time dumping bytes into the response buffer, since there's no interesting calculation on my default `/status` page. However there were two interesting sections that were taking more time than I expected.

The first is `HTML.escape`, which replaces characters that could be interpreted as HTML tags with the corresponding HTML entity. I noticed two things, first it immediately calls into `String#gsub`, and inside that there's a `malloc` call. My first thought was maybe it's implemented with a regex that's convenient but not performant, but looking [at the docs][html-escape] and the code, that's not the case, it uses a `Hash(Char, String)` to make replacements with by looking up each character in the string with its replacement in the hash.

[html-escape]: https://crystal-lang.org/api/1.18.2/HTML.html#escape%28string%3AString%29%3AString-class-method

The `malloc` revealed the real issue though, `HTML.escape` takes a string and returns a new string with the escapes applied, and that new string has to be allocated. In my code I took that string and immediately dumped it into an `IO`:

```crystal
@io << ' ' << key << "=\"" << HTML.escape(value.to_s) << '"'
```

Look at that, I'm using the wrong API! That's convenient, but it would be better if `HTML.escape` would write directly into `@io` instead of allocating its own buffer. Well that's what `HTML.escape(string : String, io : IO)` does, and it's trivial to swap:

```crystal
@io << ' ' << k << "=\""
HTML.escape(value.to_s, @io)
@io << '"'
```

Re-profiled, and that section is gone from the trace. Easy.

Removing the non-`IO` API isn't a good move here, since you'll just encourage people to do this:

```crystal
escaped = String.build { |io| HTML.escape(value, io) }
```

Since what they _want_ right now is a `String`, not a lecture about why not to allocate short-lived buffers.

The second thing that stood out were calls to `IO::Memory#increase_capacity_by`. `IO::Memory` is a dynamically-sized in-memory buffer, and the default capacity (as of Crystal 1.18.2) is just 64 bytes. When a write would exceed the size of the buffer, the capacity is increased to the next power of two with `Math.pw2ceil`, so as soon as we write our 65th byte, it'll be increased to 128 bytes.

The response of a somewhat small status page is just under 5000 bytes, [^wrong-assumptions] so—assuming a bunch of small writes to the buffer—it will have to be expanded seven times. Since we know the response is going to be at least a few kilobytes (the template with no content is 1kB), setting the initial size to 4kB avoids having to do 6 reallocations.

[^wrong-assumptions]: I actually assumed it was under 4000 bytes without checking, and edited based on that. I should've just checked right away.

In the end this is a non-issue, because the code is so low-traffic and already very performant. As [I've written before][limited-languages] I don't like the somewhat superstitious approach of limiting language features because someone might mis-use them. Slow code can come from anywhere, and you have to actually look for it. You can see the changes I actually made to the status page library [in this commit](https://codeberg.org/willhbr/status_page/commit/d312441c2ae93d270fd6fd615db5828273a4145b).

[limited-languages]: /2023/07/09/limited-languages-foster-obtuse-apis/

On the other hand, there is an opportunity for languages to enable library authors to guide their API use. Most languages have (either builtin or through a linter) a way of annotating that the return value from a function shouldn't be ignored. In Rust this is the `#[must_use]` tag.

What could be neat is a system for attaching metadata to objects at compile time that could be read later in the compile step. So the `HTML.escape` method could attach a bit of information that says the string it returns could be directly written to an `IO`. Then if that object is passed to `IO#<<` (or `IO#write` or whatever) it could check that attribute and provide a warning.

This would fit in with Crystal's existing macro system, but I'm sure it would explode the complexity of the compiler and make compilation much slower.
