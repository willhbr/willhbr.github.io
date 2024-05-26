---
title: How I Learned to Stop Worrying and Love Concurrency
tags: opinion design languages
---

Doing more than one thing at a time is still a somewhat unsolved problem in programming languages. We've largely settled on how variables, types, exceptions, functions, and suchlike usually work, but when it comes to concurrency the options vary between "just use threads" and some version of "green threads" that just allows for something that looks like a thread but takes fewer resources. We've also mostly been stuck on whether to _actually do_ more than one thing at a time[^not-at-the-same-time], rather than how best to do it.

> In this post I'm going to be talking about _concurrency_—the ability for a program to work through multiple queues of work, switching between them where necessary. This is distinct from _parallelism_ in that no two pieces of work will be happening at the same time. Of course parallelism has its place, but I'm interested in how concurrent programming can be made easier for most programs.

Many applications (I would argue most applications) benefit hugely from concurrency, and less from parallelism since IO is such a large part of many applications. Being able to send multiple network requests or read multiple files "at once" is useful for more applications than having multiple streams of CPU-intense work happening at once.

# Exceptions

Before we talk about concurrency, I want to introduce you to my newly-invented programming language. It works just like every other language, except the `return` keyword is replaced two new keywords: `yeet` and `hoik`. To accompany these two new keywords there will be two assignment operators, `y=` and `h=` (pronounced "ye" and "he"). `y=` will be used to receive a yeeted value, `h=` to receive a hoiked value. If you want to receive both, you can use both in the same expression. So for example:

```python
def get_value(a, b):
  if a == b:
    hoik a
  elif a < b:
    yeet b
  else:
    yeet a

x y= get_value(10, 5)
print(x) # => 10
x h= get_value(5, 5)
print(x) # => 5
p h= l y= get_value(1, 2)
print(p, l) # => None, 2
```

If a value is _hoiked_ or _yeeted_ but not received by the caller with `h=` or `y=`, the _hoiking_ or _yeeting_ will propagate up to the next function.

"Wow Will, that's so original. That's just exceptions." Yes, I know. I'm very clever.

The idea of having two different ways of returning from a function seems bizarre, until you take a step back and realise that most programming languages have two routes out of a function, you just don't really consider the second one. For example, what does this do:

```python
def parse_file(path):
  contents = read_file(path)
  data = parse_data(contents)
  return data

parse_file("~/config.yaml")
```

Does `parse_data()` get called? Well of course not, `config.yaml` doesn't exist, and so `read_file` raises an exception and `parse_file` re-raises the exception, exiting early. The alternate path(s) through the function are basically invisible and often not given much thought.

Like it or not, humans have a serious thing with the number two. Having two ways of propagating data from a function is no exception (pun absolutely intended), and the ability for most code to ignore the exceptional case is usually convenient. There are obviously some fairly severe downsides—resource usage should be wrapped with a `finally` (or similar) block to ensure cleanup happens, creating an exception with a trace is not free, and there are plenty of cases where something could be considered a valid return _or_ an exception (like an HTTP response with a `300`-block status code). It's up to the API designer to work out what should be communicated via a return value, and what should be communicated via an exception.

Swift has an interesting approach to exceptions; any call site that can raise an exception must be marked with `try` or its friends:

- `try` will re-raise the exception, forcing the function to be marked with `throws` and the caller one level up must handle the exception instead.
- `try?` will turn any exceptions into an optional, so if an exception is raised you just receive `nil`.
- `try!` converts the exception into a fatal error, stopping the program.

I like having an explicit marker of which calls could cause an exception and alter the flow of the program. It means that the typically-invisible alternate path through the program is clearer, and I know whenever I see `try`, control flow could be jumping or returning to a different point in the program.

This does have its downsides however; there is an implicit syntactic cost to marking a function as `throws`. Every caller then must choose to propagate or handle the exception somehow. In many cases this makes a lot of sense—if the call can fail, mark it as `throws` and add `try`. But what about calls that _should_ never fail, but can under some circumstances? Let's consider this fairly innocuous program:[^credit-to-acb]

[^credit-to-acb]: Credit to [@acb](https://mastodon.world/@acb) for pointing this out.

```swift
let text = "oh no"
let index = str.index(
  text.startIndex, offsetBy: 7)
print(text[index])
```

I've managed to create an index on the string that is outside its bounds. The subscript operator on a string isn't marked with `throws`, so its only options to communicate this failure are:

1. return some sentinel value (like an empty string)
1. crash the whole program
1. return invalid garbage and let the program continue running like nothing happened

Swift chooses the second option:

```
Swift/StringCharacterView.swift:158: Fatal error: String index is out of bounds
Current stack trace:
0    libswiftCore.so    0x00007fe01d488740 _swift_stdlib_reportFatalErrorInFile + 113
1    libswiftCore.so    0x00007fe01d163fe4 <unavailable> + 1458148
2    libswiftCore.so    0x00007fe01d163e64 <unavailable> + 1457764
3    libswiftCore.so    0x00007fe01d163b9a <unavailable> + 1457050
4    libswiftCore.so    0x00007fe01d163720 _assertionFailure(_:_:file:line:flags:) + 253
5    libswiftCore.so    0x00007fe01d29d54c <unavailable> + 2741580
6    swift-test         0x000055b8dbcd7e7a <unavailable> + 3706
7    libc.so.6          0x00007fe01c029d90 <unavailable> + 171408
8    libc.so.6          0x00007fe01c029dc0 __libc_start_main + 128
9    swift-test         0x000055b8dbcd7b55 <unavailable> + 2901
```

Aside from not giving us a stack trace, there's no way for me to recover from this failure[^maybe-not-fail]. If the function isn't marked as `throws`, it doesn't have a good way to report an unexpected failure. The result is that you're forced to ensure that every value passed to the subscript operator is valid—just like if you were programming in C.

[^maybe-not-fail]: Well maybe there is, I'm not a Swift expert. But we're talking abstractly about syntax here, just roll with it.

You could mark all methods like this with `throws`, but that adds a lot of syntactic noise for something that _should_ never happen. I'm sure that the end result would be most people using `try!` with a justification of "I know the index is within the bounds".

Java worked around this by having [two types of exceptions][java-ex], checked and unchecked. It's up to the developer to decide which is appropriate. You can make an API clearer either by including exceptions in the type system—forcing them to be handled in a similar (if more verbose) way to Swift—or omit them from the type system, having them crash the program if unhandled, but still _able_ to be handled in the same way as checked exceptions.

[java-ex]: https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html

> I presume the design of Swift's exceptions was driven by a desire to avoid checking for failure on every single function call. I'm more interested in syntax here, understanding the performance trade-offs is another topic entirely.

Swift is mostly the outlier here in terms of the status-quo of mainstream languages. The default exception-handling approach is that any function can throw an exception, and that exception will propagate up the stack until a caller catches appropriately. Designers of general-purpose application programming languages have generally decided that automatic error propagation and implicit error checking after each call is worth the performance trade-off. A language doing something different, for example requiring manual error handling, [is somewhat noteworthy](https://go.dev/blog/error-handling-and-go).

# `async` / `await` & Concurrency

The most popular[^most-popular] way of implementating concurrency into a language is using two keywords—`async` and `await`—to annotate points in the program where it can stop and do something else while something happens in the background. Usually this bridges to a historical API that uses something called a "future" or a "promise".

[^most-popular]: Measured entirely on vibes.

The basic idea behind a "future" or "promise" API (I'm just going to call them futures from now on) is that you want to save some code for running later, and often a little bit more code for after that.

The reason this works so well is that most languages don't have support for pausing execution of a running function and coming back to it later, but they _do_ have support for code-as-data-ish in the form of objects with associated methods, and often those objects can be anonymous[^anon-def]. So in Java land we could always do something like this:

[^anon-def]: This just means they don't have a real name, and are typically defined inline where they get passed to a function.

```java
HTTPTool.sendGetRequest(
  "https://example.com",
  new HTTPResponseHandler() {
    @Override
    public void handle(HTTPResponse response) {
      System.out.println(response.getBody());
    }
  });
```

The code in `handle()` (and any data that it has access to) is effectively saved for later. There's a suspension point _conceptually_ in my code, but the actual language doesn't really know that. It just knows about an `HTTPResponseHandler` object that it needs to hold a reference to so that `sendGetRequest` can call the `.handle()` method.

Where this gets _super_ messy is when you want to do one asynchronous thing after another. Say you want to make a second HTTP request with the result of the first, you'd have to do something like:

```java
HTTPTool.sendGetRequest(
  "https://example.com",
  new HTTPResponseHandler() {
    @Override
    public void handle(HTTPResponse response) {
      HTTPTool.sendGetRequest(
        response.getHeader("Location"),
        new HTTPResponseHandler() {
          @Override
          public void handle(HTTPResponse response) {
            System.out.println(response.getBody());
          }
        });
    }
  });
```

This results in a [Pyramid of Doom](https://en.wikipedia.org/wiki/Pyramid_of_doom_(programming)) where each level of async-ness is another level of indentation. Futures work around this problem by allowing "chaining", inverting how the callbacks are built and avoiding nested indentations:

```java
HTTPTool.sendGetRequest("https://example.com")
  .then(response ->
    HTTPTool.sendGetRequest(
      response.getHeader("Location")))
  .then(response -> {
    System.out.println(response.getBody());
  });
```

This is obviously much better with Java lambdas, which are less verbose than writing out a full anonymous class implementation, but are conceptually the same thing. However we're still using closures to hack around the fact that we can't pause a function.

Most futures APIs are pretty good at chaining a bunch of requests together, but when you get to anything more complicated, you end up having to use a sub-language that operates on futures: continue when all these finish, when one of them finish, do this if one fails, etc. It's fairly easy to lose track of all your futures and leave one doing work to produce a result that is never used.

What `async`/`await` does is allow us to write the closures inline in the body of the function, so our code would end up like this:[^switch-languages]

[^switch-languages]: Part of the joy of reading my blog is getting confused as I change language in the middle of a series of examples. This next one is in Swift, since Java doesn't have `async`/`await` yet, and Kotlin's implementation is less clear about `await`-ing things.

```swift
let response = await HTTPTool.sendGetRequest("https://example.com")
let url = response.headers["Location"]
let response2 = await HTTPTool.sendGetRequest(url)
println(response2.body)
```

The code reads as though the code blocks until a value is available, but what is effectively happening is that at each `await`, the compiler splits the function in two, and inserts the necessary code to turn the latter half into a callback. This way you can integrate into an existing language without having to change your byte code interpreter—Kotlin does this so it can have concurrency and still interop with Java.

When you're introducing this awesome function-splitting compiler trick, you can't do it by default for all functions, since anything from before the trick (ie: Java code) won't know anything about the implicit callbacks and so won't be able to call them correctly. To solve this problem you introduce [function colours](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function)—some functions are asynchronous, some functions are synchronous, and there are rules about how they interact. In general it looks like this:

- Synchronous functions can call synchronous functions
- Asynchronous functions can call synchronous functions
- Asynchronous functions can call asynchronous functions
- Synchronous functions can **cast** to asynchronous functions

I'm borrowing the term [**cast** here from Elixir/erlang](https://www.erlang.org/doc/man/gen_server#cast-2). Casting over in that world is sending a message but not receiving a result. In most languages with `async`/`await` you can start an asynchronous function, but you can't get a result from it—since you don't know when it will finish, and your function can't split into a callback to run when the async call finishes.

This split system introduces a problem similar to how Swift handles exceptions—you can only do async work from an async context. If you don't get called from an async context, you can't do any async work and receive the result. This makes it harder to reach for async as a tool—as soon as you've made one major API async, all callers of it must be async, and all callers of _them_ must be async. It will propagate through your codebase like a wildfire.

Unlike exceptions, you can't safely handle async work in a non-async context without risking deadlocking your program. A function that doesn't throw an exception can call a function that does throw one, it just needs to handle the failure within its body and return an appropriate result. A synchronous function can't do this if it needs to call an async function. In some cases it may be able to block the thread while it waits for a result, but in a single-threaded context, the async function never gets an opportunity to run, and so the program deadlocks. In a multi-threaded context, some work might still be constrained to a single thread (ie: the UI thread or a background thread) and if you block on that you will deadlock.

The worst thing is that often blocking the thread will _work_, but it introduces a possibility of all of your threads blocking on async work at the same time, preventing any of the async work from progressing, deadlocking your program _but only sometimes_.

So why do we have `async` and `await` in the first place? As far as I can see there are two reasons, the first is that we don't want to break compatibility with non-async code that can't be automatically split into callbacks. The second is that we want to make it explicit that on an `await` point, the program can go off and do something else—potentially for an indefinitely long amount of time. Even if you call an async function that only takes two milliseconds to finish, most implementations use co-operative multitasking and so there's no protection against some function calculating primes in the background preventing a context switch back to your function.

> ["Co-operative" multitasking](https://en.wikipedia.org/wiki/Cooperative_multitasking) means that each function is responsible for ensuring that there are enough points that it yields control back to the scheduler to make progress on some other work. If there's a huge CPU-intensive calculation going on that doesn't yield, then nothing will happen concurrently until that calculation is completely finished. ["Pre-emptive" multitasking](https://en.wikipedia.org/wiki/Preemption_(computing)) will proactively stop one function if it's running for too long and do some other queued work.

If you're making a brand-new language that isn't saddled with backwards compatibility to an existing language or runtime, would you make this same tradeoff? The [best language ever][crystal] ([Crystal](https://crystal-lang.org)) and notable poster-child of concurrency ([Go](https://golang.org)) both omit the need for an `async` keyword.

[crystal]: https://willhbr.net/2023/06/24/why-crystal-is-the-best-language-ever/

In both languages, every function is treated as async. At any point[^with-yield] in a function, execution can swap to a different function and do some work there before swapping back. Much to the fear of people that like their code to be explicit, at any point in your program, an arbitrarily large gap in execution could happen.

[^with-yield]: As long as a function yields, see co-operative versus pre-emptive note above.

Before I used a language with `async`/`await` I had heard people talking about how amazing it was, and always got confused because I was used to writing concurrent code in Crystal (or Go before that) where this was not needed. I felt like I was missing something and that this syntax would unlock some new way of doing things, but the reality is just that it's most often just a way to bridge to a old API because of backwards-compatibility constraints in the language.

> Rust is in a particularly tricky situation with async, as their no-runtime and zero-cost abstractions goals mean they can't just wrap the whole program in an event loop. I don't know much about Rust—much less writing async code using it—but found these posts to be an interesting look at the history and state of async in Rust:
>
> - [_The State of Async Rust: Runtimes_](https://corrode.dev/blog/async/) by Matthias Endler
> - [_Why async Rust?_](https://without.boats/blog/why-async-rust/) by @srrrse
> - [_Why you might actually want async in your project_](https://notgull.net/why-you-want-async/) by John Nunley

# Using Concurrency

That's less than half the battle. We can pause a function mid-execution, but we haven't actually done two things at the same time[^not-at-the-same-time]. The biggest benefit of non-blocking IO is that you can easily send off two slow requests (eg: over the network) and only wait for the slowest one before continuing, rather than doing them in sequence. This is another API design challenge. The simplest example looks like this:[^simple-diagram]

[^not-at-the-same-time]: Yeah yeah, I know it's not actually at the same time, see my note right at the top. But you know what I mean, otherwise you wouldn't have read the footnote. If you're the type of person to correct a concurrency-versus-parallelism mistake, you're also the kind of person that will read a footnote to be absolutely accurate in your correction.
[^simple-diagram]: Appreciate my effort- and bandwidth- saving ASCII diagram.

```
        B
      /   \
 o - A     D - o
      \   /
        C
```

Our function starts on the left, does some processing in `A`, does `B` and `C` at the same time, and then once both have finished does the final step `D`. There are plenty of ways you could handle this, and the measure of a good API is how easy it is to do the right thing—not introducing race conditions, unexpected behaviour, memory leaks, etc.

The example I'll use here is something you might see in the world's most naive web browser—we're going to load a page and try to also load the favicon for that webpage at the same time. Here's one example in Go, a language that doesn't have any notion of `async`/`await` because every function can be interrupted at any point:

```go
func loadPage(url string) WebPage {
  pageChan := make(chan []byte)
  faviconChan := make(chan []byte)
  go sendRequest(url, pageChan)
  go sendRequest(url + "/favicon.ico", faviconChan)
  page := <-pageChan
  favicon := <-faviconChan
  return WebPage{page: page, favicon: favicon}
}
```

And here's an example of the same function in Swift, that does have `async`/`await`:

```swift
func loadPage(url: String) -> WebPage {
  async let page = sendRequest(url)
  async let favicon = sendRequest(url + "/favicon.ico")
  return WebPage(page: await page, favicon: await favicon)
}
```

> Ok I'm going to pause here and say that the following section is basically just my notes on Nathaniel J. Smith's post [_Notes on structured concurrency, or: Go statement considered harmful_][no-go]. I recommend it, it's a good read. You can come back to this later.

[no-go]: https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/

The main difference here is that Go doesn't have any higher-level abstractions for dealing with concurrency as values, just as _goroutines_ using the `go` keyword, and channels using the `chan` keyword. We have to hand-craft any structure in our concurrency with our bare hands. Appropriately, Swift has a keyword for this. Instead of immediately `await`-ing an async function, we can assign it to a variable with `async let` and then `await` the value later.

What happens when our code gets a little more complicated? Let's say we're writing a program to fetch posts from our favourite blogs. We know that some have an Atom feed, and we should prefer that if it exists, otherwise we should fall back to the RSS feed. This might look something like:

```go
func getFeedsFrom(url: string) []Feed {
  atomChannel := make(chan Response)
  rssChannel := make(chan Response)
  go fetchFeed(url + "/atom.xml", atomChannel)
  go fetchFeed(url + "/rss.xml", rssChannel)
  atomResponse := <-atomChannel
  if atomResponse.IsSuccess() {
    return parseItems(atomResponse)
  }
  rssResponse := <-rssChannel
  return parseItems(rssResponse)
}
```

Seems reasonable? The problem is that `go fetchFeed(url + "/rss.xml", rssChannel)` can outlive the lifetime of the function if we get a successful response back for the Atom feed first. My program would just have a process running in the background doing useless work that I don't care about, and there's nothing in the language to help me do this correctly.[^maybe-go-better] Some languages with `async`/`await` can have the same problem, it's just spelled slightly differently. Depending on the implementation, if a value is not `await`-ed, it will continue running in the background and any result or error discarded. For example this JavaScript example is much more succinct, but it has the same problem in that the RSS result will not get cleaned up when the function returns:

[^maybe-go-better]: Maybe Go has some library for keeping track of your goroutines, but my basic point is this is not the default and not what I see people doing.

```javascript
async function getFeeds(url) {
  let atom = fetchFeed(url + "/atom.xml")
  let rss = fetchFeed(url + "/rss.xml")

  let atomResult = await atom
  if (atomResult.success) {
    return parseItems(atomResult)
  }
  return parseItems(await rss)
}
```

You don't think about it as much since you don't have the explicit `go` keyword here, but you are doing the same thing. The control flow splits in two, one fetching the Atom feed and one fetching the RSS feed, and then you wait for the results.

Swift and Kotlin do this very well,[^basically-vorpus] I'm going to use Kotlin as an example here since it does things a little more explicitly. The only place you can split your function is within a `CoroutineScope`. By default, the scope will only finish when every coroutine in it has finished. So the previous example would look like:[^kotlin-style]

[^basically-vorpus]: They basically do the [previously mentioned blog post][no-go].
[^kotlin-style]: Yes I know my Kotlin function could be more idiomatic and shorter, but then everyone would be getting confused about Kotlin's weird syntax, instead of getting confused at concurrency.

```kotlin
suspend fun getFeeds(url: String): List<Feed> {
  return coroutineScope {
    val atomAsync = async {
      fetchFeed(url + "/atom.xml")
    }
    val rssAsync = async {
      fetchFeed(url + "/rss.xml")
    }

    val atom = atomAsync.await()
    if (atom.success) {
      return@coroutineScope parseItems(atom)
    }
    return parseItems(rssAsync.await())
  }
}
```

This will wait for `rssAsync` to finish before `coroutineScope` returns. Even though we've got an early return on a successful fetch of the Atom feed, we'll still implicitly wait for the RSS feed. If the RSS feed takes ages to respond, our whole function will take ages. This is the price to pay for encapsulation. `coroutineScope` enforces our concurrent code to be a diamond pattern, instead of that fork pattern:

```
Always this:
        B
      /   \
 o - A     D - o
      \   /
        C

Never this:
        - - - - - B - - - - - - ?
      /
 o - A     D - o
      \   /
        C
```

`coroutineScope` isn't something magical, it's just a function with a block argument[^magic-block] that exposes the `async` method and keeps track of anything launched using it. If I find the "wait for everything to finish, even on early return" behaviour to be limiting, I can just write another function that uses the same building blocks to give me that behaviour:

[^magic-block]: Ok Kotlin's blocks are _kinda_ magic.

```kotlin
suspend fun <T> coroutineScopeCancelOnReturn(
    block: suspend CoroutineScope.() -> T): T {
  return coroutineScope {
    val result = block.invoke(this)
    currentCoroutineContext().cancelChildren(null)
    return@coroutineScope result
  }
}
```

As concurrency is tied to a scope, we can use this building block to create our own scopes with different behaviours—mine makes it easier for blocks to cancel outstanding work after an early return, but you could equally easily make a scope that included a timeout, or limited the number of async calls happening at any one time. Most of the time you should only need the `coroutineScope` builder function, but there's nothing stopping you from having a global variable that's a scope, and having things work more like Go, where any function can start work in the scope that outlives the life of the function. It's easier to spot however, since you just need to look at the cross-references for the global scope to find who's using it. In Go you would have to manually inspect every function and understand how they handled concurrency to be sure that nothing was leaking.

The usage of scopes to handle concurrency changes how APIs are written. Take a basic HTTP server in Crystal:

```crystal
server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  context.response.puts "Hello world!"
end

spawn do
  sleep 5.minutes
  server.close
end

server.bind_tcp "0", 8080
server.listen
```

After five minutes, what will this do? [The documentation](https://crystal-lang.org/api/1.10.1/HTTP/Server.html#server-loop) for `#close` says:

> This closes the server sockets and stops processing any new requests, even on connections with keep-alive enabled. Currently processing requests are not interrupted but also not waited for. In order to give them some grace period for finishing, the calling context can add a timeout like `sleep 10.seconds` after `#listen` returns.

So the fibres spawned by the server (that run the block passed to `.new`) won't be cancelled (which makes sense since fibres in Crystal can't be cancelled) and will be left dangling. If Crystal had scoped coroutines like Kotlin, you could more easily change and reason about the behaviour by passing in a different scope to the server to use for handling requests—currently you have no guarantee that code in the `.new` block won't run after `.listen` returns, or in theory any point after that, since an HTTP connection could take a prolonged time to establish before the handler code is run.

This would support the common use-case of cancelling outstanding requests when the server shuts down, but could easily be changed to add a timeout grace period, or stop the whole server if there is an unhandled exception (instead of printing it and continuing like nothing happened).

This implementation that uses scopes to control concurrency basically allows you to start building towards an Erlang [supervisor tree](https://www.erlang.org/doc/design_principles/sup_princ.html).[^not-erlang]

[^not-erlang]: Ignoring the fact you don't have memory isolation for each process so you'll never fully get there.

> When I was in university I [wrote a Slack bot using Elixir](https://github.com/willhbr/bot_bot). It originally didn't handle the "someone's typing" notification from the Slack API, which caused it to crash. The (Elixir) process that ran the bot would crash, and the supervisor would replace it with another identical process. The storage was handled in a separate process, no data was lost and the bot would reconnect after a few seconds. If I had been using almost any other language, the end result probably would have been my whole program crashing, and me having to fix it immediately.

Having language support for cancelling pieces of work is also useful in a lot of other contexts, POSIX processes can be interrupted with a `SIGINT` which often trigger some kind of callback in the language, and the callback needs to communicate to any currently-running things that they should stop. Cancellation being a first-class citizen could allow for better default behaviour when a program is told to stop. This same concept could apply to applications in resource-constrained environments (ie phone OSes) so that they can respond effectively to being stopped due to lack of resources.

# Concurrent Data

Once you've got the lifetime of your concurrency sorted, you need to work out the lifetime and access for your data. Rust does this with lifetime annotations and more static analysis than you can point a stick at, [Pony](https://www.ponylang.io) has six [reference capabilities](https://tutorial.ponylang.io/reference-capabilities/reference-capabilities.html#immutable-data-can-be-safely-shared) that define how a variable can be used in what context. Erlang and Elixir just have fully immutable data structures, so you can't mutate something you shouldn't—you can have "mutable" data in a stateful process and introduce a race condition by multiple processes sending messages to the stateful process.

When I'm writing stuff in my free time I usually have a fairly cavalier attitude to thread safety. Crystal doesn't have many guarantees for this, and since it's currently single-threaded, most of the time it works fine. I'll write some dirty code that spawns a new fibre that does some work and appends the result to a list. That's always atomic—right?

I haven't written enough Rust to appreciate what it's like working with the borrow checker and lifetime annotations. From what I've read ([a recent example](https://jsoverson.medium.com/was-rust-worth-it-f43d171fb1b3)) the borrow checker is frustrating, to say the least.

What I'd like is—somehow—for concurrent data access to be verified as easily as types are checked in Crystal. I get most of the benefits of static typing and dynamic typing by using Crystal's type inference, can the lifetimes of variables be inferred in a similar way? I think this would be a very hard problem, and probably only practical if the general population of developers was already used to adding lifetime annotations—like they are with types—so you could just require fewer of them.

For me, the best concurrency system would be one that doesn't require any tagging of functions, to avoid having to think about function colouring and the syntactic cost of annotating every call site, and a well-defined structured concurrency API that is used throughout the standard library and third party libraries, to give guarantees about the lifetime of concurrent work. This would need to have affordances to handle pending concurrent work as values (like Swift's `async let` or Kotlin's `Deferred<>`), and enough tools in the standard library to make it easy to handle these values. I don't have particularly strong opinions about actors, lifetimes, or reference capabilities[^perhaps-2] as I've not used them much to write any real-world programs.

[^perhaps-2]: Perhaps that's part 2? Subscribe to the RSS feed for more!

If you liked this and want to read something by someone who knows what they're talking about, I would recommend reading [_Notes on structured concurrency, or: Go statement considered harmful_][no-go]. Reading this was definitely the "ah-ha" moment where I was convinced that just tacking a `spawn` function in your language wasn't good enough.
