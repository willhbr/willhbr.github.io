---
title: "Async Programming Is Just @Inject Time"
tags: languages
---

All I really wanted to do was learn a little bit more about different models for error handling, but then I kept seeing "effects" and "effect systems" mentioned, and after reading about [Koka][koka] and [Effekt][effekt-lang] I think I've been converted. I want effects now. So here's what I wished I could have read a few weeks ago.

[effekt-lang]: https://effekt-lang.org/
[koka]: https://koka-lang.github.io/

To start with, you need to remember that functions don't exist. They're made up. They're a social construct.

Your CPU doesn't know or care what functions are,[^have-not-asked] they're purely a book-keeping abstraction that makes it easier for you to reason about your code, and for the compiler to give you some useful feedback about your code. It's the whole idea with [structured programming][structured-programming]: build some abstractions and have a compiler that can make guarantees about them.

[structured-programming]: https://en.wikipedia.org/wiki/Structured_programming
[^have-not-asked]: Ok I haven't asked mine.

I've never really done much assembly so this wasn't something I'd had to contend with too much, but functions are interesting because they're a fixed entry point with a dynamic return point. Let me show you what I mean with this C program:

```c
int first_function() {
  // ...
  return 10;
}

int some_function() {
  // ...
  int number = first_function();
  return 4 + number;
}

void main() {
  first_function();
  some_function();
}
```

When this program is compiled, the compiler knows exactly where the instruction pointer needs to jump to get to `first_function` and `some_function`, since it knows exactly where in the executable it put them. Chances are that if you looked at the assembly they would each just be a single instruction to jump a nice fixed offset.

What happens when we get to the `return` statements? `first_function` is called from both `some_function` and `main`—there isn't just a single place that we can jump back to. The compiler doesn't know when it's generating the code for `first_function` who's going to be calling it.

How this works is that alongside any function arguments, there's an invisible argument[^architecture] passed that contains the position of the instruction where it made the jump to the top of the function. The compiler knows what the instruction address is—it's the one that puts it there—and so for each function call site, that's just a static piece of information that gets passed in. At the end of each function, the compiler just has to generate some code to read that argument (usually stored in a CPU register somewhere, but it doesn't have to be), jump back to that location, and continue execution.

[^architecture]: More or less, depending on architecture I guess? I'm not a CPU instruction set expert, but this is the general concept.

You don't think about this complexity because the abstraction is so solid and yet gives immense flexibility to write complicated programs.

The resolution of which function to call can get more complicated by taking into account the number of arguments and their types, instead of just the name of the function.

That's the simplest case—static dispatch that is known at compile time—but higher-level languages introduce dynamic dispatch, where a function call could end up jumping to one of many different locations. A great example of this is Java:

```java
class MyClass {
  @Override
  public String toString() {
    return "my class";
  }
}

Object someObject = new MyClass();
someObject.toString();
```

The `toString` method that gets called depends on the type of the receiver object. This isn't determined at compile time, but instead a lookup that happens at runtime. The compiler effectively generates a `switch` statement that looks at the result of `getClass` and _then_ calls the right method. It's smarter than that for performance I'm sure, but conceptually that's what it's doing.

This abstraction continues to work really well because if you've developed in Java (or any of the many many languages that share this behaviour) you quickly internalise the behaviour of the method resolution algorithm, and it's almost never surprising which bit of code ends up being executed. The compiler might need a runtime lookup to check, but you can use your big human brain and work it out with deduction while you write the code.

So in Java (and basically every other object-oriented language) we have dynamic function dispatch as well as a dynamic return jump at the end of each function.

In C we don't have any dynamic lookup inside functions—every dynamic jump comes from an explicit conditional statement—but in Java and other higher-level languages we can pass an object to a function, and call a method on that object. Since the receiving function doesn't know the type of the object at compile time, any method calls on it will be completely dynamic:

```java
String someMethod(Object object) {
  return "This could be anything: " + object.toString();
}
```

`someMethod` might be statically dispatched, but the call to `toString` will have to be dynamically resolved depending on the type of `object`.

In `someMethod`, the call to `toString` will end up jumping to code that is entirely controlled by the object that is passed in as an argument. The CPU (or in this case, JVM) will lookup the location of `toString` on whatever type of object it is, and jump there.

Just like with the function resolution algorithm, this complexity is manageable both because of the function call abstraction—we know that control will jump into the other function and then return back to our function—as well as type safety—we know the returned type will be a `String`, so we don't need to worry about how we got it.

This is something that I find interesting in Rust; since there's no runtime dynamic dispatch "by default" you have to be very explicit by wrapping your type in `Box<dyn MyTrait>`, or if you want your dynamism at compile time you can use `impl MyTrait`.

Now if we're going to jump to an arbitrary bit of code, why not put that bit of code at the call site? That's what happens when we create an anonymous subclass:

```java
someMethod(new Object() {
  @Override
  public String toString() {
    return "heh a new string";
  }
});
```

The actual location in the source file doesn't really matter—the compiler will end up putting it wherever it feels like—but from a syntax point of view, we've now got control flow that jumps into `someMethod`, then back into our `toString` method, returns to `someMethod`, and then finally back to the call site.

This is such a useful pattern that most languages have dedicated syntax for this: closures! I love closures so much that [I wrote a review of the various closure syntaxes][closure-syntaxes]. Let's jump out of the JVM for now and appreciate this lovely Swift closure:

[closure-syntaxes]: /2024/06/28/a-critique-of-closure-syntaxes/

```swift
[1, 2, 3].map { number in
  number * 3
}
```

Instead of all that boilerplate to make a new object, we basically just write a block of code that will be used by the function we're calling. What's interesting here is that we're not in complete control when that block of code is running. It might appear like it, but we can't do anything except give a value back to the function.

This creates the limitation where you can't create custom control flow that integrates with control flow that's built into the language. Closures can provide values and have side effects, but they've got limited ability to stop the function that called them from running.

Both Ruby and Crystal work around this limitation in interesting ways, but that's getting a little bit ahead of ourselves.

We're going to forget about closures for a minute and talk about error handling. I promise it'll make sense.

# Error Handling

The most basic form of error handling is what you get in Go; if something didn't work, you return a value that says so. By convention the caller checks that value and typically just returns it to say that whatever it was trying to do also didn't work.

```go
func getConfigPath() (string, error) {
  path, set := os.LookupEnv("CONFIG_PATH")
  if !set {
    // The variable isn't set, report an error
    return "", fmt.Errorf("CONFIG_PATH not set")
  }
  return path, nil
}
```

This is conceptually very simple, it's building slightly on the function abstraction by allowing multiple return values, but little else. If a function can fail, you can see from its function signature that it will return an error, like in `getConfigPath` above.

With this model we have to write out the `return nil, err`  after each function call, but semantically we can think of control flow "jumping" to the point where we do something other than immediately return the error.

```go
func getConfig() (*conf.Config, error) {
  path, err := getConfigPath()
  if err != nil {
    return nil, err
  }
  f, err := os.Open(path)
  if err != nil {
    return nil, err
  }
  config, err := configFromFile(f)
  if err != nil {
    return nil, err
  }
  return config, nil
}

config, err := getConfig()
if err != nil {
  panic(err)
}
```

In this example, any error in loading the path, reading the file, or parsing the config will all direct control flow back to the top-level code and to the `panic` call.

Skipping over macros that make it more succinct to return an error, the next iteration of this pattern is checked exceptions in Java. Any function that can fail is annotated with what is effectively a second return value. The thing that's different is that there's nothing at the call site needed to return this value, it will be implicitly passed back up through the call stack (each one dynamically resolved, remember) until we hit a `catch` block, which is just a bit of code that takes that return value and does something with it, not that different to the Go example above.

If we ignore the fact that exceptions in Java are typed, all that's actually happening here is that every time we enter a `try` block, the compiler records in memory the location of the instruction corresponding to the start of the `catch` block. As we keep calling more functions, some of them might have `try` blocks of their own, and those are added onto a stack—a shorter stack than the actual call stack, since not all functions have a `try/catch`. When an exception is thrown, instead of looking up the location the function is supposed to return to, we consult the stack to find the topmost `catch` block, and jump straight there. We've just done a `return` that has skipped over multiple functions all in one go.

Of course the actual behaviour is much more complicated as it has to worry about `finally` blocks and types and all that, but the core idea is the same.

Have you got all that? This is where things get weird.

When an exception is thrown, what if the compiler grabbed the instruction pointer and stored it somewhere before jumping out to the `catch` block? Then if you wanted, inside the `catch` you could choose to jump back—multiple layers of function calls—into the code that failed as though nothing had happened.

Let's say that we could grab the current instruction pointer location—which the compiler will know for every line of code, since it's the one generating the instructions—with a special variable called `__instruction__`.

Something like this (if C had `catch` ... or `throw`):[^ignoring-stacks]

[^ignoring-stacks]: Ignoring stack frames and suchlike and the fact `goto` can't jump across functions.

```java
int some_function() {
  print("At the start...")
  throw __location__;
  print("I'm back!");
}

try {
  some_function();
} catch(error_location) {
  print("Caught an exception!");
  goto error_location;
}
print("Finished.");
```

In `some_function` we `throw` and jump out to the nearest `try` in our call stack, passing the current instruction back. In the code up the call stack we can run some code and then `goto` back to where the `throw` happened, resuming the function where we left off.

The output would look like this:

```
At the start...
Caught an exception!
I'm back!
Finished.
```

Well, that's effects. Almost.

# Coroutines

There is another feature similar to effects that is called "coroutines". This is confusing because that's what people often call lightweight threads, which are often implemented with some version of coroutines, even if you can't use them in the language for other stuff. Coroutines allow you to stop the execution of a function and then resume it later, usually passing values back and forth in those steps.

I first came across coroutines in the [Wren](https://wren.io) programming language. I got very confused by its [concurrency](https://wren.io/concurrency.html) since by default it's not the "throw stuff at the wall and it'll run at kinda the same time" model that Go and Crystal have.

```swift
var fiber = Fiber.new {
  System.print("Before yield")
  Fiber.yield()
  System.print("Resumed")
}

System.print("Before call")
fiber.call()
System.print("Calling again")
fiber.call()
System.print("All done")
```

That gives this output:

```
Before call
Before yield
Calling again
Resumed
All done
```

Instead of the fibre running in the background (or "background" depending on your scheduler) it runs until it hits `Fiber.yield()` then it stops and waits for someone to call `.call()` again.

This is really powerful for writing a lexer and parser that work together without having complicated code, or by storing an entire intermediate result in memory before passing it to the next stage. The lexer can trundle along and once it's got a full token it can `yield()` that value. The parser just continually runs `.call()` whenever it needs a new token to process. They're passing off control between each other in a more complicated way than just calling a single function and getting back a single result. The code in the lexer and parser can be more freely structured as any function can `yield()` or `call()` whenever a value is found or needed.

Remember how I wrote [thousands of words about concurrent programming][love-concurrency]? Well the secret to any language that has `async`/`await` is basically that they can do this "jump to `catch` and then resume again later" trick.

[love-concurrency]: /2023/10/31/how-i-learned-to-stop-worrying-and-love-concurrency/

Ignore the fact that `catch` usually means exceptions which usually means some kind of failure. A piece of code is running and it just started some work that's going to take a long time in the background, there's no point waiting and the program can do something more useful while the stuff happens in the background. It "throws" an exception that is caught by a scheduler multiple layers of function calls up the stack. The scheduler saves the return address into a list of pending work to get back to, and then goes to find something that it can make progress on. Eventually it completes the other work and is signalled that our background task is complete. It pops the return address off the list and jumps to it, continuing the function call exactly where it left off as though nothing happened.

If you take nothing else from this post, just know that `async`/`await` is just weird exceptions that you can undo.

Now the problem that plagues both `async`/`await` and exceptions is that they're typically not integrated into the rest of the type system. In Java you can't have a type or function that is generic over whether it will throw an exception.

```java
String readFileOrFail(String path) throws IOException, FileNotFoundException {
  File file = new File(path);
  if (file.exists()) {
    return FileUtils.read(path);
  } else {
    throw new FileNotFoundException("file doesn't exist");
  }
}

List.of("one.txt", "two.txt", "three.txt")
  .stream()
  // doesn't work!
  .map(name -> readFileOrFail(name))
  .collect();
```

The `map` method only accepts a lambda that doesn't throw any checked exceptions, so we can't directly call our `readFileOrFail` method. Ideally it would be able to generically say "I throw the same exceptions as the lambda I receive" but you can't do that in the Java type system.

This isn't helped by the fact that Java has mostly given up on checked exceptions and instead opted for purely unchecked, runtime exceptions that offer no compile-time guarantees.

Swift is a little better in that it has the `rethrows` keyword that can mark a closure and function as failing with the same exceptions as the closure.

You get the same story with `async` functions. Swift has a [whole separate library][async-seq] for dealing with async operations on collections, because the methods on the existing collections can't be generic to support both synchronous and asynchronous versions. There's no such thing as `re-async`.

[async-seq]: https://developer.apple.com/documentation/swift/asyncsequence

So here we go: all any of these things—closures, exceptions, suspending functions—are just ways of jumping forwards and backwards to different places, and some compiler guarantees to ensure that any jumping can happen in a structured, safe way. And that's what effects give you, and some more.

# Effekt

[Effekt][effekt-lang] is a research language with effect handlers and effect polymorphism (it says so on the website!). I also read the docs on [Koka][koka] but ended up writing the most code in Effekt.

From the [language tour on Effekt effects](https://effekt-lang.org/tour/effects), an effect is written with an `interface`:

```ruby
interface Exception {
  def throw(msg: String): Nothing
}
```

In this case we'll `throw` with a `String` and then the effect handler will give us `Nothing` back. In this case that's a somewhat magical `Nothing` type that tells the compiler the function will never return, but it could be a real value, which we'll see in later examples.

Then we have a function that uses the effect:

```ruby
def div(a: Double, b: Double) =
  if (b == 0.0) { do throw("division by zero") }
  else { a / b }
```

What's interesting here is how that `throw` changes the function signature of `div`. In this example it's elided since it will just be inferred by the compiler. We could write it as `Double / { Exception }`, which says we're returning a `Double` and we'll use the `Exception` effect. This means we can only call it from somewhere with an `Exception` effect handler, like this:

```ruby
try {
  div(4, 0)
} with Exception {
  def throw(msg) = {
    println("oh no the div failed: " ++ msg)
  }
}
println("finished")
```

The control flow will start at `try`, then jump to the `div` function, since the `b` argument is `0`, `div` will invoke the `throw` effect. The effect will jump control flow back down into the `def throw` block, and we'll print the error. Since we didn't call `resume()` the control flow will continue after the `try` block and run the last `println`.

Effekt effects get their power with the `resume` keyword. This swaps them from acting like exceptions and makes them act like `async`/`await`. Control flow jumps to the effect handler, which can then do some work and call `resume` to continue from the point that triggered the effect.

Let's continue with the `Exception` example, but make it possible to recover from errors. The effect would be a little more complicated:

```crystal
interface Exception[T] {
  def throw(msg: String): [T]
}
```

Now we can throw an exception with a message, and the exception handler can give us back a value to use instead.

```ruby
val result = try {
  div(4, 0)
} with Exception {
  def throw(msg): Double = {
    println("oh no the div failed: " ++ msg)
    resume(42.0)
  }
}
println("finished: " ++ result)
```

The `div` function will be called, and it'll again `throw` back to our exception handler. This time we print the error but then `resume` with a value. In `div` this is used as the result of the `do throw` expression.

In Koka this can get even more wild [where `resume` can be called more than once][multi-resume]. This forks off the original function so there are two instances, each progressing with different results. This is absolutely wild.

[multi-resume]: https://koka-lang.github.io/koka/doc/book.html#sec-multi-resume

The key here is that you don't have to call `resume` immediately. Just like how you can store a closure to compute some result later, you can wrap `resume` in a closure and wait to call it some other time. The state of the function that triggered the effect will be stored with the closure just like any other data. You can see this in action in the [Effekt async example](https://effekt-lang.org/examples/async.html).

# Effects versus `yield`

That's only just scratching the surface of how you can use effects for control flow. Something I found interesting while reading this is realising that Crystal's `yield` keyword is just like a little baby effect system.

Crystal inherits the somewhat complicated block semantics from Ruby. This is exposed with the `Proc` type and the `yield` keyword. The simple example from the [documentation](https://crystal-lang.org/reference/1.19/syntax_and_semantics/blocks_and_procs.html):

```crystal
def twice(&)
  yield
  yield
end

twice do
  puts "Hello!"
end
```

The `yield` keyword yields (aahh!) control back to the calling function. In this example the block of code "passed" to `twice` is run two times. This is not too dissimilar to passing a `Runnable` to a Java method:

```java
void twice(Runnable block) {
  block.run();
  block.run();
}

twice(() -> {
  System.out.println("Hello!")
});
```

Except the `yield` in Crystal is more powerful, because the caller can change the control flow in the function that accepts the block. You can `break` from within a block and cause an early return, or `return` from within the block and return from the method the block is in—not the method it's calling.

```crystal
def find_mod_2(items)
  items.each do |i|
    if i % 2 == 0
      return i
    end
  end
end
```

That `return` statement will stop the execution of `each` _and_ return from `find_mod_2`. If this was another language, or if `each` was implemented with a `Proc` rather than a `yield`, you would have to return a special value to indicate you wanted to stop, or raise an exception. This is how Crystal gets away with having no `for` loop in the language.[^not-macros] Otherwise the block would simply cede control to the method that called it.

[^not-macros]: Well apart from the macro language, which is kinda separate.

What's confusing is that you use the same syntax to create a `Proc` which _can't_ affect the control flow of the function that called it, and has the same limitations as other languages like Java. If you think about the implementation it makes sense, a `yield` cannot be stored and run later, outside of the execution of the method it is in, whereas a `Proc` can be stored as an instance variable and executed much later. Like, how would this work?

```crystal
class Thingie
  getter block : Proc(Nil)? = nil

  def do_thing(&block : Proc(Nil))
    puts "setting thing"
    @block = block
  end
end

def use_thingie(th : Thingie)
  th.do_thing do
    return "this is a value!"
  end
  puts "Am I unreachable?"
end

th = Thingie.new
use_thingie
th.block.call # what should happen here?
```

How can `use_thingie` ever finish if the `return` statement is in the `Proc`? What should happen when the `Proc` is called? It can't return from `use_thingie` since that function will have already finished by the time it's called.

The Crystal compiler knows this doesn't work and the program will fail to compile:

```
In test.cr:12:5

 12 | return "this is a value!"
      ^
Error: can't return from captured block, use next
```

This is the exact same distinction as [Swift's `@escaping` closures][swift-escaping-closure], except Swift doesn't allow control flow in non-escaping closures anyway.

[swift-escaping-closure]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/#Escaping-Closures

`yield` in Crystal is a very simple version of effects, since it will only allow jumping up one layer in the call stack, if you want to forward a block you need to re-`yield` when you call another function. There's also only one possible receiver, the single block passed to the function will be used for all `yield` statements.

# Dependency injection is just effects

You can only use an effect if somewhere up the call stack there is a place where that effect will be handled. In Java you need a `catch` around every `throw`, even if for runtime exceptions you can skirt around this slightly. In languages with `async`/`await` you must decorate a call to an `async` function with `await`, and the function you're calling _from_ must be `async`. Eventually up the call stack you'll get to a call that adds the async work to a task queue, executor, or blocks waiting for it to complete. These are all examples of effect handlers for async programming. They provide the scheduling effects that the async code needs in order to run.

This can define lexical scopes; no code outside of places where a certain effect handler is installed may use that effect. My mind is broken in just the right way that when I realised this, I thought "that's just dependency injection".

The key of ([Dagger](https://dagger.dev)-style) dependency injection is that you can only access certain dependencies in certain parts of the application, and how those dependencies are constructed is separated from their actual use. I like this so much I [implemented it with Crystal macros](/2026/01/31/crystal-dependency-injection/).

Since effects propagate up, they naturally support nested scopes. When an effect is triggered for a dependency provided by a wider scope, it will skip over the handler for the inner scope and jump straight to the outer handler to get the dependency.

This code is still fairly verbose, you would likely want some code generation or macros to tidy it up and make it less of a pain to write. We start with an injection effect:

```ruby
interface Inject[A] {
  def get(): A
}
```

As long as we have the right type annotations, we can `do get()` to defer to the effect handler to provide us with a value:

```ruby
def functionWithDeps(): Unit / { Inject[Logger], Inject[Config] } = {
  val logger: Logger = do get()
  val config: Config = do get()
  logger.log("Doing stuff, this config: " ++ show(config))
  doImportantStuff(config)
}
```

This function can only be called in contexts where we can inject both a `Logger` and a `Config`. This is what the function call at the scope root would look like:

```ruby
def doWithInjection() = {
  val config = buildConfig()
  val logger = getLogger()
  try {
    functionWithDeps()
  } with Inject[Config] {
    def get() = resume(config)
  } with Inject[Logger] {
    def get() = resume(logger)
  }
}
```

This would obviously be unwieldy with lots of dependencies, but that could either be handled by clever type-system trickery, macros, or code generation. You'd also want to create the objects lazily, which I've neglected to do here.

What's neat about this is that it works on functions rather than objects, so you're not forced to indirect things through lots of different classes if you don't want to.

# Effect syntax

Since many languages already have an effects-adjacent way of throwing and catching exceptions, the syntax changes required to support arbitrary effects are actually fairly minimal. Effects could slot quite nicely into the Swift syntax, at least the parts that I can think of. Since you want to stay as close to the existing `throws` and `async` keywords, I'd propose listing the effects between the argument list and the `->` before the return type, like this:

```swift
// No effects
func foo() -> String {}
// One effect
func foo() async -> String {}
// Two effects, one with a type parameter
func foo() throws<Error>, async -> String {}
```

It doesn't fit with other types in Swift, but I think the names of effects should be lowercase to appear more like "tags" than "types", although I could be persuaded for consistency to uppercase them. Since an effect might have any number of generic parameters, you'd have to specify those within angle brackets which is a little ugly but not terrible.

Defining the effect would be similar to an enum definition:


```swift
effect async {
  case suspend
  case cancel
}
```

This fits well because you're yielding to a particular case in the effect, and you can add associated data to each `case` in just the same way you do for enums:


```swift
effect throws<T: Error> {
  case throw(T)
}
```

Just like Effekt, I think the `do` keyword is nice to indicate that you're doing something with an effect. I think this would be required on any function call that has an effect, like this:

```swift
func fetchUserInfo(id: Int) async -> User {
  let info = do userInfoLoader.load(id)
  return User(from: info)
}
```

At a point that we want to handle the effects, you would put a block that will match on the effects used in the `do` expression. Currently in Swift this is the `catch` keyword, but since this has to be more general I think `when` is a better fit. It would read as "do that, and when this happens, do this other thing".

```swift
do {
  do userInfoLoader.load(id)
} when throws(error) {
  Log.error("Unable to load user \(id): \(error)")
  return nil
}
```

If you need to handle multiple effects, you'd tack on extra `when` blocks just like you can with `catch` blocks today.

The case with `throws` would be—like Effekt—a special case for an effect with a single type. For effect handlers with multiple cases, the body of the `when` block would be equivalent to a `switch` statement:

```swift
do {
  do asyncScheduler.doSomeWork()
} when async {
  case suspend: {
    self.pendingTasks.append {
      resume
    }
  }
  case cancel: {
    self.onTaskCancelled()
  }
}
```

What I think is interesting about this exercise is that from a syntactic point of view, there isn't really that much to change. Functions can already be tagged with a fixed set of effects, and there's already syntactic structures to handle them.

# Do you want effects?

I got into this mess because I was reading about ways of handling errors and also ways of handling async programming.

Much like generics, I don't think most code would have to worry about defining their own effects or effects handlers. Having exceptions and `async`/`await` not be something that's built into the language and instead be something that's built _with_ the language would be really cool. The language could be less prescriptive over how async code is written, perhaps allowing certain codepaths to have strict guarantees on how fibres can be cancelled, for example.

This might be the way to get structured concurrency into a language without placing the entire burden on the language itself. It would allow library authors to dictate the contexts in which certain functions could be called, enforcing structure and correctness. In most garbage-collected languages many contracts are only enforced in documentation saying "don't hold onto a reference to this object", which I've also [written about before](/2024/09/05/implicit-lifetimes-and-undroppable-types/).

Effects would also be valuable in code that deals with deadlines or other scoped data that is typically stored in dependency injection, thread local variables, or passed through function calls manually. Instead of constantly checking the deadline, you could just augment the existing suspension effect to fail at any suspension point when a deadline has run out. Any code that needs to operate with a deadline simply couldn't be called from contexts without a deadline.

I've focussed mostly on how effects relate back to exceptions and async code, since those are control-flow constructs that I (and probably you) are most familiar with. I haven't given much thought to what it would be like to write code where all I/O is handled through effects. If you had to annotate every single function and function call that you wanted to do I/O, I imagine that would get really tedious. If the language had good type inference on the required effects, then it might not be so bad.

When I [wrote all about concurrency][love-concurrency] I argued that all code should be async by default—like Go or Crystal—since there's already so much implicit behaviour going on in your typical program, you might as well get low-cost I/O while you're at it. I do think there are contexts where it's useful to know that you aren't going to suspend for an arbitrarily long amount of time, like a UI handler, and having the ability to write APIs that require no effects would allow these kinds of guarantees.

So there you go, I started out wanting to understand error handling and instead learnt that everything I know about programming could somehow be linked back to one language feature. If you want to read more, I'd recommend starting with the [Effekt][effekt-lang] and [Koka][koka] language tours (I just skipped straight to the good bits).

Please take my explanations of how function calls, and exceptions work here as illustrative rather than literal. I wanted to give an example of the _kind_ of thing the computer is doing without getting too bogged down in how the computer actually does it. The aim of this is to think more about how control flow works with different languages, rather than how you'd actually implement it.
