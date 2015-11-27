---
title: Life with Swift
layout: post
date: 2015-11-09
---

Since Apple introduced Swift at WWDC last year, I've been interested in it as a compiled language that seems as easy and quick to develop as a dynamic scripting language like Python. Especially that Swift will (hopefully) be open sourced late this year, meaning that it could be used to develop applications that could be deployed easily onto a webserver as a simple binary (no [Capistrano](http://capistranorb.com) necessary).

Swift's basic syntax is incredibly clean and easy to get your head around. Keywords take second place to syntactic symbols - extending a class is done with a colon: `class Subclass: Superclass, Protocols {}` rather than the more verbose Java syntax `class Subclass extends Superclass implements Interfaces {}`. I like this both because of the reduced typing but also how the colon is reused to set the type in all instances where a type is needed.

    var str: String // variable initialisation
    func things(number: Int) // argument definition

This is not the case for return values though. It would make sense that like a variable, a function should have a type attached to it. This is not the case, instead a one-off symbol is used: `func getNumber() -> Int {}`. This would be nicer and more consistent if it used the same style: `func getNumber(): Int {}`.

Swift's optional types are very convenient and make code more explicit - being forced to unwrap values that could be nil makes writing code that deals with user input or stored values a whole lot cleaner. For example if you read a number from a text field and need to turn it into an int, `Int(myString)` returns an _optional_ int, it may or may not be nil. You can then unwrap it:

    if let number = Int(myString) {
        // Do something with the number
    }

This is really handy, and extends to almost all parts of the language and the Cocoa API. This can be further enhanced by using optional chaining - adding the `?` operator on to the optional value allows you to call methods on optional values as though they were definite values. The value returned by the last method is always an optional if you do this. For example if you have a dictionary of strings and you want to get one lowercased.

    let lowercased = myDict[key]?.lowercaseString

Where this falls down is if the key is an optional value as well - you can't index a dictionary with an optional value if the key **isn't** optional. What I would like to do would be to use the question mark to maybe unwrap the key, and if it isn't nil, then use the key to look up an item in the dictionary. Like this:

    let value = myDict[key?]

But you can't do that. The closest you can get is something like this:

    if let k = key, let value = myDict[k] {
        // value is a definite value that is in the dictionary
    } else {
        // either key is nil, or there is no value in the dictionary to match it
    }


What makes Swift that bit cooler than other languages that I've dabbled in is that it has the standard functional programming functions - `map`, `filter`, and `reduce` - which makes working with arrays a whole lot less cumbersome for anyone with a bit of [functional programming prowess](https://gist.github.com/JavaNut13/6e4d65328306b993ca6d). Paired with the powerful closure support, it's easy to express an operation in terms of a few closures. To turn a list of strings into a list of all the ones that can be turned into ints you can just map and filter them:

    let nums = myStringList.map({ str in
        Int(str)
    }).filter({ possibleInt in
        possibleInt != nil
    })

To sum these you can use the name-less closure syntax:

    nums.reduce(0, { $0 + $1 })
    
None of this would be possible without Swift's type system. When first looking at Swift I thought that it was simply statically typed like Java, except you didn't have to explicitly declare the type of variables - they would be set for you if the compiler could work it out. However Swift can behave somewhat like [Haskell's types](http://www.learnyouahaskell.com/types-and-typeclasses) to create functions that don't just work on on a string or a number, but any type that implements a certain protocol.

In Haskell you might come across something like:

    isSmaller :: (Ord a) => a -> a -> Bool
    isSmaller a b = a < b

Which uses the orderable (`Ord`) type class to declare a function that can be used on any type that supports ordering - strings, characters, numbers, etc. Swift has an expanse of built-in protocols that let you do similar things. For example, I wanted to be able to do set operations on lists while keeping the order of the elements, so I made an extension that would extend an array of elements that implemented the `Hashable` protocol - meaning that the contents of the array could be put into a set.

    extension Array where Element: Hashable {
      func unique() -> [Element] {
        var seen: [Element:Bool] = [:]
        return self.filter({ seen.updateValue(true, forKey: $0) == nil })
      }

      func subtract(takeAway: [Element]) -> [Element] {
        let set = Set(takeAway)
        return self.filter({ !set.contains($0) })
      }

      func intersect(with: [Element]) -> [Element] {
        let set = Set(with)
        return self.filter({ set.contains($0) })
      }
    }

These functions will be added to any array that contains elements that are hashable - if they aren't, then I simply can't use the functions. The more I get used to things like this, the more I like programming in Swift. It successfully combines the things I like in many different languages into one - it's compiled, quick to write, allows for functional programming as well as rigid object-oriented structures and the ability to extend the language itself seamlessly.