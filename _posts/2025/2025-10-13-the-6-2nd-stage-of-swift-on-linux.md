---
title: "The 6.2nd Stage of Swift on Linux"
tags: languages debugging
---

Back in 2023 I wrote [_The Five Stages of Swift on Linux_][swift-linux] where I went through all the stages of grief while trying to get a working websocket connection on Swift on Linux. What I ended up finding out was that the Swift websocket implementation on Linux relied on websockets in `libcurl`, which [at the time were experimental][libcurl-experimental] and so weren't available.

[libcurl-experimental]: https://github.com/apple/swift-corelibs-foundation/issues/4730#issuecomment-1613801914
[swift-linux]: /2023/08/23/the-five-stages-of-swift-on-linux/

Well here we are over two years later and on the Swift blog there's a [post titled _The Growth of the Swift Server Ecosystem_](https://www.swift.org/blog/swift-on-the-server-ecosystem/). So I guess I should see if we have websockets yet.

I grab a container, write a quick test server in Crystal,[^crystal-websocket] and grab the code from my original post:

[^crystal-websocket]: Networking in Crystal is so easy for me to write and incredibly reliable.

```swift
import Foundation
import FoundationNetworking

let task = URLSession.shared.webSocketTask(
  with: URL(string: "ws://host.containers.internal:9080")!)
task.resume()
try! await task.send(.string("test message"))
```

I'm running this on the latest Docker image (`swift:latest`) which is based on Ubuntu 24.04.3 (that'll be important later) and here's what I get:

```console
swift_test/swift_test.swift:26: Fatal error: 'try!' expression unexpectedly raised an error:
  Error Domain=NSURLErrorDomain Code=-1002
  "(null)"UserInfo={
    NSLocalizedDescription=WebSockets not supported by libcurl,
    NSErrorFailingURLStringKey=ws://host.containers.internal:9080,
    NSErrorFailingURLKey=ws://host.containers.internal:9080}

💣 Program crashed: Illegal instruction at 0x0000791e0e6e26b8

Platform: x86_64 Linux (Ubuntu 24.04.3 LTS)

Thread 1 crashed:

  0 0x0000791e0e6e26b8 _assertionFailure(_:_:file:line:flags:) + 264 in libswiftCore.so
  1 0x0000791e0e716d76 swift_unexpectedError + 805 in libswiftCore.so
  2 async_MainTY2_ + 74 in swift-test at /src/Sources/swift-test/swift_test.swift:26:6

    24│ task.resume()
    25│ print("created task...")
    26│ try! await task.send(.string("test message"))
      │      ▲
    27│ print("sent message")
    28│
```

Compared to last time, this is a _huge_ improvement. Not only have I got an error message instead of just an error code, it actually explains why the connection failed with a pointer to the cause—the `libcurl` version.

So the latest Swift release doesn't support websockets out of the box on Linux just yet—but can we get it working?

The version of `libcurl` on Ubuntu 24.04.3 is 8.5, and we need [at least 8.11 to get websocket support][curl-8-11]. Updating the package through `apt` doesn't work (the latest you'll get is 8.5) so instead I created a new container with an Ubuntu 25.04 image, then ran `apt update && apt install curl`, which got me 8.12.1. I then had to go through the full [Swift install process][swift-install], only then could I run my websocket, and it worked perfectly.

[curl-8-11]: https://curl.se/ch/8.11.0.html
[swift-install]: https://www.swift.org/install/linux/

Or I assume it did, I'd actually forgotten to put any logging in the Crystal websocket server, so it wouldn't actually print anything when a client connected. So I didn't know whether the Swift client had actually worked. I updated the server and re-ran the client and it worked that time.

My understanding is that Swift dynamically links its runtime and runtime dependencies, so I don't just need a specific `libcurl` version to build my program, that needs to be available wherever this code is running. This just seems like a real pain, I'm a big fan of just statically linking everything into one binary so this isn't a concern at all.

Thankfully [Swift 6 supports static linking][static-swift]. The install process isn't super clear, the example in that post is now outdated, so you need to go to the [install page][swift-install] and find the "Static Linux" download in the "Swift SDK Bundles" section. That gives you a `swift sdk install` command that will do the download for you. For 6.2 that's:

[static-swift]: https://www.swift.org/documentation/articles/static-linux-getting-started.html

```console
$ swift sdk install https://download.swift.org/swift-6.2-release/static-sdk/swift-6.2-RELEASE/swift-6.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz \
  --checksum d2225840e592389ca517bbf71652f7003dbf45ac35d1e57d98b9250368769378
```

You can then compile a static binary with:

```console
swift build --swift-sdk x86_64-swift-linux-musl
```

Which we can then take to any `amd64` Linux machine and run:

```console
$ ./swift-test
running...
created task...
swift_test/swift_test.swift:26: Fatal error: 'try!' expression unexpectedly raised an error:
  Error Domain=NSURLErrorDomain Code=-1002
  "(null)"UserInfo={
    NSErrorFailingURLStringKey=ws://host.containers.internal:9080,
    NSLocalizedDescription=WebSockets not supported by libcurl,
    NSErrorFailingURLKey=ws://host.containers.internal:9080}
Current stack trace:
0    <unknown>                          0x0000000000a5e56c
1    <unknown>                          0x0000000000b08631
2    <unknown>                          0x000000000070a4ba
3    <unknown>                          0x00000000008bfa73
4    <unknown>                          0x00000000008f4b62
5    <unknown>                          0x00000000006c9acb
6    <unknown>                          0x0000000000b51633
7    <unknown>                          0x0000000000b527ce
8    <unknown>                          0x0000000000b6afba
9    <unknown>                          0x0000000000b6b7d8
10   <unknown>                          0x0000000000b70666
Illegal instruction (core dumped)
```

Wait no that's not what it's supposed to do.

I guess we statically linked in the wrong `libcurl` version? How can we tell?

That [static Swift post][static-swift] has a command output at the bottom that shows a bunch of library versions—including `curl`. It's for Swift 6.1 though, so it's outdated. We'll need to run the same thing ourselves on the 6.2 SDK.

They don't link to the tool, and `bom` is generic enough that it's hard to be sure what they're talking about, but it's the [Kubernetes `bom` tool](https://github.com/kubernetes-sigs/bom), which to install you first need to install [`go`][golang], set `$GOPATH`, and then finally you get a `bom` binary.[^assume-static]

[golang]: https://go.dev/doc/install
[^assume-static]: Which I assume is statically linked.

```console
$ bom document outline ~/.swift-sdks/swift-6.2-RELEASE_static-linux-0.0.1.artifactbundle/sbom.spdx.json
               _
 ___ _ __   __| |_  __
/ __| '_ \ / _` \ \/ /
\__ \ |_) | (_| |>  <
|___/ .__/ \__,_/_/\_\
    |_|

 📂 SPDX Document SBOM-SPDX-f4e4b6d7-adb7-4694-a4b3-75b5c1eadeca
  │
  │ 📦 DESCRIBES 1 Packages
  │
  ├ Swift statically linked SDK for Linux@0.0.1
  │  │ 🔗 7 Relationships
  │  ├ GENERATED_FROM PACKAGE swift@6.2-RELEASE
  │  ├ GENERATED_FROM PACKAGE musl@1.2.5
  │  ├ GENERATED_FROM PACKAGE musl-fts@1.2.7
  │  ├ GENERATED_FROM PACKAGE libxml2@2.12.7
  │  ├ GENERATED_FROM PACKAGE curl@8.7.1
  │  ├ GENERATED_FROM PACKAGE boringssl@fips-20220613
  │  └ GENERATED_FROM PACKAGE zlib@1.3.1
  │
  └ 📄 DESCRIBES 0 Files
```

So the Swift 6.2 SDK ships with `curl@8.7.1`, so no websocket support yet.

I suppose that maybe you could build your own SDK to include a more recent version version of `libcurl`, but at that point you're already an edge case (statically compiled Swift) of an edge case (Swift on Linux); so you might as well just [rewrite it in Rust][rewrite-in-rust].

[rewrite-in-rust]: /2025/07/25/rewriting-pod-with-wisdom/
