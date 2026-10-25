---
title: "What Can You Do for Your Compiler?"
tags: languages
---

> And so, my fellow programmers: ask not what your compiler can do for you—ask what you can do for your compiler.
>
> — [John F. Kennedy](https://en.wikipedia.org/wiki/Inauguration_of_John_F._Kennedy#Inaugural_address)

A friend and I were talking about the (somewhat) new [`consuming` and `borrowing` keywords in Swift](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md), which led to the question "what's the point, can't the compiler just work it out for me?" which I think is worth some interrogation.

When I used to teach programming at university, one of the common pieces of confusion stemmed from strong typing. For someone who is new to programming, `"5"` (string) and `5` (integer) are not meaningfully different. Why can't I do `"5" + 5` and have the computer work it out?

In some languages, the computer does work it out. We call that weak typing. If you ask to add two things together, the computer will first try and turn both into numbers, and use the result for the addition. You'll probably be most familiar with this from JavaScript—more so with subtraction than addition—where `4 - "5"` evaluates to `-1`, exactly how a beginner would expect.

However, these rules are hard to internalise, especially because `+` can mean both addition and concatenation. `4 - "5"` is `-1` but `4 + "5"` is `"45"`. `1 - 4 + "5"` is `"-35"`. This isn't an insurmountable problem, but it will definitely surprise you if you're not careful. There [is even weaker typing in PHP][eev], where strings that contain numbers will be converted to numbers first and then compared numerically.

[eev]: https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/#operators

An honourable weak typing mention is the iOS Shortcuts app, where the weak typing doesn't just happen in the realm of simple data types, but complex objects. Depending on how you read it, a network request can either be a string of characters, a dictionary of values (probably by parsing it as JSON), or a rich text document. It means that your program will keep running further, but the result might be something completely different to what you expected.

This is why most dynamic programming languages are strongly typed. A value can be any type, but it usually won't change type depending on how you use it. Python is a good example of this. If you want to turn a string into a number, you need to explicitly convert it with `int()` or `float()`. If you don't do this, your program will raise an exception and stop.

So the next logical question is, why can't the compiler just tell me if I'm doing an operation that's not allowed before I run the program?

Which is how you get to static typing. In a dynamic language, it's impossible to know exactly what type each value will be in order to validate whether the operations done on them are allowed. In order to do that validation, you need to give more information to the compiler, in the form of type annotations.

In a language like Java, you're not going to get a `NoMethodError` when you run your program,[^reflection] because the compiler checks that everything exists beforehand. The cost of this is that you need to tell the compiler the structure of everything ahead of time.

[^reflection]: Well unless you're doing something interesting with reflection, or dynamic class loading, etc.

Crystal's type system is a great example of "let the compiler figure it out". Most of the time you can get away with not writing type annotations, but any experienced Crystal programmer knows that it is easiest to throw some annotations in the places where you know the type of something, so that the compiler is able to provide you with a better error message.

Let's change course from typing and talk about memory management.

As a beginner learning C, you probably have the thought "why can't the computer just work out where the `free()` calls need to go?". Which it can, with a garbage collector—but only if you tell it the structure of your data. The C compiler basically knows nothing, and so it couldn't collect your garbage even if it wanted to. The Java compiler (and runtime/virtual machine) know everything, and so they can—and will—collect your garbage.

However, the garbage collector is limited by the information that you give it, and so it's still possible to get memory leaks (memory that "should" be freed, but isn't) in languages with a garbage collector. This happens when your program references something that it no longer needs. It may never access this data, but the computer doesn't know that; all it knows is that it has to keep a hold of everything that is still referenced.

This is more pronounced in languages with reference counting instead of a garbage collector. Reference counting doesn't keep track of the relationships between objects, but instead how many objects hold a reference to each object. It's the difference between knowing who everyone's friends are, and knowing how many friends everyone has. When the reference count hits zero, the object can be freed. If two objects both reference one another, the count for both will never reach zero, and so they can never be freed. The computer is doing everything it can with the information available to it, it's not able to find out whether these two objects can be accessed, and so they have to be kept around forever.

Reference-counted languages—like Swift—have features to communicate more detail about the inter-object relationships to the compiler. You can mark a relationship as `weak` so you don't increment the reference count. The compiler and runtime still can't save you if you forget this annotation.

To avoid the pitfalls of garbage collection or reference counting, you can add explicit ownership information into the language, so the compiler can verify that there aren't leaks before the program runs. However, just like the move from dynamically-typed languages to static typing, you have to model these relationships in a way that the compiler understands. You've basically going from dynamic lifetimes to static lifetimes.

Rust is the classic example of this, where data ownership and borrowing are core to how the language works. Although there's nothing stopping you from correctly annotating that you want to retain a whole bunch of information in memory that will continue to grow unbounded, the difference is just that you have to write that down.

So this brings us back to Swift's `consuming` and `borrowing`—can the compiler just work it out?

We could leave it up to the compiler, but since the compiler is just doing what we tell it to do, we could inadvertently make a change in one part of our program that forced a function to stop being `borrowing`. Just like how in dynamically typed languages, a change in one part of the codebase can change the structure of data to be incompatible with another part.

What `consuming` and `borrowing` do is let us tell the compiler our intention for particular variables. If something is `consuming` then it can't be used again later. If something is `borrowing` then we have to give it back when we're finished.

At the end of the day, the computer can only do what you tell it, so having a bigger vocabulary to talk to it is probably useful.
