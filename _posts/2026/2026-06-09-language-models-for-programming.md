---
title: "Language Models for Programming"
tags: languages
---

The other day I wrote about the [new tools that developers are using](/2026/06/03/from-vim-to-helix/) to get work done. Another topic I see discussed is different language models as part of the development process. I like to use and think about different programming languages. So I thought it would be interesting to go through some of the neat features in different languages that I've used, and how that changes your mental model of a program.

# Static vs Dynamic Typing and Compilation

I started programming in Java and then learnt Ruby a few years later. I was completely blown away by how easy it was to write code in Ruby when you didn't have to spell out all the types.

The thing worth remembering here is that you often think of dynamic typing as being intrinsically part of interpreted scripting languages (like Ruby, Python, or JavaScript) but that's just a convenient pairing. There's nothing stopping you having a compiled dynamically typed language, or an interpreted statically typed language.

Elixir is a compiled, dynamically typed language (although they've [just moved to being gradually typed](https://elixir-lang.org/blog/2026/06/03/elixir-v1-20-0-released/)), and [Roto](https://codeberg.org/NLnetLabs/roto) is a statically typed scripting language. Compilation is just a good time to check types, and if you're compiling code you can use the type information to generate more efficient instructions.

# Just-in-Time Compilation

It's easy to think of interpreted versus compiled as a simple binary, but like many things it's more of a continuous spectrum. Most of the mature scripting languages actually compile to bytecode before execution, instead of evaluating the code as they read it.

Java is a compiled language that gets compiled even harder while you're running it. The JVM will run bytecode similarly to how a scripting language would, but then it'll recompile hot sections into more efficient code as it's going.

# Null Safety

Since I started programming with Java and Ruby, it was quite a while before I came across null safety. For me it was just a fact of life that any value could be `null` or `nil` and you just had to accept that. I was blown away by the idea that the type system could track this, and integrate with the control flow of the program to ensure values were available in certain parts of the program:

```swift
if let value = self.maybeMissingValue {
  print("I've got a \(value)")
} else {
  print("I don't have any value")
}
```

This is definitely more common now, if you're doing mobile or web development you'll be using Kotlin,  Swift, or TypeScript, which all have null safety.

# Immutability

Similarly to null safety, I hadn't considered the fact that the language could stop you from being able to change values. In Java pretty much everything is mutable. You can define something as `final` but that doesn't stop you from calling a method that changes the internal state of the `final` object, it just stops you from reassigning it completely.

Swift and Rust both have strict mutability controls. If you declare a variable as immutable, you can't reassign it or call any method on it that changes its internal state. This means that you need to annotate methods with whether they will change the state of the object, or if they're simply read-only.

```rust
struct Person {
  name: String,
}

impl Person {
  fn rename(&mut self, new_name: String) {
	  self.name = new_name;
  }
}
```

In this code, if I don't have mutable access to a `Person`, I can't call the `rename` method:

```rust
let me = Person { name: "William" };
// compiler error since `me` is immutable
me.rename("Will");
```

# Immutable Data Structures

On a similar note, some languages make everything immutable. All the main data structures in Clojure are immutable, and instead of mutating them in-place, you make a copy with the alteration. This is made efficient by sharing the parts that haven't changed instead of blindly copying them, and it's safe to do that since you know no one will alter them.

Immutable data is inherently thread-safe since if no thread can mutate it, you can't have data races.

# Process Orientation

Elixir (and Erlang) work similarly to Clojure in that the data structures can't be altered. Instead, any kind of mutability is handled through message-passing between lightweight processes. A "mutation" is actually a process moving from one part of its execution into another.

The real benefit comes from the ability to swap out failing processes with new ones, knowing that there can't be interconnected data between processes since it's immutable.

I really like this model of having multiple components of a program all working together in parallel, but it's hard to make the same fault-tolerance guarantees in another language without the same memory model.

# Named Arguments

This is less of a live-changing feature, but convenient nonetheless. Many languages offer method overloading, where you can have multiple methods with the same name but different types or counts of arguments. It's great when you've got a single operation to do but multiple possible entry points.

This is less convenient when you've got overlapping types. This is often the case with drawing APIs, where there are lots of widths, heights, rotations, and coordinates. In that case it's really convenient to be able to provide the name of the argument at the call site, and have that checked by the compiler.

```crystal
# booo, unclear
draw_rect(12, 24, 50, 20)
# amazing
draw_rect(x: 12, y: 24, width: 50, height: 20)
```

This is also really convenient for APIs that have a lot of possible parameters, but only some of them need to be set.

Named arguments also means that the arguments can be listed in any order, since they're matched by name and not by position. Somehow Swift manages to get the worst of both worlds here, where all arguments are named by default, but they also must be supplied in the order they're listed in the function declaration.

# Union Types

This is another language feature that I didn't realise I was missing out on coming from Java. If I had something that could be one of two types, I just had two variables and made sure that I didn't set both at the same time. It's another case where you _can_ just do it yourself and try not to make any mistakes, but why do that when the compiler can check your working.

I use unions a lot in [pod](https://codeberg.org/willhbr/pod) since a lot of the time I'm tracking things that can be in one of a handful of states. Ensuring these states stay consistent is really useful.

```rust
enum FlagsDifference {
  NoChange,
  New(Vec<String>),
  Updated(Diff),
}
```

Like many features I find this easy to overuse and run into a wall where you've overfit on one model and have to refactor.

# Pattern Matching

Pattern matching goes along with union types as you'll want to do different things based on the type, and pull out the associated information:

```rust
match flags_difference {
  NoChange => println!("no change"),
  New(flags) => println!("new flags: {flags:?}"),
  Updated(updated) => println!("changed flags: {updated}"),
}
```

Like with [null safety](#null-safety), the compiler ensures that the data we have access to in each branch is the data appropriate for that branch. If you wanted to do a similar thing in Java you could use an enum and store the data as an `Object`, casting it to the type you know it to be. Or each case could be a separate subclass, which is much more verbose.

# Receiver Blocks

I'm not sure what the best name for this is in general. Kotlin calls them "receiver blocks" so I'll stick with that, but you can extend the idea a little more broadly. What they do is modify the normal lookup path for resolving variable, method, or class names. Most languages have a fairly predictable algorithm to map an identifier to a particular variable, method, or type. If it's not predictable, then the programmer is at risk of getting confused. It usually moves outwards from the smallest, closest scope, working its way until there is a match. If there's no match, then that's an error.

Receiver blocks just insert a new layer in that outwards search. Conceptually it's not that complicated, but it allows for some really neat tricks. The most common use case is creating declarative, type-safe builders:

```kotlin
html {
  body {
    p("This is type-safe!")
  }
}
```

`html` and `body` and just function calls, but the blocks that are passed to them are evaluated in a different context from the call site. For example, the `html` function could create an `HTMLBuilder` object and call the block inside the context of that class. The class provides the `body` method which would in turn create a `BodyBuilder` object that provides `p`. These methods are only in scope in the place that they can be added to the HTML document, so you're using the Kotlin compiler to enforce HTML correctness.

# Extension Methods

In a similar vein to receiver blocks, Ruby allows you to define a method that will be called if a method couldn't be found. You can then take that method call and apply it to another object, or mutate it and retry, or a whole host of other things. This lets you do naughty things like this:

```ruby
def method_missing(name, *args)
  puts "you tried to call #{name}!"
  self.send(name.to_s.reverse.to_sym, *args.reverse)
end
```

That's all very good for dynamic languages, but you can get similar behaviour in static ones as well. Swift allows you to define methods on existing types:

```swift
extension String {
  func frobulated() -> String {
    // frobulation implementation left to the reader
  }
}
```

This is a really convenient way to make types you don't own fit better into your codebase. In Swift it also allows you to make those types conform to protocols that they otherwise wouldn't, which saves having to wrap the type in another class that you own. Interestingly, while Kotlin supports extensions, they can't implement interfaces as they're just syntactic sugar for static methods.

# Object Lifetimes

I won't go on about this too much as [I've already done that](/2024/09/05/implicit-lifetimes-and-undroppable-types/) too much. I'm always baffled by the people who wish they had Rust without the borrow checker, because to me that's the whole point. Differentiating the place that has control over a particular piece of data and a place that's just temporarily using it is really powerful. Tracking the lifetime of objects makes reasoning about behaviour much simpler, as you don't have to guess whether something will be kept around for longer than you expect. This comes with the cost of having to tell the compiler about all this, which is a lot of extra work.

# Macros

Compilers are just fancy code generation machines, so why not let people add their own code generation in there too? I'm [a big fan of macros](/2026/01/31/crystal-dependency-injection/) since they combine my love of programming language features with my hatred of boilerplate.

There are different flavours of macros depending on what type of input they get. The weakest just get the literal text and have to process it themselves, others get the tokens but no structural information, and the most powerful get the actual syntax tree that represents how the program is understood by the compiler.

The macro can then take the input and translate it into a different form that would be annoying or cumbersome to type manually. This means you can define your own semantics and have code that breaks the established rules of the language, which makes macros an easy tool to misuse.

# But Why?

Hopefully this wasn't just a walkthrough of a few languages that I'm a fan of. I think it's useful to know about these sorts of things to keep your mind open to different ways of structuring programs and solving problems. It can even be useful to know about esoteric features so you know what you might need to emulate to get the same behaviour in a language that doesn't support them.

The original inspiration for this post came from the idea of "imitation language features": ways that you can hack around the lack of a certain feature in your language of choice. My classic example would be promises, which are a way to work around a lack of `async`/`await` by using callbacks. Although `async`/`await` is itself a hack around [a lack of effects in the type system](/2026/03/02/async-inject-and-effects/).

I thought that might end up a bit negative, so I've left it up to the reader to work out which languages are missing which features, and what effect that has on the code.
