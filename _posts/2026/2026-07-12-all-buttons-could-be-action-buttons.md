---
title: All Buttons Could Be Action Buttons
tags: opinion
---

My iPhone 15 Pro has four physical buttons. The two volume buttons, the sleep/wake button, and the Action Button, that replaced the silence switch in the iPhone 15 generation above the volume buttons. Since I never took my phone out of silent mode, I was a big fan of the swap to the action button, which [I have used as a camera shortcut](/2024/12/02/appreciating-the-fine-art-of-phone-photography/) since getting the phone.

The iPhone 15 Pro was the only phone to have the action button and _not_ have [the "camera control"][camera-control] button and touch-sensitive thing. On subsequent iPhones, the action button is the quick utility button, and the camera control is the camera launcher, which makes sense. It would be weird to have those around the other way.

[camera-control]: https://support.apple.com/en-au/guide/iphone/iph0c397b154/ios

However, since I'm still living the mono-button lifestyle—at least the mono-customisable-button lifestyle—I yearn for more options. I tooted on Mastodon the other day that I realised I could set the action button to a shortcut that checked if the device was locked, and multiplexed between opening the camera or creating a quick note[^quick-note]. The camera shortcut is most useful to press while I'm fishing my phone out of my pocket, so that it can be ready to capture a photo by the time I've got it pointed in the right direction. Creating a note quickly is most useful when I'm looking at something on my phone. So splitting the two actions based on whether the phone is locked is convenient.

[^quick-note]: "Quick Note" is an iOS feature where you get a somewhat context-aware compose window for a note, with options to add links to the current web page, etc.

Sadly Shortcuts on iOS is still not trustworthy. I [wrote four years ago](/2022/04/22/shortcuts-is-a-cursed-minefield/) about how I struggled to get a simple image resize to work. The width and height of an image would be reported as zero if the variable was read as "photo media" instead of "image". Reading the properties as "photo media" would work, but only after swapping to "image" and back again.

It's this kind of inconsist behaviour that has mostly stopped me from using Shortcuts (despite having [used it quite substantially in the past](/2018/12/26/compiling-for-shortcuts/)). I thought that a single conditional statement with two actions would work reliably. Sadly a lot of the time I'd press the action button, the shortcut would run, and I would get a camera, a note, or even an error message. I've gone back to using the built-in "launch camera" action for the button, and creating notes from the share sheet.

This got me thinking about how many physical buttons I've got on my phone, and how many customisable actions I could have access to. So let's go through it.

A short press on the sleep/wake button either sleeps or wakes the phone. Probably not a good idea to change that one.

Two short presses opens wallet/Apple Pay. This is frequently used enough for me that I appreciate it being easily accessible.

A long press activates Siri. I don't really use voice assistants much as I'm embarrassed by talking to a computer, so this could be replaced with something more useful. Maybe taking a screenshot, or to create a note.

The shortcut for screenshots is sleep/wake and volume up, but there's no pairing for volume down, or the action button. These shortcuts are a little fiddly, which is why I'd rather take screenshots by long-pressing the sleep/wake button.

Pressing the volume buttons change the volume, long press changes the volumes more, and double-click changes it twice. There's not a lot of ground for customisation here, and that's probably sensible.

Next is the action button. It's the only one that has significant customisation, but only for its single medium-length press. At the very least it would be nice to have a secondary action for double-press (with the same cadence you use for opening wallet from the sleep/wake button). This would solve my desire to have two different actions with only one button to use.

The action button only triggers after a fairly intentional press. Not quite a long press, but definitely not a singular click. That's understandable to avoid accidental presses, but you could have a third action (perhaps that only works when the screen is on) that activates on a quick press. I can see that this would be confusing, so I understand why you wouldn't do it, but that doesn't stop me from wanting it for myself.

There's also triple-click on the sleep/wake button to activate the accessibility menu, and whatever the incantation is to get your phone to lock down to require a password instead of Face ID.

Fairly conservatively, I think it would be great if the wallet (sleep/wake double-click) and Siri (sleep/wake long press) shortcuts could be customised, and a second double-click action added to the action button. For me that would give two additional free actions to play around with.

It would also be great to have a native action selector, so I could double-click the action button and get something like a touch version of a [pie menu](https://en.wikipedia.org/wiki/Pie_menu) showing my selected actions. Imagine if I could customise what actions were shown based on context. I usually make notes from web pages, so maybe that should only be shown there. Maybe if I'm in a messaging app, I could get actions to share a recent photo or something. The opportunities could be endless.

Ultimately this will mostly be moot by the end of this year, as I plan on getting a new phone—on my three-year schedule. I'll likely have a camera control button which will free up the action button for whatever nonsense I feel like. However, adding a whole new button to free up capabilities that could be unlocked entirely in software with the existing hardware feels wasteful.
