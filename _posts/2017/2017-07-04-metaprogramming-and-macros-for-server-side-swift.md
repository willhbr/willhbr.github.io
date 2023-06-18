---
title: Metaprogramming and Macros for Server-Side Swift
---

I have been a fan of the Swift programming language since it was first announced, and [especially after](/2015/12/04/welcome-to-swift-org/) it was open sourced. The place that I thought Swift could be the most interesting for me was for server applications - I'm not much of an iOS/ macOS developer. The progress of Swift-on-Linux is slow for someone that doesn't like digging around Makefiles and linking to C libraries.

However, there are some things about web applications that aren't currently served by the design of Swift. This can basically be boiled down to one thing - [compile-time macros](/2017/03/27/templates-code-generation-and-macros/). Having a macro system allows for a lot of really cool syntactic sugar, as well as removing work that would otherwise need to be done on the first request, or at startup. Many of these are taken from my brief time learning [Phoenix](https://phoenixframework.org), a web framework written in [Elixir](https://elixir-lang.org) - if I've misinterpreted something or ruled out some approach that is actually possible, [let me know](https://twitter.com/willhbr).

The main use of macros in your typical web framework is the routing configuration. Phoenix and Rails both support a DSL (implemented using the syntax of the language, Elixir or Ruby). Both of these look quite similar, basically allowing you to do this:

```ruby
# In Phoenix
get "/", MyController, :index
# In Rails
get "/", to: 'my_controller#index'
```

The DSL gets more complicated when you include [resourceful routes](https://guides.rubyonrails.org/routing.html#resource-routing-the-rails-default) and other goodies. But at its core the purpose of the DSL is to allow the developer to use the same tools (i.e: the same editor and highlighting) to define their routes in a succinct manner. Phoenix can go one step further, because Elixir supports macros. The routes are checked when the project is compiled, and can be turned into arbitrary code that responds to web requests following the rules defined.

For example, the `get` macro can check that the path is valid, that it doesn't clash with any other routes, and make helper functions for linking to that page (e.g. a `my_controller_index_path()` function). This is done at compile time, so when the code is run it is no different to running the "hand written" equivalent.

> This is not the case in Ruby - because it is a dynamic language these methods can be created at runtime. There is basically no loss in performance because to support this level of metaprogramming (and because it is interpreted) Ruby is super slow compared to compiled languages.  

When it comes to compiled languages without macros (like Swift, Go, Java, etc) you can't pre-calculate information while the code is being compiled. [Go](https://golang.org) lacks the features [^go-features] to implement any kind of usable DSL. [Revel](https://revel.github.io) (the #1 result when googling for "golang web framework") has a separate routes file - written in a Revel-specific syntax that is parsed at runtime. This creates complexity in the packaging and distribution of the application - it no longer can be built as a single binary as it relies on this config file.

[^go-features]: lol no generics.

Swift does allow for creating concise DSLs. [Vapor](https://vapor.codes) and [Perfect](https://www.perfect.org) are Swift web frameworks. Both of them offer routing DSLs that look something like:

```swift
app.get("/:page_id") { request ->
	return Response(.text, request.params["page_id"])
}
```

But this is processed at runtime, and doesn't allow for creating helper methods for creating URLs, or grouping methods together into a class-based controller like Rails does. The latter could just be a necessary limitation of Swift, instead of making classes you could create a "controller factory" DSL, which you might use like:

```swift
controller("MyController") { app ->
	app.get("/stuff") { request ->
    // do something with stuff
  }
  // etc
}
```

Although this doesn't get around the fact that much of your logic is defined in string literals that don't get looked at until the application is running, or the fact that the routes must be generated when the application starts - if you wanted to make a super-efficient [trie](https://en.m.wikipedia.org/wiki/Trie) or other data structure for better processing requests, you sacrifice startup time in both development and production, even if the structure never changes until a new version is deployed.

Moving code-level information out of strings allows for static analysis to perform more useful checks when validating code. For example, regular expressions are often written as string literals (e.g: in Java) and so don't get checked for validity until the program reaches them. Other languages have builtin regex literals (JavaScript, Ruby) to fix this problem. Elixir goes one step further thanks to (you guessed it) macros, specifically "sigils". [These are macros that wrap around a special "literal creation" syntax](https://stackoverflow.com/documentation/elixir/2204/sigils#t=201707040415344579701). This is used not only for regexes (written like `~r/abc\w{5}/`) but for common "make a list of strings" helpers commonly found in other languages: `~w(foo bar)` is equivalent to `["foo", "bar"]`. So if you made a cool new type of regex that adds some awesome new feature, you can implement a macro that lets you write it easily and have all the same advantages as the builtin version.

> View templates (think ERB, Liquid, Handlebars, etc) can also be parsed and optimised at compile time using macros - Phoenix does this so that when running the application all that needs to be done is string concatenation, no parsing needed.  

So where does that leave us with Swift-based web development? It doesn't seem any worse off than Go in terms of ability to dynamically create methods, etc - and Go appears to be used for web development a wee bit. The other option is code generation - but that's always going to be a second-class way of doing this, as it relies on other tools and requires the other tool to parse the rest of the codebase to get the advantages you would from a macro system.

There might of course be a time when Swift gets a macro system, which will create a huge opportunity for new syntax and more concise, expressive code. However given the complexity of Swift and decisions so far, I would not hold my breath.
