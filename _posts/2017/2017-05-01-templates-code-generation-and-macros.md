---
title: Templates, Code Generation, and Macros
---

Macros are a really cool feature that is includes in a few cool languages (Clojure/ Common Lisp/ other Lisps, Elixir, Rust, and Crystal) that allow you to reduce boilerplate code, extend the capabilities of the language, and process data at compile time. There is no shortage of tutorials on macros, but I am going to approach them from a direction that may be more familiar to some people.

It doesn't take long while programming to come across some kind of template. Whether it's `str.format()` in Python, or the moustache-templated bindings in `$JS_FRAMEWORK` you'll end up writing something that will be used to generate something else. We can use these to separate the content from how it will be displayed.

This snippet is some Embedded Ruby, the `<%` and `%>` denote a start and end of Ruby code. Outside the Ruby is just HTML.

```erb
<ul>
  <% for item in items %>
    <li><%= item %></li>
  <% end %>
</ul>
```

Here we have `items` which is a list of strings, and we iterate over it creating an `<li>` with the content of each `item`. The server will run this code and generate some HTML, which is then sent to the browser. The browser doesn't know that the HTML was part of a template, it looks exactly the same as hand-written HTML. What we're doing is using Ruby to generate more code that could have been written by hand. Doing this for a formatting language makes sense - there is no way for HTML to show dynamic content. However because we're just dealing with text, we can use a template to generate any type of file - even code.

```javascript
function <%= func_name %>() {
  return "This is <%= func_name %>";
}
```

This is a silly example, but we're using a template to create a Javascript function. All it does is returns "This is " followed my the function name, but if we were making a library that interacted with a database, and we wanted to have an API that was something like `<table_name>.get_by_<column_name>()` without having to do metaprogramming (for example if the language doesn't support metaprogramming, or you don't want the runtime cost of doing reflection).

A common example of something that uses a "template" to generate code is a parser generator (like Cup, Yacc). These read a file that is in their own syntax for defining a grammar and how to store the AST, and produce a file of code in the target language that will parse something according to the specification.

[Casey Liss recently wrote about](https://www.caseyliss.com/2017/3/31/the-magic-of-sourcery) [Sourcery](https://github.com/krzysztofzablocki/Sourcery), a library for automaticaly generating boilerplate Swift code - it can do things like make a type `Equatable` by generating an `==` method that compares every property of the type. This is possible by generating a `.swift` file with the code needed to define this method.

Sourcery is quite cool - but it means that you have to have a special Sourcery file that defines what it should do, and remember to run the Sourcery script to generate the new files. Ideally you would put the definition for what boilerplate to generate inside the Swift file with all the rest of the code, and the Swift compiler would generate it automatically before running the program.

This is essentially what macros are. They are pieces of code that make more code, and are run when the program is compiled. For example if Swift supported this, it might look something like:

{% raw %}
```swift
func ==(other: this.class.name) {
  for attr in this.storedVariables {
    quote {
      guard self.{{ attr }} == other.{{ attr }} else { return false }
    }
  }
  quote {
    return true
  }
}
```
{% endraw %}

I'm imagining that `quote` will turn whatever is inside it into code that will be generated (like other languages), and the double curly braces escape a variable - {% raw %}`{{ attr }}`{% endraw %} would be expanded to the name of the attribute.

For macros to be super effective, the language should be represented in its own data structures (languages that are like this are called _homoiconic_). Clojure is one of these, and provides syntax for denoting which code is to be evaluated, and which code is to be used to generate more code. `` ` `` or `'` start a "this is for code generation block" - everything _after_ the that is like all the HTML _outside_ the `<% %>` tags in Ruby. Code after `~` is equivalent to code inside the `<% %>` tags.

So we could make a macro that prints the code it will evaluate before it runs (like the `-x` option in Bash):

```clojure
(defmacro debug [code]
  `(do
    (println '~code)
    ~code))
```

This can then be used just like a normal function call, but instead of calling the function at runtime, it gets replaced when the code is compiled.

```clojure
(debug (println (+ 8 6 (* 5 7))))
; Will be replaced with
(do
  (println '(println (+ 8 6 (* 5 7))))
  (+ 8 6 (* 5 7)))
```

The new code will first print `"(+ 8 6 (* 5 7))"` then run the maths.

That's a silly example, but a far more practical example is the Ecto library for Elixir. It is a DSL for running SQL queries, by using a macro it basically adds an SQL-like language right into Elixir, which can be checked for validity at compile time, rather than putting SQL in string literals where errors are only known when the code is run.

Running code at compile time also lets you do some cool tricks that don't involve creating "new" syntax. For example, resource files can be loaded right into the program, so nothing has to be read from disk when the application is running. Phoenix (an Elixir web framework) loads all the views when the code compiles and turns it into a function that concatenates strings - so no parsing has to be done at runtime.

Of course, many smart compilers let you use lambdas and stuff to create "new syntax" that gets expanded at compile time, but macros allow the developer to have more control over what happens when code is compiled and truly add new contructs to the language.
