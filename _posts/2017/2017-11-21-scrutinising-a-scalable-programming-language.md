---
title: Scrutinising a Scalable Programming Language
---

In my opinion, most developers should know three different programming languages, three different tools that can be used for most of the projects you come across. These should include a scripting language - for automating a task or doing something quickly; an application language - for writing user-facing or client applications, which have to be run on systems that you don't control; and an "infrastructure" language for building a system that has many components and runs on your own platform.

> I don't really do any systems programming - which I see as basically being dominated by C anyway - so I would lump it in with your application language, as the situation is very similar. If this is not the case then the target hardware and tooling probably dictates using C anyway.

A scripting language is usually dynamically typed and interpreted. It starts up fast and lets you cut as many corners as needed until the problem is solved. It should be good at dealing with files, text, and simple HTTP requests. For this I will usually use Ruby, as it is very quick to write and has useful shortcuts for common things scripts do - like running shell commands. On occasion I will use Python, but I can't think of any reason that I would use it over Ruby - except for Ruby not being installed.

The application language I use most often is Java (or Kotlin, more recently). This is partly due to having to use it for university, but also if you want to write something that can be run on pretty much anyones computer with minimal effort, the JVM is probably your best bet. It has its problems, of course - but it's easier to get someone to install a JRE and run a fat JAR than it would be to ensure they're running the correct version of Python and the dependencies are installed.

The "infrastructure" language is probably closest to what I find most interesting - I first thought of this after finishing the hackathon that resulted in [Herbert](https://github.com/euston-fish/herbert). Herbert is a Slackbot that does some timesheeting. It includes the proper Slack app integration hooks and stuff, so it needs to be able to join many different teams at once, and dynamically join teams as they add the integration. It's written entirely in Ruby, because it was easy to get a working prototype (see above) - but because Ruby doesn't have real threads, running a load of things at the same time is a bit orthogonal to it's strengths. In [subsequent hackathons](https://github.com/euston-fish/liberdata), Logan and I chose to use [Elixir](https://elixir-lang.org), which is better suited to piecing a selection of bits together and having them communicate (thanks, BEAM!) so it would probably be my choice here.

---

I expect that most people - like me - would choose three fairly different languages. What if we had a language that could be used easily for all of these situations? What would it take, and what (in my opinion) is stopping existing languages from being used everywhere?

> Most of these languages can be used in all situations, but there are some things that get in the way of them being a great choice. If you are an expert in one particular language then the familiarity will likely win out over the suitability of another.

# Go

Go excels at building highly concurrent and performant applications. What makes it even more useful is the ability to easily cross compile to pretty much every major platform. Not having exceptions makes it easy to cut corners in error handling - which makes building an initial prototype or experiment easier. For me the verbose syntax and lack of (seemingly simple) language features pushes me away from Go - but I'll happily reap the benefits of others using it by making use of [their applications](https://gitea.io).

The other aspect of Go that I find frustrating is the enforced package structure and (lack of) dependency management. There is a fair bit of work from just using `go run` on a single file to setting up a proper Go environment - especially if you have an existing way of organising your projects.

# Java/ Other JVM Languages

The main pitfall of using the JVM for quick tasks is that it usually takes longer for the JVM to start than it does for your program to run. In the time that it takes to start a Clojure REPL, I can typically open a few other terminals and launch a Ruby, Python, and Elixir REPL.

Plain Java also lacks a build system - who in their right mind would use `javac` to compile multiple files? No simple script should start by writing a `pom.xml` file. Kotlin is a lot closer to being used for scripting, but still has the problem of slow JVM startup.

# Python & Ruby

Both are great scripting languages, and often get paired with native extensions that increase performance without you having to step down to a lower-level language yourself. However I find that the native extensions or systems that manage the running of your code (Passenger, etc) hard to understand and deploy. I like the idea of being able to run the application completely in production mode locally, which is often not really the case for these types of systems. For example, Rails is usually run in production through a Rack-based server that lets your application handle concurrent requests easily, however in development it just uses a simple single-threaded server.

This makes deployment more difficult, and Pythons versioning fiasco doesn't help. I once wrote a simple script to run on my Raspberry Pi, and because I couldn't get the correct version of Pip installed to load the dependencies onto the Pi I just reimplemented the same script in Go and cross-compiled it.

# JavaScript & Node

I don't have a lot of experience with JavaScript, but it is one of the few languages that is probably being used in almost every scenario. Quick scripts using Node, applications either in Electron or even just as a web page, and potentially back to Node for your infrastructure. However the ecosystem and build tools are not really to my liking (to say the least), so I will rarely use Node for anything unless I really have to.

# Swift

Swift has the potential to be a great option for solving all kinds of problems, but the focus on iOS and macOS development hinders it in the areas that I am interested in - backend development on Linux. This fragments libraries and frameworks, some depend on being built by XCode and use Foundation or Cocoa, others use the Swift Package Manager and use third-party implementations of what you would expect from a standard library. For example, I don't know how to open a file in Swift. I know how to do it using Foundation, but not on Linux - or maybe that's changed in the latest version?

String handling makes Swift awkward to use for scripting - indexing can only be done using a `Index` rather than an `Int`. This makes sense - indexing a UTF-8 string is an O(n) operation as characters can be pretty much any number of bytes. It does mean that you end up with a spaghetti of `string.startIndex` and `string.index(after: idx)`.

# Elixir

I find [Elixir](https://elixir-lang.org) great for making systems with many different components - which isn't a surprise given the concurrent focus of Erlang and the BEAM VM. The tooling for Elixir is also great, which makes it a pleasure to develop with. Creating a new project, pulling in some dependencies, building a system, and deploying it is well supported for a new language.

The tooling is necessary - working with multiple files isn't really possible outside of a Mix (the Elixir build system) project, as Mix makes a load of bits and bobs that allows BEAM to put all the code together.

I would never imagine building something designed to run on a computer that's not my own with Elixir - having someone install Erlang or bundling all of it into a platform-specific binary seems a bit flaky. Also the type of code you write for a client-side application usually isn't suited for Elixir.

# Crystal

[Crystal](https://crystal-lang.org) is an interesting new language - it's still in alpha. What makes it interesting is it has global type inference; instead of just inferring the type for variable assignments based on the return type of functions, it takes into account the usage of every function to determine what types the arguments and result are.

What this means is that Crystal code can be written almost like a dynamically typed programming language, but any type errors will get caught at compile time - basically eliminating typos (ha! type-os!). Obviously this makes Crystal a great language for quick development.

Static typing should make Crystal quite well suited to building larger systems. Of course this is dependent on how it continues to evolve and its ecosystem continues expanding and maturing.

---

So what would make an ideal scalable language? Something that can be used in any scenario, to build any kind of application. This is a stretch - especially if you want it to be any good at any of one of the problems. For me this basically boils down to readable, concise syntax that allows me to write code that fits in with the standard library; often this includes some solid compile-time checks, catching problems before the code is run, but without adding too much extra overhead to writing the code.

The tools in the language need to make it easy to go from a single script, to a few files, to a full on project with dependencies, tests, etc. Of course as soon as dependencies are involved you need a good ecosystem of libraries and frameworks ready to be used on all the platforms you need them on.

On balance the language should probably compile to native code, but what would be neat is the option to run in a lightweight VM that can be bundled into a native binary so that the application can be more easily deployed without installing a runtime environment. Developing Elixir is very easy because you can recompile and interact with the application from the REPL (this is obviously not new to LISP developers - I have only used Clojure and find that IEx in Elixir is far easier to use than the Leiningen REPL).

Due to my habit of jumping between languages I don't imagine I will settle on one that I would use for everything any time soon. Although I always keep an eye on Swift to see how that's progressing - just next year is going to be the year of Desktop Linux, next year will be the year of Server-side Swift. Always next year.
