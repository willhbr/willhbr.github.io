---
title: "Why Crystal is the Best Language Ever"
tags: opinion crystal languages
---

[Crystal][crystal] is a statically typed language with the syntax of a dynamically typed one. I first used Crystal in 2016—about version `0.20.0` or so. The type of projects I usually work on in my spare time are things like [`pod`][pod], or my [server that posts photos][pixelfed-piper] to my [photos website]({{ site.urls.photos }}).

[pixelfed-piper]: /2023/05/22/complicated-solutions-to-photo-publishing/
[pod]: https://github.com/willhbr/pod
[crystal]: https://crystal-lang.org

# Type System

This is the main selling point of Crystal, you can write code that looks dynamically typed but it'll actually get fully type checked. The reality of this is that if I know the type and the method is part of a public interface (for me that's usually just a method that I'm going to be calling from another file), I'll put a type annotation there. That way I usually only have to chase down type errors in single files. If I'm extracting out a helper method, I won't bother with types. You can see this in [the code that I write][code-link]:

[code-link]: https://github.com/willhbr/pod/blob/baeff9f871eaff05c962178be3c80e53ff46a689/src/pod/updater.cr#L64

```crystal
private def calculate_update(config, container, remote) : ContainerUpdate
  ...
```

The three argument types are fairly obvious to anyone reading the code, and since the method is private the types are already constrained by the public method that uses this helper. If I wrote this in Java it would look something like:

```java
private ContainerUpdate calculateUpdate(
  Config config, Container container, Optional<String> remote) {
  ...
```

There's a spectrum between language type flexibility and language type safety. Dynamic languages are incredibly flexible, you can pass an object that just behaves like a different object and everything will _probably_ work. The language gets out of your way—you don't have to spend any time doing work explain to the compiler how things fit together—it'll just run until something doesn't work and then fail. Languages that boast incredible type safety (like Rust) require you to do a bunch of busywork so that they know the exact structure and capabilities of every piece of data before they'll do anything with it. Crystal tries to bend this spectrum into a horseshoe and basically ends up with "static duck typing"—if it's duck shaped at compile time, it will probably be able to quack at runtime.

It definitely takes some getting used to. The flow that I have settled on is writing code with the types that I know, and then seeing if the compiler can work everything out from there. Usually I'll have made a few boring mistakes (something can be `nil` where I didn't expect, for example), and I'll either be able to work out where the source of the confusing type is, or I can just add some annotations through the call stack. Doing this puts a line in the sand of where the types can vary, making it easy to see where the type mismatch is introduced.

The Crystal compiler error trace can be really daunting, since it spits out a huge trace of the entire call stack of where the argument is first passed to a function all the way to where it is used in a way it shouldn't be. However once you learn to scroll a bit, it's not any harder than debugging a `NoMethodError` in Ruby. At the top of the stack you've got the method call that doesn't work, each layer of the stack is somewhere that the type is being inferred at.

This can get confusing as you get more layers of indirection—like the result of a method call from an argument being the wrong type to pass into a later function—but I don't think this is any more confusing than the wrong-type failures that you can get in dynamic languages. Plus it's happening before you even have to run the code.

A downside of Crystal's type system is that the type inference is somewhat load-bearing. You can't express the restrictions that the type system will make from omitting type annotations, the generics are not expressive enough. So very occasionally the answer to fixing a type error is to remove a type annotation and have the compiler work it out.

# Standard Library

This is probably the thing that keeps me locked in to using Crystal. Since I'm reasonably familiar with the Ruby standard library, I was right at home using the Crystal standard library from day one. As well as being familiar, it's also just really _good_.

Rust—by design I'm pretty sure—has a very limited standard library, so a lot of the common things that I'd want to do (HTTP client and server, data serialisation, for example) require third-party libraries. Since Crystal has a more "batteries included" standard library, it's easier for my small projects to get off the ground without me having to find the right combinations of libraries to do everything I want.

API design is hard, and designing a language's standard library is especially difficult, since you want to leave room for other applications or libraries to extend the existing functionality, or for the standard library types to work as an intermediary between multiple libraries that don't have to be specifically integrated together. This is where I really appreciate the HTTP server and I/O APIs. The HTTP server in the standard library is really robust, but the `HTTP::Handler` abstraction means that you can fairly easily replace the server with another implementation, or libraries can provide their own handlers that plug into the existing `HTTP::Server` class.

The IO API is especially refreshing given [how hard it is to read a file in Swift][swift-file]. It's a great example of making the easy thing easy, but then making the more correct thing both not wildly different, or much harder.

[swift-file]: https://forums.swift.org/t/read-text-file-line-by-line/28852/7?page=3

```crystal
# Reading a file as a String is so easy:
contents = File.read(path)
# do something with contents
# And doing the more correct thing is just one change away:
File.open(path) do |file|
  # stream the file in and do something with it
end
```

And then since all input and output use the same `IO` interface, it's just as easy to read from a `File` as it is to read from a `TCPSocket`.

There is definitely a broader theme here; Crystal is designed with the understanding that getting developers to write 100% perfect code 100% of the time is not a good goal. You're going to want to prototype and you're going to want to hack, and if you're forced to make your prototype fully production-ready from the get-go, you'll just end up wasting time fighting with your tools.

# Scaling

I [wrote back in 2017](/2017/11/21/scrutinising-a-scalable-programming-language/)[^crystal-new] thinking about how well different languages scaled from being used for a small script to being used for a large application. At this point I was still hoping that Swift would become the perfect language that I hoped it could be, but over five years later that hasn't quite happened.

[^crystal-new]: I'd only dabbled in Crystal for less than a year at this point, and was yet to realise that it was the best language ever.

The design of Crystal sadly almost guarantees that it cannot succeed in being used by large teams on a huge codebase. Monkey-patching, macros, a lack of isolated modules, and compile times make it a poor choice for more than a small team.

Although I remain hopeful that in 10 years developers will have realised that repeatedly writing out type annotations is a waste of time, and perhaps we'll have some kind of hybrid approach. What about only type annotations for public methods—private methods are free game? Or enforce that with a pre-merge check, so that developers are free to hack around in the code as they're making a feature, and then baton down their types when the code is production ready.

# Flexibility

I'm of the opinion that no piece of syntax should be tied in to a specific type in the language. In Java, the only things that can be subscripted are arrays—despite everyone learning at university that you should always use `List` instead. This limits how much a new type can integrate into the language—everything in Java basically just ends up being a method call, even if an existing piece of syntax (like subscript, property access, operator, etc) would be neater.

Pretty much everything in Crystal is implemented as a special method:

```crystal
struct MyType
  def [](key)
    ...
  end

  def property=(value)
    ...
  end
end
```

There's no special types that have access to dedicated syntax (except maybe `nil` but that _is_ somewhat special), so you can write a replacement for `Array` and have it look just like the builtin class. Being able to override operators and add methods to existing classes allows things like `4.hours + 5.minutes` which will give you a `Time::Span` of 4:05. If you did this in Java[^java-time] you'd have something like this, which absolutely does not spark joy:

```java
Duration.ofHours(4).plus(Duration.ofMinutes(5))
```

[^java-time]: After researching for hours which library was the correct one to use.

# Safety

While Crystal's type system is game-changing, it doesn't break the status quo in other ways. It has no (im)mutability guarantees, and has no data ownership semantics. I think this is down the design goal of "Ruby, but fast and type checked". Ruby has neither of those features, and so nor does Crystal.

An interesting thought is what would a future language look like if it tried to do what Crystal has done to type checking to data ownership. The state of the art in this area seems to be [Rust](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html) and [Pony](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html#the-list-of-reference-capabilities), although it seems like these are not easy to use or understand (based on how many people ask about why the borrow checker is complaining on Stackoverflow). A hypothetical new language could have reference capabilities like Pony does, but have them be inferred from how the data is used.

# Macros

[Every language needs macros](/2017/07/04/metaprogramming-and-macros-for-server-side-swift/). Even Swift (on a rampage to add every language feature under the sun) [is adding them][swift-macros]. Being able to generate boring boilerplate means developers can spend less time writing boring boilerplate, and reduces the chance that a developer makes a mistake writing boring boilerplate because they were bored. If my compiled language can't auto-implement serialisation in different formats (JSON, YAML, MessagePack) then what's even the point of having a compiler?

[swift-macros]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/

It's a shame that Crystal's macros are a bit... _weird_. The macro language is not quite the full Crystal language, and you're basically just generating text that is fed back into the compiler (rather than generating a syntax tree). Crystal macros are absolutely weak-sauce compared to macros in Lisp or Elixir—but those languages have the advantage of a more limited syntax (especially in the case of Lisp) which does make their job easier.

Crystal macros require a fairly good understanding of how to hack the type system to get what you want. I have often found that the naive approach to a macro would be completely impossible—or at least impractical—but if you flipped the approach (usually by leveraging [macro hooks](https://crystal-lang.org/reference/1.8/syntax_and_semantics/macros/hooks.html)) you can leverage the flexible type system to produce working code.

The current macros are good enough to fit the use cases that I usually have, and further improvements would definitely be in the realm of "quality of life" or "academically interesting". You _can_ always just fall back to running an external program in your macro, which gives you the freedom to do whatever you want.

# The Bottom Line

Back in my uni days there would be a new language each week that I was _convinced_ was the future—notable entries include Clojure, Elixir, Haskell, Kotlin, and Go. There are aspects to all these languages that I still like, but each of them have some fairly significant drawback that keeps me from using them[^language-downsides]. At the end of the day, when I create a new project it's always in Crystal.

[^language-downsides]: Really slow edit/build/run cycle, process-oriented model gets in the way for simple projects, I just don't think I'm a monad type of guy, experience developing outside of an IDE is bad, lacking basic language features.

Other languages are interesting, but I'm yet to see something that will improve my experience working on my own small projects. Writing out interface definitions to appease a compiler sounds just as unappealing as having my program crash at runtime due to a simple mistake.
