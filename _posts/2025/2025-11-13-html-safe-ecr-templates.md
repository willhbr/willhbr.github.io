---
title: "HTML-Safe ECR Templates"
tags: crystal
---

After writing [my last post][enhance-apis] I wondered if I could improve `ECR` to avoid the need to call `HTML.escape` explicitly when adding values to the template. This turned out to be much easier than I expected.

[enhance-apis]: /2025/11/07/tracking-down-progressively-enhanceable-apis/

ECR (Embedded Crystal) is the compile-time templating system [included in the Crystal standard library][ecr-crystal]. The syntax is based on ERB (Embedded Ruby), but the template is processed at compile time in a macro, instead of at runtime. The end result is that using an ECR template is just the same performance-wise (good) as writing your output using `IO#<<` and `Object#to_s(IO)`. If we take this simple example:

[ecr-crystal]: https://crystal-lang.org/api/1.18.2/ECR.html

```crystal
<section>
  <h1><%= title %></h1>
  <p><%= content %></p>
</section>
```

It will get turned into roughly this code:

```crystal
io << "<section>\n  <h1>"
title.to_s io
io << "</h1>\n  <p>"
content.to_s io
io << "</p>\n</section>"
```

The problem is that `title` or `content` could contain HTML, like a naughty `<script>` tag, which would get dumped directly into our HTML document. The obvious thing to do is wrap every variable in `HTML.escape`:

```crystal
<section>
  <h1><%= HTML.escape title %></h1>
  <p><%= HTML.escape content %></p>
</section>
```

Although as [we learnt before][enhance-apis] that will allocate a temporary string, just for the string to be written to the `IO` buffer and discarded—which is a waste—and more importantly the code is now ugly.

One option would be to make a custom `IO` subclass that processes every `IO#write` call through `HTML.escape`, ensuring that nothing is ever written with dangerous angle brackets. But that would mean that no HTML could be written, not even the HTML in our template file! Turning our `<section>` into a `&lt;section&gt;` is not very useful. We want string literals from the template to be left as-is, but everything else to be escaped.

You might look at the generated code and notice that values from the template are always passed to `IO#<<`, whereas variables are stringified using `to_s`, so maybe we could just override `<<` in our custom `IO`? That works right up until the point where a `to_s` call uses the `<<` method.

The remaining option is to see if I can hack with ECR itself.

Thankfully the ECR code is really modular, there are some macros in [`macros.cr`][macros-cr] that call `run` on [`ecr/process`][ecr-process] which is just a wrapper around [`ECR.process_string`][process-string], which just uses the [`ECR::Lexer`][lexer] class to handle each token and build a string with the code.

[lexer]: https://github.com/crystal-lang/crystal/blob/1c72aa8f20d40bfdfed1324df35bb33419b774e1/src/ecr/lexer.cr
[process-string]: https://github.com/crystal-lang/crystal/blob/1c72aa8f20d40bfdfed1324df35bb33419b774e1/src/ecr/processor.cr
[ecr-process]: https://github.com/crystal-lang/crystal/blob/1c72aa8f20d40bfdfed1324df35bb33419b774e1/src/ecr/process.cr
[macros-cr]: https://github.com/crystal-lang/crystal/blob/1c72aa8f20d40bfdfed1324df35bb33419b774e1/src/ecr/macros.cr

I can just write my own macros to call my own processor (which can by 99% copied from the standard library) that uses the same `ECR::Lexer`. The difference is minimal: instead of calling `IO#<<`, I'll call `unsafe_write`. This is a new method that I'll add to a new `Builder` class that will handle the escaping. `Builder` will wrap an existing `IO` and any normal writes—that haven't come from a template literal—will be fed through `HTML.escape`.

It's actually really simple when you see it written down:

```crystal
class Builder < IO
  def initialize(@io : IO)
  end

  def write(slice : Bytes) : Nil
    HTML.escape(slice, @io)
  end

  def unsafe_write(slice : Bytes)
    @io.write(slice)
  end
end
```

The generated code will only look slightly different:

```crystal
io.unsafe_write "<section>\n  <h1>"
title.to_s io
io.unsafe_write "</h1>\n  <p>"
content.to_s io
io.unsafe_write "</section>"
```

Now no matter what `title` and `content` are, they're guaranteed to be passed through `HTML.escape` before being written to the wrapped `IO`.[^more-benefits]

[^more-benefits]: Splitting the literals from variables does open the possibility of counting the size of each string literal that is to be written to the `IO` and preemptively increasing the buffer size to fit them all. This would obviously get complicated with loops and conditionals, and Crystal's macros aren't too capable of extensive syntax-tree analysis, but it's a possibility.

However, what if we want to include a string as a piece of HTML? That's also easy to do, I made a struct that wraps a `String` and checks the type of `IO` it's writing to, changing the behaviour for the `Builder`:

```crystal
record SafeString, string : String do
  def to_s(io : IO)
    case io
    when Builder
      io.unsafe_write(self.string.to_slice)
    else
      self.string.to_s(io)
    end
  end
end
```

This is where Crystal's type system lets me down a little. I'd like to either make this `HTMLSafe(T)` and wrap any type, or erase the type and use `Object` instead of `String`, but that's not yet supported in Crystal.[^object-var] Realistically this approach will work for the majority of cases, so it's fine for now.

[^object-var]: "can't use Object as the type of an instance variable yet, use a more specific type"

The next thing I would like to solve is a nice API for ECR layouts that have a gap for the main content. What I've done previously is render the main content into one buffer, turn that into a string, then render the layout and have the layout pull in the content string in the middle. The ideal would be system that's as flexible as [`content_for` in Rails][content-for-rails] but rendering the whole page top-to-bottom with no intermediate buffers.

[content-for-rails]: https://guides.rubyonrails.org/layouts_and_rendering.html

In the meantime I've added my HTML-escaping `ECR` to [Geode](https://codeberg.org/willhbr/geode), my little library of Crystal junk.
