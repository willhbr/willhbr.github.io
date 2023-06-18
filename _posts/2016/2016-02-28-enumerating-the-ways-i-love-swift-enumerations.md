---
title: Enumerating The Ways I Love Swift Enumerations
tags: development
---

_[Enumerating The Ways I Love Swift Enumerations &rarr;](https://www.caseyliss.com/2016/2/27/swift-enums)_

As Casey illustrates, enums in Swift really are quite awesome and really powerful once you get used to them.

When I was working on [WORM](https://github.com/willhbr/WORM) I kept wanting to make things enums. Every time I did try I wanted to attach values to each of the options. For example I created an `@Stored` annotation, which you could either tell it to work out the type for you, or to have a custom type string when it created the table. In Swift I could have done:

```swift
enum ColumnType {
  case Infer
  case Custom(type: String)
}
```

What is interesting is that I thought of the Swift solution before coming up with a Java version - my 'native' language.
