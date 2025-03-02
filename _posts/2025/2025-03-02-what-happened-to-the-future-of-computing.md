---
title: "What Happened to the Future of Computing?"
tags: opinion design
---

So back in 2015 all the attention of tech companies and tech enthusiasts was on the "future of computing", which came in the form of powerful tablets with keyboard cases. Thousands of words were penned and hundreds of hours of podcasts were spoken on what kinds of people could do their work on tablets, whether people _should_ do work on tablets, and what kind of tablet was the best for doing the work that one might do on a tablet.

I'm here to write a few more.

The general premise was that you could take a tablet, which is already really good for reading documents, reading webpages, watching video, and stuff like that, add a keyboard, add some multitasking support into the OS, and you've got a something that could be used single-handed for reading, sat on your lap with a keyboard for authoring a document, or attached to amount and an external keyboard for more ergonomic use.

Most of these tablets also supported a high-precision input from a pressure-sensitive stylus, which allowed for the undocked tablet to be used for annotating documents or in place of a dedicated art tablet.

Check out [MKBHD's end-of-year review of the tablets released in 2015](https://www.youtube.com/watch?v=h0BSqrfXBjM). If you weren't as deep into this as I was, it's a great little window into what was going on around this time.

This trend was in full swing by 2016, then over the next five slowly petered out until—by my estimate—stopping in 2021.

My interest in using a tablet for development work started when I read Mark O'Connor's post [_I swapped my MacBook for an iPad+Linode_](https://yieldthought.com/post/12239282034/swapped-my-macbook-for-an-ipad). I was intrigued about the idea of having a low-maintenance client device that could connect back to a more powerful server—especially because this would mean doing development work on Linux, which I still preferred over MacOS.

(This is basically where my [obsession with tmux](/tags/#tmux) and vim started, but that's another story)

While tablet OSes—especially iOS—improved significantly in 2014-2016, the most significant changes were released in 2017. [iOS 11 included](https://www.macstories.net/stories/ios-11-the-macstories-review/) the second version of split-screen multitasking, which made it much easier to select what went where, introduced the Files app, as well as system-wide drag-and-drop.

To understand why the Files app is significant, we need to talk about desktop operating systems. Please permit me to make some gross oversimplifications here. Don't take this too literally, I'm aware that there are exceptions and caveats to basically everything I've written.

Desktop OSes (operating systems that run on desktops, laptops, and servers) like MacOS, Windows, and most flavours of Linux have their design roots in a pre-internet age. They're designed with the assumption that there is a collaborative relationship between the user and their software—the software is able to do whatever it wants, because it will only do the things the user wants.

While desktop OSes allowed the user's software to do anything they wanted to their own files, there were at least safeguards that prevented users from accessing other users' files. You could categorise this as a collaborative relationship between the user and their software, and an adversarial relationship between the users of a computer.

As long as software isn't literally malware, what's the point in doing something like scanning every file on your hard drive? What's it going to do with that information? It can't send it anywhere, so unless it's going to be ransomware there doesn't seem to be much point.

If we move to a post-internet—especially post-smartphone—era, these relationships have changed. It's still adversarial between two users, but most mobile devices are now single-user anyway. The relationship between users and their software is now also adversarial. Widespread network access means that software can actually do something with all the information it has access to on the computer. Software could now scan your photos, contacts, or documents and report the information they found out about you to the software author.

Mobile operating systems, having grown up in this second age, have built-in features to guard against this type of behaviour—arming the user in their fight against their software. This prevents applications from reading anything but their own data, ensures shared data—photos, contacts, etc—can only be read if the user consents to the data being shared.

This model works really well for software that works in isolation—chat apps, web browsers, etc—but falls down when you need multiple pieces of software to work together or work on the same data.

If you're writing software, you have your code which needs to be accessed by your editor, your version control system, your language server, and your compiler. They _must_ all be looking at a consistent view of the same files at all times. The language server probably has to be able to launch the compiler to get semantic information about the code, and the editor has to be able to communicate with the language server to get the information about the code to show to the user. On a desktop OS this all works because any piece of software can access any file belonging to the current user.

In theory, a system where applications can advertise a storage system which can then be used by another application with the OS acting as a broker could work. The reality is that most applications did not invest in implementing this pattern, and those that did realised that the implementation in the OS was nowhere near the level of reliability needed from this kind of foundational system.

In 2019 I was [pushing into storage limitations using my iPad for photography](/2019/11/02/impracticalities-of-ios-photo-management-for-photographers/).[^not-ipad] In theory I could offload photos from the iPad onto an external storage device, but in reality this was impossible. There was no progress indication, and if your screen turned off the copy would cancel—with no way to resume, only start back from the beginning. The final insult was if you _did_ manage the copy the files across, viewing the contents of a directory with hundreds of images in it would never load—I assume because the system is attempting to create thumbnails for every image—so you can't even check if the copy worked successfully.

[^not-ipad]: Using the iPad to edit the photos, not take the photos. Obviously.

This forced me to delete work instead of archive it, and [eventually move to editing photos on a laptop](/2022/03/20/the-good-and-bad-of-photos-for-macos/), where if I run out of space I can just plug in an external drive with more storage.

A companion to the Files app was Shortcuts, the intersection of an automation system, visual programming language, and a new way for applications to communicate with one another. Initially Shortcuts ([originally Workflow](https://www.macstories.net/news/apple-acquires-workflow/)) was a visual programming environment with hard-coded integrations to a handful of services. You could integrate with web APIs and use [`x-callback-url`](http://x-callback-url.com) in certain apps to round the edges of certain interactions that were poorly supported by iOS.

Over the years Shortcuts' ingrained itself deeper into the OS, eventually allowing applications to advertise actions that could receive inputs and return an output. If you squint it's not hard to see how Shortcuts could be a modern incarnation of Unix command-line tools.[^in-theory]

[^in-theory]: Ignoring any caveats about what the "unix philosophy" actually means, and how effective it actually is.

I have written before about how [I don't think iOS should have a command line](/2018/06/21/ios-should-not-have-a-command-line/), and a system that replaces the command-line with modern sensibilities is what I was imagining.

However, applications were never permitted to run actions themselves, everything had to be written by the user and launched from the Shortcuts app. So unlike a command line, where one application can delegate work to another, a Shortcuts action cannot be used from inside a third-party application.

Take the software development example from before. In theory a compiler just needs to have one action that turns human-readable code into an executable. A code editor just has to run that action, giving the source files as input. This isn't possible, since the user has to write and trigger the shortcut themselves, and it can't be triggered inside a separate app. Instead, the compiler has to implement a full code editing environment themselves.

In the last year there has been [a common refrain of "just let the iPad run MacOS"](https://sixcolors.com/post/2024/05/the-ipad-pro-is-no-longer-the-future-so-whats-next/). This would obviously allow the tablet to gain a huge amount more capability,

This would basically be admitting that the mobile OS architecture is incompatible with the flexibility afforded from a desktop operating system. You can't have it both ways, you either have an OS that's restricted and secure-by-default, or you have one that's flexible and just trust that all your software will do the right thing.

Instead what I wanted to see was something of a magic trick. I absolutely love good API design, and what I was hoping for was to see someone pull the rabbit from a hat, demonstrating that it's possible to get the best of both worlds by defining new ways for systems to interact that balance security, privacy, and capability. Without forcing the user to pick only two.

A topic of conversation that is much more present now than it was 10 years ago is how much trust you want to place in the manufacturer of your computers. Backing up your iOS device means sending a copy of your data to a system that you don't control—and there's only one choice for where you backup to. Ensuring that no application can read my entire hard drive is a two-sided coin, it also means that if I want to give an application that ability, I'm out of luck.

The spotlight that was once shone on mobile OSes running on laptop-adjacent tablet hardware has since cooled off. This has left some significant improvements: It's much easier for me to do my homework for Spanish class on my iPad, and if need be I can read the textbook with half my screen and write notes on the other.

However you can't go far before running into a wall: I needed to upload an image to a website, and it couldn't be above a certain threshold. The iPad has no built-in UI to resize an image.[^shortcuts]

[^shortcuts]: You can do this with Shortcuts, but it is absurdly frustrating to have to write a one-off program to do a task like this.

Instead of tablets, my operating system interests now lie elsewhere. Containers offer many of the peace of mind benefits you get from a mobile OS, and I've been [using them heavily since 2023](/2023/06/08/overcoming-a-fear-of-containerisation/). It's not the revolution in API design I was imagining, but it's something.

Last year I wrote [_Scalability and Capability_](/2024/02/08/scalability-and-capability/), which touches on similar topics. Give it a read if this wasn't enough for you.
