---
title: "When Does an API Become a DSL?"
tags: languages
---

In response to my [previous post][mockito-post] I got asked when something is a DSL versus just being an API. Of course if you've defined a separate grammar and written a parser for that grammar and use that to solve a problem in your specific domain, then you've got a DSL. But a lot of the time, a DSL is directly embedded in another language—like how Mockito is just Java—and so the distinction between when you're just using the API of a library and when that library becomes a DSL is a little blurry.

[mockito-post]: /2024/09/27/mockito-type-checking-and-the-perils-of-dsl-design/

My immediate response was along the lines of when the API defines its own set of rules and semantics, then you've got a DSL. This doesn't really hold up as plenty of APIs have rules about what you can do when, [as I've discussed before][lifetimes]. It really boils down to ["I know it when I see it"](https://en.wikipedia.org/wiki/I_know_it_when_I_see_it), which isn't a satisfying answer. Obviously if you're defining your own grammar, you've got a DSL, but when does your API in an existing language become a DSL?

[lifetimes]: /2024/09/05/implicit-lifetimes-and-undroppable-types/

If we take Mockito as an example to start with, the API is clearly designed to emulate how you would write out the behaviour in English:

```java
when(thingSizer.getSize()).thenReturn(ThingSize.LARGE)
```

You would explain this to someone as "when I call `thingSizer.getSize()` then it should return `LARGE`". What makes me think of this as a DSL is the fact that it's adding a "feature" that Java doesn't have—the ability to pass a method call as an argument to a function. Of course as [I previously mentioned][mockito-post] this isn't actually possible, so it's doing some behind-the-scenes magic to make it _appear_ that the argument to `when()` is the actual invocation on the `thingSizer` mock, not the result of that method call.

You can imagine writing a code linter that ensured that the argument passed to `when()` is always an invocation on a mock, and not some other value. To me this is what makes it a DSL: it's got its own semantics that are separate from the typical semantics of Java code, in order to provide a particular way of writing code.

Staying within the JVM, Kotlin has some features that make writing DSLs much easier. [Receiver blocks][kt-receiver-blocks] allow for altering the typical scoping rules that determine how method and property names are resolved. The documentation uses an HTML-generator DSL as an example, which is something that [I've also built in Crystal][status-page-builder].

[kt-receiver-blocks]: https://kotlinlang.org/docs/type-safe-builders.html
[status-page-builder]: https://codeberg.org/willhbr/status_page/src/branch/main/src/status_page/html_builder.cr

You can see how the change in scoping rules breaks how you might refactor the code, for example if we want to avoid repeating the definition of the button:

```kotlin
html {
  body {
    p {
      +"This is one paragraph"
      button { +"Copy" }
    }
    p {
      +"This is another paragraph"
      button { +"Copy" }
    }
  }
}
```

One might assume that you could extract the `button { ... }` block into a variable to avoid re-defining it:

```kotlin
val copyButton = button { +"Copy" }
html {
  body {
    p {
      +"This is one paragraph"
      copyButton
    }
    p {
      +"This is another paragraph"
      copyButton
    }
  }
}
```

But of course if you're familiar with Kotlin's receiver blocks you know that the `button` method is actually probably defined on the receiver type for the `body` method, so we can't call it from outside the block passed to `body`. Of course if you know the rules, you can refactor your code:

```kotlin
val addCopyBody = { body ->
  body.button { +"Copy" }
}

html {
  body {
    p {
      +"This is one paragraph"
      addCopyButton(this)
    }
    p {
      +"This is another paragraph"
      addCopyButton(this)
    }
  }
}
```

Or if you're really clever, you know that you can define an extension function on the `body` type that defines the copy button.

Contrast this with a more traditional API for building HTML using type-safe objects:

```java
HTMLBuilder html = new HTMLBuilder();

html.body().add(new Paragraph("This is one paragraph", new Button("Copy")));
html.body().add(new Paragraph("This is another paragraph", new Button("Copy")));

// Or just:
Button copyButton = new Button("Copy");
html.body().add(new Paragraph("This is one paragraph", copyButton));
html.body().add(new Paragraph("This is another paragraph", copyButton));
```

Of course you could extract that `new Button("Copy")` call into a common variable to avoid defining it twice.[^object-references]

[^object-references]: In all these examples I'm assuming that the `Button` objects are interchangeable, and the only state that one button holds is its label, so passing the same instance to two paragraphs is not a problem.

Another good example is HTTP routing APIs, where some router object has methods for "get", "post", etc that accept a callback for when a certain HTTP request with a matching path is called. Taking the API for [this library](https://github.com/julienschmidt/httprouter) simply as an example:

```go
router := httprouter.New()
router.GET("/", func(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
  fmt.Fprint(w, "Welcome!\n")
})
```

What happens if you break out of the little API and do something that's not really intended?

```go
router.GET("/", func(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
  router.GET(
    r.Params["new_method"],
    func(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
      fmt.Fprint(w, "Welcome!\n")
    })
})
```

I don't know whether this would work (i.e: whether the `router` object gets closed for modification when you start accepting requests) but it's clearly not the intended use of the API as it doesn't match the simple language that is constructed by the API.

A great example of something that's clearly a DSL is [Ecto](https://hexdocs.pm/ecto/Ecto.html), the database wrapper/ORM for Elixir. Ecto has a full-on language defined with macros that gets translated to SQL. Take this example from the documentation:

```elixir
query = from u in "users",
          where: u.age > 18 or is_nil(u.email),
          select: %{name: u.name, age: u.age}
Repo.all(query)
```

It might seem like you can call any function in your query—perhaps replacing that `is_nil(u.email)` with something that checks the validity of the email instead—but Ecto completely redefines the rules of what can happen within the `from` clause. Since it's a macro, it's not limited by typical evaluation order of Elixir function calls, and can translate the syntax tree into anything it wants. However at the end of the day it does have to translate it to an SQL query, and SQL can't evaluate Elixir code.

Much like the scoping rules in the HTML builder, the code inside the `from` call are subject to Ecto's rules, not the standard rules of Elixir function calls.

One last thing that I think differentiates a DSL is a little unease about the exact execution order of your code within the DSL. Are you defining some behaviour that will be aggregated and evaluated later, or will each part simply be evaluated immediately, top to bottom? The HTML builder might defer the serialisation until it's requested, or it might serialise while you're calling the builder methods. Or it might serialise some parts, but leave others un-evaluated. If you put a break point or log statement right in the middle, are you confident you know when that'll actually trigger?

Something like a [Ruby Bundler gemfile](https://bundler.io/v2.5/man/gemfile.5.html) might _look_ like it's installing each gem when you call the `gem` function, but—I'm fairly confident—it's just defining a list of gems that it needs to install after the file is evaluated. You can't install a gem at the top of the file and then change the gems you're installing later based on the version you downloaded.

Of course none of these things are doing magic, they all need to use features of the language they live in, and are subject to that language's limitations—for better or worse. While that does mean that you can debug a DSL down to the non-DSL code that powers it, the intent of the DSL is that you don't have to, because if used correctly you don't think about how they're implemented, it's just a more convenient way to express your intent.

```ruby
inter = 'string interpolation'
question = "Is #{inter} a DSL?"
puts question
```
