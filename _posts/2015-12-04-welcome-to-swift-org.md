---
title: Welcome to Swift.org
layout: post
date: 2015-11-28
link: http://swift.org/
---

> Swift is now open source!

Finally I can start having a more serious look at making something with [Taylor](https://github.com/izqui/Taylor) and deploying it onto something other than my laptop. At work this morning I downloaded the Swift binary and fired up the REPL. Fully functioning Swift on Ubuntu. [The future is now.](/2015/11/28/life-with-swift/)

Perhaps more interesting than the actual [Swift repository](https://github.com/apple/swift) is the [Swift Evolution](https://github.com/apple/swift-evolution) page that publicly shows the features and direction that both Apple and Swift community want the language to head in. It makes me very excited to see speed, portibility and API design among the goals for version 3 and beyond. This could mean more consistent APIs and a global `Foundation` library that wraps the native functions for each system (at the moment pre-processor commands are needed to use platform-specific libraries) which is not very Swift-y.

The [first commit](https://github.com/apple/swift/commit/18844bc65229786b96b89a9fc7739c0fc897905e) to the Swift project is dated July 18, 2010. It's crazy to think that this was kept completely secret for four years before it was unveiled. Also pointed out in the comments is that Swift was named Swift since its inception.

Along with the [dump of projects](https://github.com/apple) released this morning is the [Swift Package Manager](https://github.com/apple/swift-package-manager). I am probably far too excited about this that it is normal to be for a tool that I haven't really looked at yet. However because of the pain that [CocoaPods](https://cocoapods.org) has caused me while trying to write unit tests that access a database, I'm happy to see a first party solution - and will be updating [my version of SQLite.swift](https://github.com/JavaNut13/SQLite.swift) as soon as I can.