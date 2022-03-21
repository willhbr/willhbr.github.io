---
layout: post
title: "The Good & Bad of Photos for MacOS"
date: 2022-03-20
---

I've [previously written about](https://willhbr.net/2019/11/02/impracticalities-of-ios-photo-management-for-photographers/) how iOS/iPadOS is poorly suited to anything more than casual photography.

Unsurprisingly there hasn't been a change in iPadOS's capabilities since 2019. However through a fortunate series of events I've found myself in possession of an M1 MacBook Air, and have been using that for storing/editing my photos for the last year or so.

> As well as ending up on Instagram, my photos also end up on [a real website](https://pics.willhbr.net).

## The Good

Reviewing and flagging photos on MacOS is much quicker and easier than on iPadOS. The arrow keys move instantly between photos (instead of having to swipe and see an animation), which means you can have a more direct comparison between two shots. Pressing "." quickly favourites a photo, which I use to mark a photo as a possible editing opportunity. Deleting photos or removing them from an album can be done with one shortcut – no annoying confirmation required _every time_. These few things alone make it much easier for me to scan through my photos, find the best ones, and clear out any obvious rubbish.

On iPadOS you **still** have to **manually unfavourite every single photo**, which makes using favourites as a staging area impractical and frustrating. ([Darkroom](https://darkroom.co) has implemented their own "flag/reject" system as a workaround, but I was already using MacOS at this point).

Photos on MacOS has a much more robust and mature album system – the best feature being smart albums. This lets me have an "Edited" smart album that just shows edited photos. Some apps on iPadOS will add edited photos to their own album, but that's limited per-app and depends on how it integrates with the photos library. Smart albums are also much more flexible – you can filter by camera model, shutter speed, aperture, date, etc. So it's completely trivial to do something like find all the long exposure shots from my new camera that have been edited.

Of course the real advantage to MacOS is that the photos library lives in the file system, and I can just go and look at it. The real, original bytes that came from my camera are fully within my grasp – I don't have to worry about transparent re-encoding as I move them around – and I can actually back them up to somewhere that isn't iCloud or Google Photos. I can include them in Time Machine, I can copy them to an external drive, or I can create my own janky system that uses `rsync` to copy them to a Raspberry Pi sitting on my network.

I also now have access to more advanced or flexible software. As much as I like [Pixelmator Photo](https://www.pixelmator.com/photo/) it is limited to only making colour adjustments to a single layer. [Pixelmator Pro](https://www.pixelmator.com/pro/) on the other hand has all the same features (even with the same UI) but has layers (and layer masks!), effects (blurring and suchlike), and painting tools. This makes it possible to do things like [merge multiple fireworks shots into one picture](https://pics.willhbr.net/2022/01/01/post.html), or [fake the motion of many ferries at once](https://pics.willhbr.net/2021/12/28/post.html).

![fireworks photo with implausible number of fireworks](https://pics.willhbr.net/photos/2022-01-01.jpeg)

In addition to Pixelmator Pro, I've also found use in single-purpose utilities like [Starry Landscape Stacker](https://sites.google.com/site/starrylandscapestacker/home) and [Panorama Stitcher](https://www.panoramastitcher.com) – which has come in useful with my [still-quite-new DJI Mini 2](https://pics.willhbr.net/2022/02/06/post.html).

While none of this is impossible on iPadOS, these tools are made with the assumption of a more serious use – for example I can stitch together 20 raw images from my a6500 and get a 1GB TIFF out the other end. Not a single pixel of data is lost, and the software on MacOS can scale to handle it without hitting any limits.

## The Bad

While much of the software _around_ Photos on MacOS is built for serious users, Photos itself is still lacking. For example, when you export a JPEG, you get a few pre-defined choices for quality instead of a slider. I'd like to export at 95% quality, but instead I'm stuck with whatever "high" or "maximum" mean (probably 80% and 100%). I could probably work around this with Shortcuts, but that's another whole can of worms.

Apps can integrate their editing UI directly into Photos – but there isn't a quick way to jump straight to editing in a specific app, you've got to open the default Photos editor and _then_ open it in the app you actually want. There **is** a way to jump directly to an app, but it doesn't support preserving the adjustments you made, you just get a new image with the adjustments baked in. So if you want to do a complex edit where you might come back later to tweak it, this is no good.

The editing UI in Photos also limits you to using one window, since Photos itself only supports a single window. This is the kind of limitation I'd expect on iPadOS, not on MacOS.

Backing up with Time Machine is a terrible experience. Not specific to Photos, but this is what pushed me to make a custom solution using `rsync`. Backing up to a NAS appears to be almost impossible (without buying a Synology or something else that has worked out how to trick MacOS into using it as a backup target), and backing up to an external disk is horrendously slow and temperamental. MacOS also fights you with permissions issues trying to read the contents of the photo library – the permissions changes added in MacOS Catalina do not mesh well with any kind of custom script (even Apple's own `launchd` doesn't work with it), which makes custom backups harder to implement and rely on.

I opted to get the 1T SSD in my MacBook, since I knew I wanted enough storage to keep me going for a few years. There doesn't seem to be any _particularly_ well-supported way of splitting a Photos library in two, so that part of it can be offloaded to archival storage. You can do it by duplicating the photo library itself, archiving one copy, then delete all the old photos from the unarchived copy. My photo library currently takes up 500G and I'm not looking forward to having so split it. This is an obvious "strategy tax" that Photos pays when the recommended thing to do when you run out of local storage is to pay for iCloud storage. However that only goes up to 2T and what do you do then?

The experience of using MacOS to manage and edit photos is far better than iPadOS. I do still miss being able to twiddle my Apple Pencil while thinking of how I wanted to apply my edits, and do it without a keyboard in the way. Additionally, you get a way better screen on an iPad for a similar price as a MacBook Air.

Now that I've made the shift to MacOS, the iPad would have to do something amazing for me to switch back.

---

> OH! A side note, did you know there's no way to import a photo library from an iOS device to MacOS? You can import the photos (either directly from the Photos app, or using Photo Capture) but this doesn't import any albums, or _edit history_. I'm fairly sure I've lost some originals in the process of importing pictures from my iPad – and the only way I can see to do it is upload it all to iCloud and re-download it on MacOS, or write your own app to write all the photos to some external storage connected to the iPad, along with custom metadata, and then write a MacOS app that imports them back. You just have to ignore the fact that external storage _still_ is terribly limited and unreliable on iPadOS.