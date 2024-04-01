---
title: "Optimising for Modification"
tags: opinion
---

It is an accepted wisdom that it's more important to write code that is easily read and understood, in contrast to writing code that is fast to write[^run-fast]. This is typically used in discussions around verbose or statically typed languages versus terser dynamically typed languages.

[^run-fast]: Or even fast to run, in some cases!

The kernel of the argument is that it doesn't take you _that_ much long to write a longer method name, spell out a variable in full, or import a class. Wheres it can take someone reading the code significantly more time if they have to trace and guess at every single variable name and function call to understand what the code is doing.

The classic examples are Java's excessively long class names, Ruby's convoluted one-liners for data manipulation, or Swift's overly verbose method and argument names. For example here's how you trim whitespace characters from a string in Swift [from StackOverflow](https://stackoverflow.com/questions/26797739/does-swift-have-a-trim-method-on-string):

```swift
let myString = "  \t\t  Let's trim all the whitespace  \n \t  \n  "
let trimmedString = myString.trimmingCharacters(in: .whitespacesAndNewlines)
```

Whereas in Ruby it's just `" my string \t".strip`.

In Swift, the writer of that code has to know—or lookup—the longer method with a potentially not-obvious argument[^argument-labels], but it would be incredibly clear to a reader what that method is doing. The writer of the equivalent Ruby code would have to remember a single word, but the reader may have to check what characters are included in the `.strip` operation.

[^argument-labels]: They've also got to know that `in:` is the argument label, I find this constantly baffling as `charactersIn:` seems like it could be an equally-good argument label, so you have to remember both the full "trimming characters in" name of the method, and where in that name the arbitrary separator between what's the method name and what's the argument label.

Another example is Go's previous lack of support for building generic abstractions[^generics]. The counter-example was always to just write the code out by hand, using a classic `for` loop or `if` statement. So instead of doing this:

```ruby
buildings.map(&:height).max
```

You would do something like:

```go
maxHeight := 0
for _, item := range buildings {
  if item.Height > maxHeight {
    maxHeight = item.Height
  }
}
```

[^generics]: Until Go [added support for generics](https://go.dev/doc/tutorial/generics), which I have not yet used.

No hidden behaviour, and super easy to understand.

---

I don't want to try and argue where on this spectrum is best. I have a different metric that I want to optimise for: the ease of manipulation.

I spend a lot of time changing code to understand how best to implement, refactor, or debug a problem, and languages that are more explicit code end up getting in the way.

I'll just reach for `System.out.println` in Java because the fully-productionised logging class requires me to add an import and edit my build config.

I might not use `.map` and `.filter` in my final code, but it sure is convenient to have these around to transform data either to print it, or to quickly pass it to another part of the application.

Having static types is absolutely valuable when undergoing a large refactor to build confidence that you haven't completely messed something up, but when I just want to move some code around to see if I can change some behaviour, having to re-define interface definitions and then contend with anything _else_ that breaks is a frustrating experience. It would be great if I could just turn off type checking in single files while I work.

An easy example of this is when you're doing something that unifies the behaviour of a bunch of objects, and will almost certainly result in defining some common interface for all the classes to implement. However in the interim you just want the compiler to treat all the objects as being the same shape, despite the fact that from the compiler's point of view they have absolutely nothing in common.

Since I'm a big `printf` debugger, languages that don't have a sensible default for printing objects is a huge pain. Remembering to use whatever the method is that turns a Java array into a human-readable string is the absolute worst. Ruby is great here because every object has a `.inspect` method that will dump the value of all instance variables, which is incredibly convenient. Of course you could attach a debugger, but having it available programmatically allows you to dump it into your applications UI if necessary, without having to re-run with a debugger attached.

Other times I might want to just:

- Call a private methods
- Read a whole file without writing lines of [`InputStreamReader` boilerplate](https://stackoverflow.com/questions/2049380/reading-a-text-file-in-java)
- Throw an exception that I didn't declare
- Catch that exception somewhere else
- Redefine a method on an existing class

Swift's error handling actually has a few of these features—the `try!` and optional unwrap `!` syntax are great examples of convenience features for hacking something together that should never get past a code review.[^swift-no-fail]

[^swift-no-fail]: As I [wrote before](/2023/10/31/how-i-learned-to-stop-worrying-and-love-concurrency/) Swift has some weird trade-offs when it comes to exceptions.

Of course it's no surprise that Crystal has a lot of these features (it is of course the [best language ever](/2023/06/24/why-crystal-is-the-best-language-ever/)). Being able to punt some best practices to the back seat is incredibly convenient, and not something that I've seen included much in discussions on readability versus writability of code.
