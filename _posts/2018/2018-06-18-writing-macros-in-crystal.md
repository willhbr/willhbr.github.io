---
title: "Writing Macros in Crystal"
date: 2018-06-18
layout: post
---

The [existing documentation](https://crystal-lang.org/docs/syntax_and_semantics/macros.html) for macros in [Crystal](https://crystal-lang.org) leaves a wee bit to be desired, especially if you want to do anything that's a bit off-the-rails. So here we go, some top tips for macros in Crystal.

There are two different types of interpolation - `{% raw %}{{ foo }}{% endraw %}` will put the result of `foo` into the code, whereas `{% raw %}{% foo %}{% endraw %}` will evaluate it and ignore the result. Much like `<%= foo %>` and `<% foo %>` in embedded Ruby. So if you want to print something to debug the macro, then use `{% raw %}{%{% endraw %}`. This is obvious if you notice that conditionals and loops in macros always use `{% raw %}{%{% endraw %}` because they shouldn't actually output anything themselves.

Something that I didn't realise initially was that you can assign variables in non-expanding interpolation (the `{% raw %}{%{% endraw %}` kind). This makes your code a lot tidier.

When writing a macro it is super useful to be able to see the generated code - to do this you can use `{% raw %}{% debug %}{% endraw %}`! It will output the current "buffer" for the macro, so you can just put it at the bottom of your macro definition to see what is being generated when your code compiles.

`@type` is definitely not given the attention it needs. It is essential for writing macros that change aspects of the current class or struct. For example:

```ruby
macro auto_to_string
  def to_s(io)
    io << {% raw %}{{ @type.stringify }}{% endraw %}
  end
end
```

> `.stringify` basically returns the syntax tree wrapped in quotes, so `44.stringify` gives `"44"` at compile time.

When we call this method in some class, a new method will be generated:

```ruby
class SomeNeatClass
  auto_to_string # Calling the macro will expand the code here

  # This is what will be generated:
  def to_s(io)
    io << "SomeNeatClass"
  end
end
```

The class name is turned into a string at compile time. `@type` will be some kind of `TypeNode` - checking what kind it is using `.is_a?` and the methods in the imaginary [macros module](http://crystal-lang.org/api/Crystal/Macros.html) lets you do different things based on what it is - like if it has generic types, what its superclasses are, etc. Although do remember that this information is limited to what is known by the compiler when the macro is invoked - so if you use `@type.methods` in a macro that is expanded before any methods are defined, there won't be any there:

```ruby
macro print_instance_methods
  {% raw %}{% puts @type.methods.map &.name %}{% endraw %}
end

class Foo
  print_instance_methods

  def generate_random_number
    4
  end

  print_instance_methods
end
# This will print:
# []
# [print_instance_methods]
```

Depending on what you want to do, you could either move the code into a macro method - they get resolved when the first bit of code that uses them is compiled - or use [the `method_added` and `finished` macro hooks](https://crystal-lang.org/docs/syntax_and_semantics/macros/hooks.html).

The difficult thing about writing macros (especially if someone else has to use them) is doing unexpected things when you don't get quite the input you expect. The error messages are often incomprehensible - just as you'd expect from an interpreted templating language that is used to generate code for another language, on top of which it is based.

Pretty much everything you run into in macros is some kind of `*Literal` class. Arrays are `ArrayLiteral`, booleans are `BoolLiteral`, `nil` is `NilLiteral`, etc.
