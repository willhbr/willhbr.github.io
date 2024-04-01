---
title: "iOS Should Not Have a Command Line"
tags: opinion
---

On the [latest episode of Upgrade](https://www.relay.fm/upgrade/198) [^upgrade-is-great] Jason and Myke briefly discuss the idea of Apple adding a command line to iOS. They quickly dismiss it because of the constraints of sandboxing and security - instead suggesting that the command line will be a feature that keeps people at the Mac. I find the idea of a new command line really interesting, so I wanted to expand on some more reasons why there shouldn't be a command line on iOS - unless it comes with massive changes to how you think about a command line.

[^upgrade-is-great]: A great show, definitely listen to it if you're into this kind of thing.

I think I know customising and using the terminal fairly well; [I'm 160 commits into customising how I use it](https://github.com/willhbr/dotfiles) - whenever I'm at a computer (whether that's my Mac or my iPad) I have a terminal open.

The advantage of a command line is not the fact that it is textual. Being able to enter `rm *` is not much faster than selecting everything and hitting cmd-delete in the Finder. The real advantage is that everything uses the exact same set of easily understandable interface concepts, and they can all interact with each other.

All command-line programs have an input stream, an output stream, and an error stream. These can be displayed anywhere, hidden, parsed, redirected, or reinterpreted trivially. The concepts in the command line are the core concepts of the operating system, and everything respects these concepts. They are building blocks that you can put together to do your work.

In macOS, the building blocks are windows [^also-tabs] - everything you interact with is contained in a window, and you can interact and manipulate these in a consistent and predictable way. iOS has a less predictable model - apps are the only unit that a user can interact with, which in some situations - particularly dealing with documents - is too coarse and gets in the way.

[^also-tabs]: Also tabs, I suppose.

The other advantage of a the command line is that interacting with it (at least at the basic level, before you get into ncurses) is trivial, so tools like compilers or video encoders like ffmpeg don't have to implement a full interface - they concentrate on their own specific functionality.

Previously on iOS if you wanted to implement something like a compiler, you'd have to implement the whole IDE or editor as well as the actual compiler - which is a lot of extra work. People are also quite picky about their editors [citation needed]. iOS 11 improved this significantly with the Files app - your compiler could just read the source files from a file provider that were written with someones editor of choice.

For example, [Cub](https://github.com/louisdh/cub) can only really be used in [OpenTerm](https://github.com/louisdh/openterm) - and there's no way to add another language to it. OpenTerm is also limited in that it can't accept commands from other apps - the commands must be baked in, entirely hard-coded.

It would be possible to create a sandboxed shell - that ensures that commands can only see the files that they are entitled to access. You would most likely have to throw out almost all existing scripts from macOS, and the semantics of the shell language would change - popular shells (zsh, BASH, Fish, etc) don't have strong types so you don't know if the parameters passed are files or if they just look like that. Maybe they're just parts of a web URL? (but does this command have permission to access that URL?) Sandboxing an existing shell would either end up limited, or frustrating and unproductive to use.

This all ignores the fact that iOS apps are not built to be used from the command line - they don't expect command line arguments, they don't print a result - they can't share anything about themselves in the way that a command line expects. Even macOS apps don't really do this.

For me to support a command line on iOS, I would have to see significant changes to how the core of the operating system behaves. The command line needs to be able to tell apps to do things on behalf of the user - when it is allowed - and receive results back from those apps.

iOS can already do this: [Workflow](https://workflow.is/) (aka Shortcuts) can chain actions from different apps together. Siri shortcuts allows apps to expose actions that can be consumed by the system, and used as part of a workflow. They don't allow for passing input or output (as far as I know), which doesn't make them as versatile as command line programs.

The other aspect of the terminal that is often overlooked is the features that sit outside of the fairly simple concept of a process with input and output streams - [VT100](https://en.m.wikipedia.org/wiki/VT100) emulation and the use of [ANSI escape codes](https://en.m.wikipedia.org/wiki/ANSI_escape_code). These allow any process to control the interface far more than just writing a sequence of characters onto the screen. My terminal would not be complete without [tmux](https://github.com/tmux/tmux/wiki). It allows me to easily manage applications in a uniform environment, without having to reach for features higher up the "stack" like windows which are not as well suited to managing command line applications.

There is however - as is tradition when talking about iOS releases - always next year. Shortcuts could gain the ability to accept input from other apps and pass their output to other shortcuts. iOS could get UI improvements that make it easier to juggle parts of applications like I can with tmux.

What I don't want to see is a literal port of the command line to iOS, because that would be a significant step back in imagining a new way of handling inter-app communication and would most likely be so constrained that it wouldn't be able to fill the use cases of todays terminals. A bad terminal on iOS would only serve to further the argument that doing work on iOS is a dead end.

But hey, I'm just some guy that uses tools that are decades older than him.
