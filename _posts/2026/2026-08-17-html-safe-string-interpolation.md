---
title: "HTML-Safe String Interpolation"
tags: crystal
---

Last year I made a version of ECR (the Crystal templating language) that [allows for automatic escaping of values injected into an HTML template](/2025/11/13/html-safe-ecr-templates/). This avoids having to litter your code with `HTML.escape` around everything that you put into the template.

A little while after writing that post, I realised that it was a whole lot simpler if instead of using `to_s` to build my template, I created a new method, `to_html`. This got rid of the `Builder` and the `unsafe_write` and all that nonsense. Instead, a class can override `to_html(io : IO)` and write HTML content into the `IO`. If it don't implement it, the default implementation will proxy `to_s` through an `HTMLEscapingIO` that calls `HTML.escape` on any data as it's written.

This made it easier to implement "partials" that can be placed into a larger template, just by creating objects that override `to_html`. You can see the new code [on Codeberg](https://codeberg.org/willhbr/geode/src/branch/main/src/geode/html_safe_ecr.cr).

HTML-safe ECR is cool, but sometimes you just want to build a quick and dirty string, without making a separate file. Something like this:

```crystal
def homepage_link
  "<a href=\"/home\">#{HTML.escape @title}</a>"
end
```

Now we're back to wrapping everything in `HTML.escape`, and we're [allocating an intermediate `String` unnecessarily](/2025/11/07/tracking-down-progressively-enhanceable-apis/). To avoid that allocation, we could use `String.build`:

```crystal
def homepage_link
  String.build do |io|
    io << "<a href=\"/home\">"
    HTML.escape @title, io
    io << "</a>"
  end
end
```

We've made it more efficient, but we've also made it verbose and terrible.

You know the drill. We can solve this with macros.

In the syntax tree, a string interpolation is distinct from a regular string as it actually has to be built at run time. I assume this is basically just doing `String.build`, but I haven't checked.

We can make a macro that takes a [`StringInterpolation` node](https://crystal-lang.org/api/1.21.0/Crystal/Macros/StringInterpolation.html) as an argument, and iterate through each of its `expressions`:

{% raw %}
```crystal
macro interpolate(literal)
  {% for expr in literal.expressions %}
    {% p expr %}
  {% end %}
end

interpolate "<h1>#{title}</h1>"
```
{% endraw %}

At compile time, that'll print out the components of our string:

```shell
$ crystal build example.cr
"<h1>"
title
"</h1>"
```

Now we just need to use those to build a string:

{% raw %}
```crystal
macro interpolate(literal)
  String.build do |%io|
    {% for expr in literal.expressions %}
      {% if expr.is_a? StringLiteral %}
        %io << {{ expr }}
      {% else %}
        ({{ expr }}).to_html(%io)
      {% end %}
    {% end %}
  end
end
```
{% endraw %}

That will produce code that looks like this:

```crystal
String.build do |__temp_94|
  __temp_94 << "<h1>"
  (title).to_html __temp_94
  __temp_94 << "</h1>"
end
```

This does the same thing that the ECR templating does: instead of calling `to_s` on the values to be interpolated, it calls `to_html`. If a class doesn't override `to_html`, they get the default implementation that does the escaping automatically:

```crystal
class Object
  def to_html(io : IO)
    self.to_s Geode::HTMLSafeECR::HTMLEscapingIO.new(io)
  end
end
```

There's only one last trick: we need to mark the resulting `String` as safe to use in an HTML template. Otherwise, if someone calls `to_html` on it, it'll automatically get proxied through the `HTMLEscapingIO` and all our HTML-building will be lost in a sea of `&gt;` and `&lt;`.

I already have a `.html_safe` extension method on `String` that returns a `SafeString`, which forgoes further escaping. That leaves us with a final macro:

{% raw %}
```crystal
macro interpolate(literal)
  {% if literal.is_a? StringLiteral %}
    ({{ literal }}).html_safe
  {% elsif literal.is_a? StringInterpolation %}
    (String.build do |%io|
      {% for expr in literal.expressions %}
        {% if expr.is_a? StringLiteral %}
          %io << {{ expr }}
        {% else %}
          ({{ expr }}).to_html(%io)
        {% end %}
      {% end %}
    end).html_safe
  {% else %}
    {% raise "argument to interpolate must be string, not '#{literal}'" %}
  {% end %}
end
```
{% endraw %}

You don't have to do anything special to support multiline strings, or strings with other delimiters. You could even build a whole HTML file this way:

```crystal
interpolate %(
  <!doctype html>
  <html>
    <head>
      <title>#{title}</title>
    </head>
    <body>
      #{content}
    </body>
  </html>
)
```

I did think about hacking in some live-reloading (like [I did with ECR](/2025/11/17/hot-ecr-reloading-in-your-area/)) but you'd have to re-parse the whole Crystal source file and try to find the right `interpolate` call, which would be difficult. You could get away with using `#line_number` and `#column_number` on the `StringInterpolation` node, but that would fall down if there were two `interpolate` calls in the same file.
