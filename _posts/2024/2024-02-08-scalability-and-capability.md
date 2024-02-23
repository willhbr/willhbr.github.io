---
title: Scalability and Capability
image: https://pics.willhbr.net/photos/2021-07-10.jpeg
---

I thought of this as a single topic, but when I started writing it I realised that I was really thinking about two different things—scalability and capability—but after writing half of this I also realised that the broader idea that I've been thinking about needs to include both. So let's start with:

# Scalability

Desktop operating systems are able to scale to cover so many use-cases in part by their open nature, but also because of the incredible flexibility of windowed GUIs. Every modern mainstream OS has a window manager that works in the same basic way—you have a collection of rectangles that can be moved around the screen, and within each rectangle there are UI elements.

Floating windows is such a good abstraction that it can be used on a huge range of display sizes. My netbook with a tiny 10" screen used the same system as my current 13" laptop. If I connect a huge external monitor, the interactions remain the same—I've just got more space to put everything.

What's really amazing is that there has been almost no change in the window metaphor since their inception. I'm not a computer historian, but I know that if you time-travelled and showed any modern desktop OS to someone using Windows 98 (which ran on the first computer that I used), they would be quite at home. The visual fidelity, speed, and some rearranging of UI elements might be a bit jarring, but "move this window over there" and "make that window smaller" work in the exact same way.

Characterising it as _no_ changes is obviously selling it short. The best change to the core windowing metaphor is the addition of virtual desktops. It fits in to the system really well; instead of having windows be shown on the screen, we just imagine that there are multiple screens in a line, and we're just looking at one of them. In the relationship of "computer" to "windows" we're just adding a layer in the middle, so a computer has many desktops, and each desktop has many windows. The best part is that the existing behaviour can just be modelled as a single desktop in this new system.

The difficulty is that this introduces a possibility for windows being "lost" on virtual desktops that aren't currently visible on the screen. Most window managers solve this by adding some kind of feature to "zoom out" from the desktop view, and show all the virtual desktops at once, so you can visually search for something you misplaced. MacOS calls this "Exposé" and I use it constantly just to swap between windows on a single desktop.

Tablets haven't yet managed to re-invent window management for a touch-first era. Allowing multitasking while not breaking the single-full-screen-app model is exceptionally challenging, and what we've ended up with is a complicated series of interdependent states and app stacks that even power-users don't understand. Even the iPad falls back to floating windows when an external monitor is connected, as being limited to two apps on a screen larger than 13" is not a good use of screen real estate.

# Capability

Something simultaneously wonderful and boring about computers is that while they continue to get better over time, they don't really _do_ anything more over time. The computer that I bought from a recycling centre for $20 basically does the same things as the laptop that I'm using to write this very post.

On my netbook I could run Eclipse[^before-as] and connect my phone via a USB cable and be doing Android development using the exact same tools as the people that were making "real" apps. Of course it was incredibly slow and the screen was tiny, but that just requires some additional patience. Each upgrade to my computer didn't fundamentally change this, it just made the things I was already doing easier and faster.

[^before-as]: This was before Android Studio, by the way.

Of course at some point you cross over a threshold where patience isn't enough. If I was working on a complicated app with significantly more code, the compilation time could end up being so long that it's impossible to have any kind of productive feedback loop. In fields like computer graphics, where the viewport has to be able to render in real-time to be useful, your computer will need to reach a minimum bar of usability.

However in 2020 I did manage to learn how to use [Blender](https://blender.org) on my 2013 MacBook Air. It could render the viewport fast enough that I could move objects around and learn how to model—so long as the models weren't too high detail. Actually rendering the images meant leaving my laptop plugged in overnight with the CPU running as hard as it could go.

All those same skills applied when I built a powerful PC with a dedicated graphics card to run renders faster. This allowed me to improve my work much faster and use features like volumetric rendering that were prohibitively slow running on a laptop.

![A computer render of a small cabin in a foggy forest with a radio mast next to it with sunlight shining through the trees](https://pics.willhbr.net/photos/2021-07-10.jpeg)

Rendering the fog in this shot would likely have taken days on my laptop, but rendering this at ultra-high quality probably took less than an hour.
{:class="caption"}

I really appreciate using tools that have a lot of depth to them, where the ceiling for its capabilities is vastly higher than you'll ever reach. One of the awesome things about learning to program is that many of the tools that real software engineers use are free and open source, so you can learn to use the real thing instead of learning using a toy version. This is one of the reasons I wanted to learn Blender—it's a real tool that real people use to make real movies and digital art (especially after watching [Ian Hubert's incredible "lazy" tutorials][lazytuts]). There are apps that allow for doing some of this stuff on an iPad, but none are as capable or used substantially for real projects.

[lazytuts]: https://www.youtube.com/watch?v=U1f6NDCttUY&list=PL4Dq5VyfewIxxjzS34k2NES_PuDUIjRcY&pp=iAQB

It's not just increases in processing speed that can create a difference in capability. My old netbook is—in a very abstract way—just as able to take photos as my phone. The only difference being that it had a 0.3MP webcam, and my phone has a 48MP rear-facing camera. The difference in image quality, ergonomics, and portability make the idea of taking photos on a netbook a joke and my phone my most-used camera.

Portability is a huge difference in capability, which has enabled entire classes of application to be viable where they were not before. There's no reason you couldn't book a taxi online on a desktop computer, but the ease and convenience of having a computer in your pocket that has sensors to pinpoint your location and cellular connectivity to access the internet anywhere makes it something people will actually do.

My phone is also capable of doing almost everything that a smartwatch does[^not-everything], but it's too big to strap to my wrist and wear day-to-day. The device has to shrink below a size threshold before the use-case becomes practical.

[^not-everything]: The exception being that it doesn't have a heart rate and other health-related sensors.

Of course the biggest difference between any of the "real computers" I've mentioned so far and my phone is that it has capabilities locked by manufacturer policy. It's much more capable from a computing power standpoint than any of my older computers, and the operating system is not lacking in any major features compared to a "desktop" OS, but since the software that can run on it is limited to being installed from the App Store and the associated rules, if you wanted to write a piece of software you'd be better off with my netbook.

My iPad—which has just as much screen space as my laptop—can't be used for full-on development of iPad applications. You can use [Swift Playgrounds](https://developer.apple.com/swift-playgrounds/) to write an app, but the app is not able to use the same functionality as an app developed on a Mac—the app icon doesn't appear on the Home Screen, for example. If this was a truly capable platform, you would be able to use it to write an application that can be used to write applications. Turtles all the way down. On a desktop OS I could use an existing IDE like IntelliJ or Eclipse to write my own IDE that ran on the same OS, and then use that IDE to write more software. That's just not possible on most new platforms.

"Desktop" operating systems are suffering from their own success—they're so flexible that it's completely expected for a new platform to require a "real computer" to do development work on for the other platform. This is a shame because it shackles software developers to the old platforms, meaning that the people that write the software to be used on a new device aren't able to fully embrace said new device.

Once your work gets too complicated for a new platform, you graduate back to a desktop operating system. Whether that's because the amount of data required exceeds that built into the device (a single minute of ProRes 4K from an iPhone is 6GB), or you need to process files through multiple different applications, you're much less likely to hit a limit of capability on a desktop OS. So unlike me, you might start on one platform and then later realise you're outgrowing it and have to start learning with different tools on a different platform.

Smartphones have made computing and the internet accessible to so many people, but with desktop operating systems as the more-capable older sibling still hanging around, there's both little pressure to push the capability of new platforms, or to improve on the capabilities of older ones.
