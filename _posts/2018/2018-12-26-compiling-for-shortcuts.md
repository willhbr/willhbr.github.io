---
title: "Compiling for Shortcuts"
---

In [this video](https://youtu.be/Xe-8Vp0e9qE) I show a program written in [Cub](https://github.com/louisdh/cub) being compiled and run inside of the iOS Shortcuts app. The program is a simple recursive factorial function, and I can use it to calculate the factorial of 5 to be 120. Super useful stuff.

The idea was first floated by [Andrew](https://ruby.social/@acb@mastodon.world) - who knows that I am someone that is easily nerd-sniped by programming language problems. Even after I pointed out that Shortcuts doesn't support functions (or any kind of _jump_ command other than conditionals) and a whole host of other features that you'd expect in the most basic set of machine instructions. But the bar had been set.

Initially I started writing a parser for a whole new language, but quickly discarded that idea because writing parsers takes time and patience. Why not just steal someone else's work? I'd seen [Louis D'hauwe](https://nerdculture.de/@louisdhauwe) tinkering on Cub, a programming language that he wrote for use in [OpenTerm](https://github.com/louisdh/openterm) - which is written entirely in Swift. After a quick look into the [code](https://github.com/louisdh/cub) I realised that it would be simple to just use the lexer and parser from Cub and ignore the actual runtime, just leaving me to do the code generation. All I have to do was traverse the syntax tree and generate a Shortcuts file. In terms of code this is fairly straightforward - just add an extension to each AST node that generates the corresponding code.

Over a few evenings I pulled together the basic functionality - after reverse-engineering the Shortcuts plist format by making a lot of shortcuts and airdropping them to my Mac (Josh Farrant ended up doing a similar thing for [Shortcuts.fun](https://shortcuts.fun), and he's [written about the internals a bit on Medium](https://medium.com/shortcutsjs/creating-ios-12-shortcuts-with-javascript-and-shortcuts-js-942420ca9904)).

The main problem was how to invent functions in an environment that has no concept of them. Andrew suggested making each function a separate shortcut - and just having a consistent naming convention that includes the function name somewhere - which would work but would make installing them a complete pain. However if you assume you know the name of the current shortcut, you can put every function in one shortcut and just have it call itself with an argument that tells it which function to run. An incredibly hacky and slow solution (as you can see in [the video](https://youtu.be/Xe-8Vp0e9qE)) but it works - even for functions with multiple arguments!

A lot of debugging and crashing Shortcuts later, I had a working compiler that could do mathematical operations, conditionals, loops, and function calls - all being turned into drag-and-droppable blocks in the Shortcuts app. Like using CAD to design your [Duplo](https://en.m.wikipedia.org/wiki/Lego_Duplo) house.

The main shortcoming with this hack is that every action has a non-obvious (and non-documented) identifier and argument scheme that you have to reverse engineer for every action. If this was going to be a general-purpose solution, you'd have to deconstruct all the options for every action and map this to an equivalent API in Cub.

If you're intrigued you can run the compiler yourself (be warned; it is janky). All you need is Swift 4.2 and the code [from GitHub](https://github.com/willhbr/cub-shortcuts).
