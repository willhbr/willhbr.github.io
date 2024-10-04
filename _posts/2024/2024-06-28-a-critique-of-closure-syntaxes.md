---
title: "A Critique of Closure Syntaxes"
tags: languages
---

I love a good closure, but not all languages have a good syntax for writing them. What makes a good closure? What does your closure syntax say about your language? Do you call them lambdas, blocks, closures, or anonymous functions? Does Will know how to end this intro?

# Go

Let's start off with something boring. Go does the absolute minimum while still actually allowing closures. You can use the exact same syntax you use for regular functions.

```go
// Here's a regular function
func main() {
  // and here's a closure
  fun := func() {
    println("hello!")
  }
  fun()
}
```

It's a function in a function. Can't really ask for much else, can we? (spoiler: we can).

To write type of a closure (for example to receive it as an argument) also uses the same syntax: `func(int32, int32) string` is the type of a function that receives two `int32` args and returns a `string`.

# Python

Python just goes that extra few centimetres, you can use the same syntax inside a function, but there's also the `lambda` keyword as a shortcut for single-expression closures:[^correction]

[^correction]: Previously my example incorrectly showed it being possible to omit the name in `def` and use it as a value, but this is not the case, thanks Susanne for the correction!

```python
def main():
  def func(a):
    return a + 41
  # can be written as:
  func = lambda a: a + 41
```

The `lambda` keyword is a bit verbose for my liking, and Python's indent-based blocks don't really lend themselves well to many alternatives that are longer than one expression.

# Clojure

Clojure is similar to Python in that it has a fairly mundane shorthand:

```clojure
; This is a normal function definition
; I included this because not everyone knows Clojure
(defn normal-func [a]
  (+ 41 a))

; And here's a closure
(fn [a] (+ 41 a))
```

You can pop that `fn` form as an expression anywhere:

```clojure
((fn [a] (println a)) "hello!")
```

This is your brain on Lisp. Parents: talk to your children about Lisp before Paul Graham does.
{:class="caption"}

Closure also has an even shorter form backed by [a "reader macro"](https://clojure.org/reference/reader#_dispatch), which allows for single-expression closures with implicitly named arguments:

```clojure
; This expression
#(println %1)
; Translates to
(fn [%1] (println %1))
```

# Elixir

Elixir is similar to Clojure in that its "full" function syntax isn't that much more verbose than the closure syntax:

```elixir
# This is a function
def some_function(args) do
  args
  |> Enum.map(fn arg ->
    # And that ^^ is a closure
    arg * 2
  end)
end
```

Closures have all the same pattern-matching, multiple body abilities as regular functions, and since everything in Elixir is immutable, they don't really "capture" variables in the same way as other languages.

The pattern matching syntax is slightly different as the closure is written as one expression, whereas the full function is written as overloads:

```elixir
def list_empty?([]) do
  true
end

def list_empty?(_) do
  false
end

list_empty_closure = fn
  [] -> true
  _ -> false
end
```

# Rust

For a fancy modern language, Rust is fairly conservative with its lambda syntax. I guess it makes sense with Rust's focus on correctness and predictable behaviour, they're not going to add something to build crazy DSLs—we'll get to some of those later.

The syntax looks like this:

```rust
// With a type-inferred argument, and a single expresssion
my_vec.map(|x| x * 2);
// With a typed argument, and multiple statements
my_vec.map(|x: i32| {
  let result = x * 2;
  result
});
```

The multi-statement syntax works well since all code blocks in Rust can produce a value by omitting the trailing semicolon on that line (or with a `return` statement, I'm not too hot with Rust to tell you for sure).

# Java

Java's closures are a pretty horrible hack, but we try not to hold that against them, after all we're rating the closure syntax, not their implementation.

The syntax comes in three basic forms:

```java
// No arguments, single expression.
() -> println("Hello!");
// Single argument, single expression.
message -> println(message);
// Multiple arguments, multiple statements.
(a, b) -> {
  String c = a + ": " + b;
  return c;
};
```

This is pretty nice, especially compared to most of Java's syntax. It's fairly terse, clear, and doesn't get mixed up with other parts of the language. `->` is a nice token to split the arguments from the lambda body, it doesn't appear anywhere else in the Java language. Allowing the brackets (both round and curly) to be omitted in certain cases allows this to be really syntactically lightweight in common cases:

```java
List.of(1, 2, 3)
    .filter(x -> x % 2 == 0)
    .map(x -> x * 2)
    .reduce(0, (acc, x) -> acc + x);
```

The weirdest thing about Java's lambdas is that they're the only place where the types of parameters can be omitted, and the compiler will infer them from context. This is obviously a syntax benefit, but it's odd to break the rules established in the rest of the language—we'll see this come up again a few times. If you want to be explicit, or the compiler can't infer types correctly, you can specify the type of arguments:

```java
Function<String, Integer> getLength = (String input) -> input.length;
```

The biggest difficultly when using lambdas in Java is the fact that you need to understand how they're implemented, and remember the built-in "functional interfaces" that back them.

For the uninitiated, Java lambdas are just syntactic sugar around anonymous implementations of interfaces with single methods. The most common is `Runnable`—an interface with a single `run()` method that takes no arguments and returns no result. Another common one is `Supplier<T>` which takes no arguments but returns an object of type `T`. You've then got `Consumer<T>`, which does the opposite, `Function<T, R>` which does both, and `BiFunction<S, T, R` because variadic generics are too complicated. So basically:

```java
// This lambda
Runnable r = () -> println("hello!");
// gets translated to
Runnable r = new Runnable() {
  @Override
  public void run() {
    println("hello!");
  }
};
```

# JavaScript

Somewhat appropriately, JavaScript's closures are pretty similar to Java. The traditional syntax looks like a normal function (without the name, like Python):

```javascript
let closure = function(input) {
  return input * 12;
};
closure(4); // returns 48
```

And then the new syntax looks just like a Java closure, except with a `=>` instead of `->`. It shares the same shortcuts to omit the round brackets if there's a single argument, and omit the curly brackets if there's a single expression in the body.

```javascript
// No arguments, single expression.
() => console.log("Hello!");
// Single argument, single expression.
message => console.log(message);
// Multiple arguments, multiple statements.
(a, b) => {
  let c = a + ": " + b;
  return c;
};
```

Just like Java, the short form doesn't bind to `this` in the closure body, but if you write out the function (or anonymous class) in full, it will bind `this`.

# C++

C++ does the classic C++ thing of using all the different symbols in one go.

```cpp
auto closure = [&capture](int argument) {
  return argument * 2;
};
```

The obvious difference is that unlike most other languages, C++ won't automatically capture variables for you. You need to specify how variables are closed over, either by reference with `&`, by pointer with `*`, or by value with no prefix. Most of the time I'd just capture everything by reference with `[&]`, since for functions that don't store the closure and just call it before they return, you're not likely to run into retention issues.

It's a messy syntax, but it gets the job done and fits in with the requirements of C++.

# Swift

Someone found Swift's syntax to be confusing enough that they registered  [fuckingclosuresyntax.com](https://fuckingclosuresyntax.com) to list all the different spellings of Swift closures.

This is the point in the syntax list where the syntaxes flip from being good at defining a standalone value, to instead being better for passing as an argument for a function. You can always do this in Swift:

```swift
let myClosure = { (arg: Int) in
  print("the arg: \(arg)")
}
myClosure(1234)
```

The syntax starting with a curly brace is a bit weird, as in many C-inspired languages, that is used to define a scope. Swift actually forbids you from having an unused closure expression, I assume due to the fact that people might incorrectly assume that they're creating scopes.

What Swift really wants you to do is use a trailing closure where possible:

```swift
// Boring
let mutator: String -> String  = { element in
  element.reversed()
}
myList.map(mutator)

// New and exciting, with trailing closure
myList.map { element in
  element.reversed()
}
```

I think that all languages should allow trailing closures, it makes closures feel like a first-class part of the language, not something that's bolted on from spare parts, like it is in Java.

Swift does have one (mostly understandable) messy syntax: `@escaping`. If your closure is going to outlive the function it's passed to, you need to annotate the argument with `@escaping`. Nothing wrong with that, but it looks a bit weird to have something that's _basically_ a language keyword look like it's an arbitrary annotation.

The other annotation-looking thing you might come across is `@autoclosure`, which is absolutely awesome and I don't know why more languages don't have this. It lets you change the evaluation order of expressions passed in as function arguments. Every other language is boring and evaluates them in the order they're listed at the call site, but Swift lets you change that so the arguments are evaluated whenever you want.

```swift
func test(message: @autoclosure () -> ()) {
  print("Hello")
  message()
}

test(message: print("world"))
```

This will print "Hello" and then "world". To get this behaviour with any other language you'd have to wrap `print("hello")` in the appropriate lambda syntax at every call site.

Clearest win for `@autoclosure` is logging libraries: you can use all the nice—and expensive—string interpolation in what looks like a normal method call, but you don't have to evaluate it if logging isn't enabled. Other languages like Crystal make the block syntax part of the logging API to get this same behaviour.

```swift
class Logger
  static func log(msg: @autoclosure () -> String) {
    if loggingEnabled {
      // The message is only built if we're actually going to use it
      logInternal(msg())
    }
  }
}
// That debug info will only be calculated when we're actually going to use it
Logger.log("I just did \(getExpensiveDebugInformation())")
// Other languages use an explicit closure
Logger.log {
  "I just did \(getExpensiveDebugInformation())"
}
```

This is so neat that the builtin `&&` and `||`  operators are implemented with `@autoclosure` to support short-circuiting (where the right hand side of the expression is only evaluated depending on the result of the left). I learnt this from [this post](https://www.douggregor.net/posts/swift-for-cxx-practitioners-error-handling/) but you can go and [look at the code yourself](https://github.com/apple/swift/blob/382a8e765399e44fa830bef509cf979217b4f62c/stdlib/public/core/Bool.swift#L282).[^open-source]

[^open-source]: Woooo, open source!

Where most languages would accept that trailing closure syntax is best limited to a single block, and to use a different pattern if you need to pass multiple blocks, Swift doesn't know how to say no. You can pass multiple trailing closures:

```swift
loadPicture(from: someServer) { picture in
    someView.currentPicture = picture
} onFailure: {
    print("Couldn't download the next picture.")
}
```

The second closure is passed as `onFailure` to `loadPicture`. At this point I would probably opt for a builder pattern, where you set callbacks and then execute the request. That would have the disadvantage of all the closures being marked as `@escaping`—since they would outlive the method on the builder that set them—which I think has a performance penalty.

This is where you consider what the _actual_ problem you're trying to solve is, and realise that setting a bunch of callbacks is not productive and [instead you should support concurrency in your language](/2023/10/31/how-i-learned-to-stop-worrying-and-love-concurrency/) so that `loadPicture` can just suspend and return a result when it's ready, removing the need to write closures entirely.

# Kotlin

The syntax in Kotlin is very similar to Swift:

```kotlin
myList.map { value -> value * 2 }
```

The `in` keyword is replaced by `->` , and they also allow trailing closures.

Kotlin goes beyond what Swift has with _receiver blocks_. Instead of the closure being evaluated in the lexical scope of where it is written, it can be evaluated within the scope of another object. This is the building block that backs the [Flow](https://kotlinlang.org/docs/flow.html) API, a lot of the [couroutines](https://kotlinlang.org/docs/coroutines-guide.html) helpers, and a whole bunch more.

To a developer, this basically gives the impression that within a block, you've got access to additional functions and variables that aren't accessible outside. In the structured concurrency API this means you can only call `async` inside of a `coroutineScope` block, or similar.

Receiver blocks can definitely get confusing—it's basically breaking the method-lookup pattern that is almost the same across every language—but it gives the ability for libraries to make APIs that look like they're part of the language, which is something that [I am a fan of](/2023/07/09/limited-languages-foster-obtuse-apis/).

What I don't like about Kotlin's closures is that if you want to return a value from them, the `return` must be annotated with the name of the function that is receiving the closure. For example:

```kotlin
myList.map { num ->
  // Not allowed
  return num * 2
}
myList.map { num ->
  // Gotta do this
  return@map num * 2
}
```

I understand why you'd do this—heavy use of the block syntax can make it confusing where you're returning from—but it does mean that you end up structuring your code a bit differently to avoid having to write out `return@coroutineScope` too many times.

Kotlin does also allow using the normal method-definition syntax to create a closure, so this is a totally valid Kotlin program:

```kotlin
println((fun(a: String) = "$a world!")("howdy"))
// => howdy world!
```

# Crystal

Crystal doesn't really have a closure syntax that stands alone, instead you use the block syntax to pass some code to a function that returns a callable closure.

```crystal
closure = Proc(String, Nil).new do |name|
  puts "Hello #{name}!"
end

closure.call "world"
```

The `do |name| ... end` syntax can't be used anywhere other than being passed as an argument to a function. The `Proc` type just wraps that block up in a thing you can call later. The thing that always catches me out is the generic types on `Proc`—a single type is the return, if you give multiple types then the last one listed is the return type and the rest are the argument types. It's just `arguments*, return`, but somehow I forget that every time I write a `Proc`. The good thing is that you rarely construct a `Proc` in most Crystal code.

Just like Kotlin (and Ruby), Crystal also allows for evaluating blocks in a different lexical scope than the one they are defined in:

```crystal
struct String
  def with_me(&block)
    with self yield
  end
end

"a string".with_me do
  # this calls #size and #upcase on "a string"
  puts size, upcase
end
```

I've used this to make a simple HTML builder for my [status page library](https://github.com/willhbr/status_page).

# Ruby

Ruby works the same way as Crystal, except they've also got the "stabby lambda" syntax:

```ruby
closure = ->(args) {
  puts args
}
```

Which I think looks a bit weird, and prefer to just use the `proc` helper method that works like `Proc(T).new` in Crystal:

```ruby
closure = proc do |args|
  puts args
end
```

Things get a little bit weird when you consider how trailing blocks work with function calls that omit brackets:

```ruby
method_call argument do |a|
  puts a
end
# Does that code work like this:
method_call(argument) do |a|
  puts a
end
# Or like this:
method_call(argument() do |a|
  puts a
end)
```

More specifically: is the block passed to `method_call`, or to `argument`? Every Ruby programmer probably knows this intuitively, and this is where the curly brackets come in:

```ruby
# The block is passed to `argument`
method_call argument { |a|
  puts a
}
# The block is passed to `method_call`
method_call argument do |a|
  puts a
end
```

I'd explain this in term of associative-ness, but I can never remember which is which. The curly brackets will stick to the function call closest to them, `do ... end` will stick to the outermost call. This means you can do:

```ruby
method_call method_call { |a| puts a } do |a|
  puts a
end
```

And each `method_call` will receive a block each. It's just up to your good taste to avoid writing code like this.

There's a pretty clear split here between languages with closures that are better for using as values, and others with closures that are better as arguments to functions. Java and JavaScript's shorthands are nicely suited to being standalone values, Crystal and Ruby only work as function arguments, and Swift and Kotlin can be used as values, but they work much better as function arguments.

In general I like the ability to build APIs that appear to extend the language, so closures that look like code blocks are my favourite. However, no language has what I think is the ideal: a terse closure syntax that matches how functions are defined. Take Swift, for example:

```swift
func some_function(arg: String) -> String {
  ...
}

let closure = { arg: String -> String in
  ...
}
```

In a closure, the argument list goes after the token that starts the block (`{` in this case), but in a function it goes before. In other parts of the language, the bindings for the block go before the curly brace, like in a conditional:

```swift
if let binding = the_optional {
  ...
}
```

We're defining that `binding` will be available within that block, and it is listed before the brace, more like a function definition than a closure. You can't use closures to make an API that has this pattern of defining a binding before the block where it is going to be used.

I'll keep on the lookout for a language that makes these syntaxes match, but I think it's a natural tradeoff between these two types of closures.

Closures seem to be the point in a language where everyone suddenly gets on board with heavy type inference, implicit returns, and removing unnecessary syntax like curly braces around single expressions. It's amazing how much is inferred in a Java lambda compared to the rest of the language[^java-8].

[^java-8]: In Java 8, aka the only Java version anyone actually uses. I don't know what weird stuff has been cooked up in newer Java versions.

The closure feature I think more languages should adopt is compile-time guarantees on how many times a block will run. I was pleasantly surprised that [Rust closures](https://doc.rust-lang.org/book/ch13-01-closures.html) come in three flavours: `FnOnce`, `Fn`, and `FnMut`. This is necessary to work with Rust's ownership model, but other languages could make use of this to allow for smarter checking of variable initialisation. To give an example:

```crystal
def initialise_with_random(&block)
  yield Random.rand
end

number: Int32
initialise_with_random do |num|
  number = num.to_i
end
puts number
```

It is not possible to get to that `puts` call without `number` being assigned, but the compiler doesn't know that. If I could annotate that block as an `FnExactlyOnce`, the compiler could both check that I do actually call it, and also know that my variable will always be initialised.

Of course the real answer is that I should just use Lisp and be able to define my own syntax for everything using macros.
