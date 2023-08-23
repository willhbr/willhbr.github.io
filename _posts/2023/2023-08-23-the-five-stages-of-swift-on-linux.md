---
title: "The Five Stages of Swift on Linux"
---

Recently I attempted to learn about Swift's async support by doing my favourite thing—writing an RPC framework. In this case the "RPC framework" is just a request/response abstraction over websockets (which are message-based), which makes the actual RPC bit very simple, as all it's really doing is wrapping some objects and matching responses to requests.

In doing this, I think I went through all five stages of grief[^not-grief], which often happens when I try and use Swift on Linux—despite my [previous excitement about it](/2015/12/04/welcome-to-swift-org/).

[^not-grief]: Yeah I know the titles don't really match the content, I just did this for a funny title, alright?

# Denial

So first of all I found [the documentation](https://developer.apple.com/documentation/foundation/urlsession/3181171-websockettask) for `URLSession#webSocketTask(with:)`. At first glance the API seemed pretty reasonable. I had a quick read over some blog posts and ended up with some code to test out:

```swift
let task = URLSession.shared.webSocketTask(
  with: URL(string: "ws://brett:9080")!)
try! await task.send(.string("test message"))
```

Don't use this code as an example. It doesn't work. That's the whole point—keep reading.
{:class="caption"}

This seems pretty easy, I create a websocket task and then send a message using it. The message should be received by a simple Crystal [`HTTP::WebSocketHandler`](https://crystal-lang.org/api/1.9.2/HTTP/WebSocketHandler.html) and logged, so I know when it's working.

I run the program, and it just hangs. No error, no timeout (at least not one that I was patient enough to wait for). Now there isn't anything that I can see from the documentation that I'm missing (mostly because [there is no documentation](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask/3767360-send) for `send(_:)`).

Eventually I look back over the blog posts and see that you need to call `resume()` on the `URLSessionWebSocketTask` for it to do anything.

# Anger

This is very frustrating. If I were writing the documentation for this class, I would make sure that the requirement to call `resume()` was the first thing anyone saw when looking at the docs. Currently you have to go to the `URLSessionTask` superclass and find the [`resume()` method docs](https://developer.apple.com/documentation/foundation/urlsessiontask/1411121-resume) which state:

> Newly-initialized tasks begin in a suspended state, so you need to call this method to start the task.

A friendly API would raise an exception if you tried to use it before it was ready—failing fast is going to reveal your problem more readily than silently doing the wrong thing. However, I don't know enough about the wider `URLSession` API know whether there's a design tradeoff here that makes failing fast impractical.

Ok so I've wasted a bunch of time trying to work out what's wrong all because my task was suspended. Never mind, at least I know what the problem is now. I add the `resume()` call and now I get:

```
Fatal error: 'try!' expression unexpectedly raised an error: Error Domain=NSURLErrorDomain Code=-1002 "(null)"
Current stack trace:
0    libswiftCore.so                    0x00007fecbfa6eb80 _swift_stdlib_reportFatalErrorInFile + 112
1    libswiftCore.so                    0x00007fecbf76043f <unavailable> + 1442879
2    libswiftCore.so                    0x00007fecbf760257 <unavailable> + 1442391
```

Hmm an `NSURLErrorDomain` problem. A `-1002` problem to be precise. This is my first rodeo in Swift-networking-land so I don't know what a `-1002` means off the top of my head. Eventually I find some info that points me to [this list of all the error codes](https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes). Hilariously it doesn't include the code in the list—just the name—so you have to open each case one-by-one until you find the one that matches your error code. The fourth from last one turned out to by my error: [`NSURLErrorUnsupportedURL`](https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes/nsurlerrorunsupportedurl).

Immediately I start thinking of all the possible ways that you could consider a URL unsupported, maybe the `ws://` scheme should be `wss://`? or maybe it won't handle hostnames and needs an IP address? Perhaps I've messed something up in my container[^of-course-container] and it's counting a closed port as an unsupported URL? (a bizarre thing to do, but at this stage all bets were off).

[^of-course-container]: Of course I'm running this in a container.

# Bargaining

So maybe `URLSessionWebSocketTask` is a [lost cause](https://xkcd.com/349/), but [SwiftNIO](https://github.com/apple/swift-nio) is always an option. I won't go into this too much, but basically I stumbled at the first hurdle when I followed [this post](https://www.swiftbysundell.com/articles/managing-dependencies-using-the-swift-package-manager/) to add SwiftNIO as a dependency. I don't really understand all the moving pieces here but basically:

```swift
dependencies: [
  .package(url: "https://github.com/apple/swift-nio", from: "2.58.0")),
],
.executableTarget(
  name: "WebSocketRPC",
  // bad, doesn't work
  dependencies: ["SwiftNIO"],
  // also no good
  dependencies: ["NIOWebSocket"],
  // perfect and excellent
  dependencies: [.product(name: "NIOWebSocket", package: "swift-nio")]
)
```

Why do I need a `.product` instead of just a string? No idea, and I couldn't find this mentioned anywhere in the SPM documentation. I happened to stumble across an NIO example project and looked at the `Package.swift` file to find this.[^eventually-docs]

[^eventually-docs]: While writing this I did end up finding that towards the bottom of the readme for SwiftNIO there is a ["Getting Started"](https://github.com/apple/swift-nio#getting-started) section that has the correct incantations. Only after you've read past the conceptual overview, repository organisation, and versioning scheme, however.

However after learning more about the SwiftNIO websocket implementation, it seems that I would need to handle _much_ more of the underlying protocol and HTTP-to-websocket upgrade than I had expected. The [example websocket client](https://github.com/apple/swift-nio/blob/7d9f892d8339148e9b00b0f4722afafbecfd14e5/Sources/NIOWebSocketClient/main.swift) has over 200 lines to do the same thing I was hoping to accomplish in two.

# Depression

Maybe websockets aren't that cool anyway, what if I just use plain old HTTP? Maybe this will help me understand whatever I'm doing wrong with the websocket API. While I'm at it, why don't I translate the callback-based API into an `async` one—that was the original purpose of this exercise in the first place, right?

```swift
func download(url: URL) async throws -> String {
  return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
      if let error = error {
        continuation.resume(throwing: error)
      } else if let data = data {
        continuation.resume(returning: String(data: data, encoding: .utf8)!)
      } else {
        fatalError("impossible?")
      }
    }
    task.resume()
  }
}

print(try! await download(url: URL(string: "{{ site.url }}")!))
```

And that just works first time? That's definitely weird. Was this an excuse to include some tidy callback-to-async code? Maybe.

# Acceptance

At this point my curiosity got the better of me—would it work on MacOS? Maybe I would get a better error and suddenly understand what was going wrong?

After a bit of an adventure with `xcrun` (it turns out you can't use the Swift compiler that's installed with the Xcode Command Line Tools), I installed Xcode and ran the exact code I had been trying on Linux for hours.

And it worked first time without any issues. The most frustrating result.

Eventually I found [this GitHub issue](https://github.com/apple/swift-corelibs-foundation/issues/4730) linked from a project's README:

> **fatalError when trying to send a message using URLSessionWebSocketTask**
>
> ...
>
> That code runs perfectly fine under macOS (using Swift 5.7), but as soon as it's run on Linux I get the error from above.

A few people chime in saying they see the same issue, and then [this comment](https://github.com/apple/swift-corelibs-foundation/issues/4730#issuecomment-1613801914) points to [this page of the `libcurl` documentation](https://everything.curl.dev/libcurl/ws/support):

> WebSocket is an **EXPERIMENTAL** feature present in libcurl 7.86.0 and later. Since it is experimental, you need to explicitly enable it in the build for it to be present and available.

So if your underlying library doesn't support websockets, it makes sense that a websocket URL is unsupported.

---

I don't have much of a conclusion here, apart from the fact that this was a very frustrating journey. I'm sad to see that almost eight years after being open-sourced and supporting Linux, Swift is still full of subtle traps that are hard to debug. Hopefully the [Swift Server Working Group](https://www.swift.org/sswg/) is aware of these issues and continues to make improvements—a simple [`@available` annotation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/attributes/#available) would have saved a lot of time.
