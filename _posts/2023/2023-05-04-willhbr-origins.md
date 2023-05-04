---
title: "@willhbr: Origins"
date: 2023-05-04
layout: post
image: /images/2023/arctic-lego.jpeg
---

At some point my memory will fail me and I won't be able to recall some of these details. So I've written it down for future-me to enjoy, and while it's here you might as well read it.

# Zero: Computers

My first interaction with a computer was after showing my dad my cool Lego minifig with a little chainsaw[^chainsaw] from my "Arctic Explorers" set:

[^chainsaw]: Actually in terms of Lego scale, it was about half this guy's height so not really a little chainsaw.

![The LEGO arctic explorers set with lots of cool lego action happening](/images/2023/arctic-lego.jpeg)

My dad then showed me ["stress.exe"](https://archive.org/details/The_Stress_Game_201711) where you could use a variety of tools (including a chainsaw) to destroy whatever was displaying on the computer. 6-year-old me found this amazing.

The family computer we had was a classic beige monster probably running Windows 98, with those cool little speakers that would clip onto the sides of the huge CRT display.

# One: Programming

Fast forward a few years and I was playing around with stop motion animation, and the [MonkeyJam](http://monkeyjam.org) splash-screen mentioned that it was written in [Delphi](https://en.wikipedia.org/wiki/Delphi_(software)). My dad made some comment about how I could probably write something in Delphi—not knowing about what programming involved, this sounded quite daunting.

My memory is a bit hazy on the next bit, I think it may have been hard to get a Delphi license or something (free and open source tooling is the only way to go!) so I ended up tinkering around in Visual Basic for a while.

I don't remember doing any "programming" in VB—instead I just used the UI editor to drag buttons in and then make them show other screens when you clicked them. I definitely made some mazes where all the walls were buttons and you had to carefully manoeuvre the cursor through the gaps.

Eventually the rate of questions that I was asking my dad hit a critical threshold and I suggested that if he just helped me get started with Java, I could learn it all from a book and wouldn't have to ask him anything. This was of course, not true.

Nevertheless I got a copy of [Java 2: A beginners Guide](https://www.amazon.com/Java-Beginners-Guide-Herbert-Schildt/dp/0072225882), a fresh install of [Eclipse](https://www.eclipse.org/ide/), and I was on my way.

You know how most 11-year-olds would want to get home from school and play computer games for hours? Well instead I would slave away writing Java [Swing](https://en.wikipedia.org/wiki/Swing_(Java)) applications.

With no concept of version control, backups, tests, code structure, or libraries I learnt how things worked by reading the Eclipse autocomplete and posts on the Sun Java forums. It's amazing what you can do with unlimited time, a lot of patience, and no concept of the "wrong" way of doing something.

# Two: The USB Years

At some point while I was off in Java land, my dad installed Ubuntu[^ubuntu-version] on the family computer (why? unclear). This started my dive into the world of ultra-small Linux distros. I played around with running [Damn Small Linux](http://www.damnsmalllinux.org) from a USB drive in QEMU in Windows (with limited success), I then graduated to [Puppy Linux](https://puppylinux-woof-ce.github.io) which was more usable but still left a lot of space on my 1GB USB drive.

[^ubuntu-version]: Just going from vibes on my memory of the Ubuntu versions, I think this would have been 7.04 (Feisty Fawn).

![The exact USB drive that I used to have (and probably have in a drawer somewhere)](/images/2023/usb-drive.jpg)

These tiny distros were great to pull apart and see how things worked, and the community was full of people who were doing the same kind of tinkering—rather than doing real work. This gave plenty of practice in booting from [live CDs](https://en.wikipedia.org/wiki/Live_CD), installing Linux distros, and debugging the inevitable problems.

Eventually I scraped together enough money to buy my own computer—a $20 Windows ME-era desktop from a recycling centre[^pc-image-credit]:

[^pc-image-credit]: Credit to [www.3sfmedia.com](https://www.3sfmedia.com), who seem to restore and sell really old PCs? Or they're just an out-of-date computer shop.

![My first computer (well, one that looks just like it)](/images/2023/hp-pavilion.jpg)

> Side note: I've had amazing luck while writing this being able to find pictures of things. I searched for "Kingston 1gb usb drive" and "hp pavilion windows me desktop" and got images of _exactly_ what I was looking for immediately.

I'm not sure of the exact specs, but this probably had 600MHz clock, 128MB or 256MB of RAM, and a 15GB HDD. Even running a 100MB OS was challenging for this machine. I disassembled and reassembled this computer countless times as I would scrounge parts from other broken PCs. In the end I think it had 768MB of RAM and a 40GB HDD.

The next few years were spent trying to get my hands on newer hardware, and assembling a Franken-PC from the best bits. I think the peak of my power was a Pentium 4, and a 17" LCD monitor—a huge upgrade from the ~14" CRT that I had started with.

# Three: Netbook

*It's 2010. The netbook craze is at its peak.*

My parents helped me buy an Acer Aspire One netbook. This thing was the absolute bomb; it had more storage than all my Franken-PCs combined, it had wifi built in which would give me reliable internet anywhere in the house[^bad-internet].

[^bad-internet]: On my desktops I had to use a USB wifi dongle, which would interfere with my cheap speakers and make a buzzing noise whenever it was sending data.

By this point I was riding the Ubuntu train full-time, and so installed [Ubuntu Netbook Edition](https://en.wikipedia.org/wiki/Ubuntu_Netbook_Edition) 9.10 (Karmic Koala)[^karmic-koala] on it immediately—replacing Windows 7 Starter Edition. The tinkering didn't stop now that I had reliable hardware, I remember installing the Compiz settings manager to play around with thing like [wobbly windows](https://youtu.be/fG24PhCFDa8?t=103), deciding that I wanted to remove them to save valuable system resources, and ended up uninstalling Compiz itself. Since Compiz is actually the window manager and not some layer that just wobbles your windows, I had a very fun time trying to fix my system while all my windows were missing their chrome.

[^karmic-koala]: This particular version of Ubuntu seemed to work really well on the netbook, and so even more than a decade later I am still nostalgic for this one version.

Having a (somewhat) reliable computer meant that I got back to programming more, and I ditched Java Swing in favour of Ruby on Rails. The web is unparalleled in being able to make something and share it with others. Before, the things that I had made were mostly hypothetical to others, but once it's on the web anyone can go and use it.

My most successful project was a fake stock market game, where you could invest in, and create companies whose stock price would go up and down semi-randomly. Most of the fun was in giving your company a wacky name and description and then being amused when the stock price soared or tanked. This captured the zeitgeist of my school for a few weeks.

> Free web hosting (specifically the old free [Heroku](https://www.heroku.com) tier) for _real_ applications did so much to motivate me as I was learning web development. Being able to easily deploy your application without paying for dedicated hosting, setting up a domain, or learning how to setup a real server was so valuable in letting me show my work to other people. I was sad to see Heroku stopping this tier, but glad to see things like [Glitch](http://glitch.me) filling the niche.

I also made my first Android app on my netbook. Running Eclipse and an Android emulator with 1GB of RAM to share between them seems horrifying now, but when that's your only option you just make do. I do remember being massively relived when I accidentally found out that I could plug my phone in and develop the app directly on that, instead of using the emulator.

Eventually I replaced the netbook with a MacBook (one of the white ones that were actually just called "MacBook")—but still ran Ubuntu[^mac-ubuntu] until I realised that Minecraft ran _way_ better on OS X.

[^mac-ubuntu]: Installing Linux on Apple hardware is one of the most painful things you can do, I would not recommend it to anyone. Clearly [The USB Years](#three-the-usb-years) had made me foolhardy enough to try this.

Despite having made applications on a variety of different platforms, I hadn't strayed very far into different languages. I'd had to use Python for school and uni, but it's not much of a change from Ruby. It wasn't until 2014 and the introduction of [Swift](https://swift.org) that I actually learnt about a statically-typed language with more features than Java. The idea that you could have a variable _that could never be null_ or _could not be changed_ was completely foreign to me.

# Four: Peak Computing

The MacBook was eventually replaced with a MacBook Pro and then a MacBook Air when I was in university. At this point I felt like my computer could do anything. Unlike my netbook I could run external displays[^external-displays], install any IDE, SDK, or programming language. There would be countless different tools and packages installed on my machines. I'd usually have both MySQL and PostgreSQL running in the background (until I realised they were wasting resources while not in use, and wrote a script to stop them).

[^external-displays]: I think the netbook could actually do this, but it would be a really bad time for all involved.

Academically I know that my current computer(s) are much, much faster than any of these machines were. However I'm still nostalgic for the sense of freedom that the MacBook gave me. It was the only tool I had, and so it was the best tool for any job.

![My MacBook, hard at work making an app that simulated cicuits](/images/2023/macbook.jpg)

# Five: Down the Rabbit Hole

It must've been 2012 when I read ["I swapped my MacBook for an iPad+Linode"](https://yieldthought.com/post/12239282034/swapped-my-macbook-for-an-ipad). The idea was so enticing—having all the hard work happen somewhere else, being able to leave your computer working and come back to it being as though you never left.

However it seemed completely out of reach—it relied on you being able to use a terminal-based text editor, and while I could stumble around Vim it was nowhere near as effective as using [TextMate](https://macromates.com). It was like my dream of having an electric longboard—hampered by the cold reality of me not being able to stand on a skateboard.

Much like my learning to skateboard (which was spurred by a friend helping me stand on their longboard, showing me that it wasn't impossible)—my journey down the Vim rabbit hole started with a friend pointing out that "you can just use the Vim keybindings in Atom" (which allows you to do _some_ Vim stuff, but also use it like a normal text editor).

At university my interests veered into more and more abstract projects. Instead of making apps and websites for people to use, I was [learning Haskell to implement random algorithms](https://gist.github.com/willhbr/6e4d65328306b993ca6d) and [writing Lisp compilers](https://github.com/willhbr/lisp.js).

---

So if you ever wondered "why is Will like this", maybe this will help answer.
