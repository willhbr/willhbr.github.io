---
title: "Limited Languages Foster Obtuse APIs"
---

On the topic of the [design decisions of a low-level system limiting the design space of things built on top of them][design-decisions], the design of programming languages has a significant impact on the APIs and software built using them.

[design-decisions]: /2023/07/06/why-modernising-shells-is-a-sisyphean-effort/

Go is heralded by the likes of Hacker News and r/programming as modern, exciting, and definitely not anything like Java, which is old and boring. Java developers spend their days writing abstract factory interfaces and generic strategy builders, whereas Go developers spend their time solving Real Problems™. Although if you squint a bit, you can see the similarities between Go and Java, and perhaps see where Go developers might end up.

Let's think about factories. I'd include a quote from _Effective Java_ here, but I don't have a copy handy. The tl;dr is that you use a factory so that you're free from the limitations of object construction in Java. When you call `new MyThing()`, you can only get one of two things; an exception, or a new instance of `MyThing`. If you call a static method like `MyThing.create()`, then you can get absolutely anything. Of course, good taste would prevent us from returning _anything_, but we can do things like cache expensive objects, or return a different `MyThing` subclass.

A concrete example (I know some people like that kind of thing) would be the main interface to an RPC framework[^rpc-framework]. `Connection.create(String url)` could return a different implementation based on the protocol of the URL passed in (TCP, HTTP, Unix socket, in-memory, etc). The normal constructor syntax can't do this, so you end up with a recommendation for developers to prefer static constructor-methods in case of future flexibility.

[^rpc-framework]: This is like, _my_ favourite thing.

Go has this exact same limitation. Struct creation is a different and special type of syntax. It can only do one thing—create a new instance of a struct (it can't even throw an exception because Go doesn't have those). This leads to the recommendation for packages to have a function that creates the instance for you:

```go
func MakeMyThing(a string, b int) MyThing {
  return MyThing{a: a, b: b}
}
```

Does this look familiar?
{:class="caption"}

Struct initialisation in Go also has a surprising feature: it will silently set any attributes to their default value if the attribute is omitted from the list. So this code compiles without any warnings:

```go
type MyThing struct {
  foo string
  bar string
}

func main() {
  fmt.Println(MyThing{foo: "hello"})
}
```

And `bar` will silently be set to `""` (the default value for a `string`). If you want to have any guarantee that attributes will all be set correctly, or be able to add an attribute to a struct and know that all usages have it set, you should wrap the creation of the struct in a factory function.

The other limiting factor for Java is the handful of types that have special syntax in the language. Only the builtin number types, strings, and arrays can use operators and the subscript syntax, there is no mechanism for these to be used on any user-defined type. So if you have a method that returns some data as a `byte[]` (for performance or convenience or whatever), and you want to change it to be `MyByteSequence`, you have to change all subscripts over to be a method call, since you define that operator on `MyByteSequence`.

Go has the exact same limitation; only number types, strings, slices, and maps use the operator and subscript syntax. In both cases this means that if you want to build an abstraction over the underlying data, you need to wrap them in a struct/object and define functions/methods on that object.

> Prior to [generics being added](https://go.dev/doc/tutorial/generics) to Go, there was even more limited ability to build abstractions on top of the built-in types.

The effect of this is that you end up with a bunch of code that is entirely composed of method or function calls. Which doesn't seem like much of a problem on the surface, but you end up in a state where every operation looks the same, making it hard to see the "shape" of what the code is doing.

This is the exact problem that keeps me from enjoying Lisp (and _oh boy_ have I tried to enjoy Lisp). When I look at any non-trivial piece of Lisp code, I have a lot of trouble working out what is actually happening because every action has equal precedence—literally. Clojure does a commendable job at improving this by adding TWO additional types of brackets that allow for some glanceable differentiation.

```clojure
; the square brackets make it easier to find the
; function arguments
(defn my-method [foo bar]
  ; the curly brackets allow for defining different
  ; types of commonly-used literals, like a map
  {:foo foo
   :bar bar})
```

Java code ends up devolving towards a similar type of syntax, since the only part of the syntax that you get "access" to is method calls. I used [an example earlier in the context of Crystal][crystal-best] about using time APIs in Java:

[crystal-best]: /2023/06/24/why-crystal-is-the-best-language-ever/

```java
// This Java code
Duration.ofHours(4).plus(Duration.ofMinutes(5))
// Is surprisingly similar to Clojure
(.plus (Duration.ofHours 4) (Duration.ofMinutes 5))
```

I think one of the reasons that I find Elixir easier to read than Clojure is that it has much more syntax, so different actions actually look different. In Clojure, [a `case` statement][clojure-case] looks just the same as a method call, whereas in [Elixir the addition of an infix `->` operator][elixir-case] to separate the match from the code makes the code block much easier to read.

[clojure-case]: https://clojuredocs.org/clojure.core/case
[elixir-case]: https://elixir-lang.org/getting-started/case-cond-and-if.html

Now, if you're a particular type of person who solves every problem with a profiler and a flame graph, you're probably preparing an argument about how overriding operators and subscripts allows for hiding potentially expensive operations. If developers are discouraged from using the built-in types that support these operators, then your expensive operations are just hidden behind a method call. Every Java 101 class tells you _never_ to use an array, instead use `List<>`. Who knows how `.get()` is implemented in that list? It could be a linked list, and each call could be an O(n) operation. Would it really be much worse if that was behind a subscript instead of a method?

Unless you're using some capabilities-based language where you can limit the type of operations a module can do, any function call could result in a network request or slow inter-process communication. It could even just do some blocking I/O, wasting valuable time that your thread could spend doing something more interesting.

Limiting language features for the sake of performance issues is ignoring what actually causes performance issues: slow code. Slow code can be called from anywhere, and limiting the expressiveness of the language seems like a high cost when you're going to have to find your bottlenecks using a profiler anyway.

Of course no blog post about languages would be complete without me explaining how Crystal is perfect. There are _virtually_ no special operators in Crystal. Operators are implemented as methods on the left-hand operand, subscripts are just a special method called `[]`. The exception is that the array shorthand is linked to the built-in `Array` type, so `[] of String` is equivalent to `Array(String).new`.[^actually-overridable]

[^actually-overridable]: There are [actually variations of this syntax](https://crystal-lang.org/reference/1.8/syntax_and_semantics/literals/array.html) that other types can override.

What this really boils down to is that programming language design should limit the amount of syntax that are bound to specific types. In Java this is operators and subscripts, in Go this is also includes channels. The Java ecosystem's obsession with design patterns and abstraction is fuelled by the lack features in the language, requiring developers to invent another sub-language on top using the pieces of Java that they have access to—types and method calls. Go might have different built-in tools (like coroutines and channels) but since they are baked right into the language syntax, they can't be replaced or altered as developer needs change.


