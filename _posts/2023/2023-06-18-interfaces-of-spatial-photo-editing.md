---
title: "Interfaces of Spatial Photo Editing"
date: 2023-06-18
tags: opinion photography
---

How would you import, edit, and export photos using an AR/VR headset? I _personally_ think there is a lot of potential for this to be an exceptional experience, far better than working on a laptop, especially in sub-optimal working conditions. I also think the jump from hand to face is a significant hurdle that you might not want to dive head-first into—I've relegated a lot of that to the footnotes.[^footnotes]

[^footnotes]: These ones! They're like little extra treats at the bottom of (or hidden within) each post.

As with everyone else, I have been inundated with people's thoughts on spatial computing. The assumptions that I've made here are largely based on information from:[^also-note]

[^also-note]: I also read [this hilariously negative post](https://www.wired.com/story/apple-vision-pro-doomed/) on Wired which doesn't add much new information, but is a fun read.

- [WWDC 2023 Keynote](https://www.youtube.com/watch?v=GYkq9Rgoj8E)
- _Upgrade_ [#462](https://www.relay.fm/upgrade/462) and [#463](https://www.relay.fm/upgrade/463)
- [_The Talk Show_ Live](https://daringfireball.net/thetalkshow/2023/06/07/ep-378)
- _Connected_ [#453](https://www.relay.fm/connected/453) and [#454](https://www.relay.fm/connected/454)
- [_Cortex_ #143](https://www.relay.fm/cortex/143)
- [_Apple Vision Pro: A Watershed Moment for Personal Computing_](https://www.macstories.net/stories/apple-vision-pro-a-watershed-moment/) by Federico Viticci
- [_A Developer's View of Vision Pro_](https://www.david-smith.org/blog/2023/06/12/new-post/) by David Smith
- [_Vision Pro: I just tried Apple’s first spatial computer, and here’s what I think_](https://9to5mac.com/2023/06/05/hands-on-apple-vision-pro-mixed-reality-headset/) by Chance Miller
- [_First Impressions of Vision Pro and VisionOS_](https://daringfireball.net/2023/06/first_impressions_of_vision_pro_and_visionos) by John Gruber

Let's cast our mind into the not-too-far future, let's say about five or six years from now. Spatial computing devices (AR/VR headsets) have gone through the rapid iteration and improvement that happened in the first years of smartphones, and we've arrived at a device that is more refined from the first generation. Probably smaller, more robust, and with enough battery life that you don't _really_ worry about it.

# Interface

The interface would obviously depend on what idioms are established over the next few years. On the safe end of the spectrum would be something like the current touch-first interfaces present in the iOS Photos app and Photomator for iOS—a list of sliders that control adjustments, and a big preview image, all contained in a floating rectangle. You'd do some combination of looking at controls and tapping your fingers to make changes to the image.

An obvious problem with an eyes-as-pointer is that you usually want to look at the image while changing the slider, and a naive click-and-drag with your eyes would make this impossible. I'm sure that any sensible developer would realise this immediately, and work out a gesture-based interface where you can look at a control, grab the slider, and then move your hand to change it while your eyes are free to look elsewhere in the image.

Taking the interface one step further, the controls would probably escape the constraints of the app rectangle and become their own floating "window", allowing you to hold your adjustments like an artist's palette while your image floats separately in front of you. Sliders to represent adjustments might not even be necessary, each adjustment could just be a floating orb that you select and move your hand to adjust. There are definitely some touch interfaces that use the whole image as a control surface for a slider, and perhaps this will become the norm for spatial interfaces.

Or maybe we'll go in a less abstract direction; the interface will resemble a sound-mixing board with rows and rows of physical-looking controls, that can be grabbed and moved.

The photo library interface has similar challenges. The safe choice is to simply present a grid of images in a floating rectangle, using the standard gestures for scrolling and selection. Something that I foresee finding frustrating is an insistence for everything to animate, with no alternative. Swapping quickly between two photos to see differences and select the better shot is a common operation, and is made much less useful when there is an animation between the two (this is something I appreciated [moving from editing on an iPad to a Mac][macos-editing]).

A floating rectangle would get the job done, but doesn't take advantage of the near-infinite canvas available in your virtual world. Could you grab photos from the grid and keep them floating in space to deal with later—like living directly inside your desktop folder? This will really depend on what the idioms end up being for data management. Perhaps the standard for grouping related objects will be stacks that stay spatially consistent, floating wherever you left them last.

Spatial consistency is obviously very easy to understand, since that's how the real world works[^spatially-inconsistent-airpods], but when you start adding more and more data, the limitations of space become more apparent. What I don't want to happen is the flexibility of the digital world is restricted in order to match the limitations of the real world. In the real world an object can't exist in two places at once, but in the digital world it can be really useful to eschew this and allow putting photos in multiple albums, or creating different views over the same data.

[^spatially-inconsistent-airpods]:  Apart from my AirPods, they seem to just disappear and reappear around my apartment and in my bags without me doing anything.

# Data Management

I spend a lot of time working out how to get photos from my camera, into my computer, and then back out of my computer. At this point I've got fairly good at it. For new spatial computing devices, I think the data management story will be far closer to my experience [editing on my iPad][ipad-editing] than [editing on my Mac][macos-editing]. Let's work through it, step by step.

[ipad-editing]: /2019/11/02/impracticalities-of-ios-photo-management-for-photographers/
[macos-editing]: /2022/03/20/the-good-and-bad-of-photos-for-macos/

Getting photos from the camera. In the future, I think photographers will still be taking photos on dedicated cameras. The difference in potential quality and flexibility is just down to physics, having a bigger device to hold a bigger sensor and a bigger lens just gives you better photos[^not-spatial-photos]. As much as cameras get better each year, the best way to get the photos from them is still by reading the SD card. Wirelessly transferring photos is slow, painful, and tedious.

[^not-spatial-photos]: Maybe in 5 years we'll all be taking spatial 3D photos, but until we're all spending all our time in augmented reality, having photos that can be printed at high quality or viewed on a traditional screen will still be common.

> My [Sony a6500][a6500-specs] (which still commonly sells for AU$1,200) which was announced in 2016, has USB 2 (over micro USB) for wired transfers and 802.11n WiFi for wireless. The [a6600][a6600-specs], which was released in late 2019 has the same connectivity. I don't foresee wired or wireless transfer eclipsing the convenience of reading the SD card directly for the type of cameras that I buy.[^a7-better-transfers]

[a6500-specs]: https://www.dpreview.com/products/sony/slrs/sony_a6500/specifications
[a6600-specs]: https://www.dpreview.com/reviews/sony-a6600-review/8

[^a7-better-transfers]: The Sony a7 line of full-frame cameras have had USB 3 and 802.11ac for a few generations now, but they also cost well over twice as much, and I'd guess that most people that use them still read from the SD card directly.

Maybe your headset will support a dongle, but I am not optimistic. Instead you'll probably do that little dance of connecting to the camera's wifi network, and then using some half-baked app you can import the photos. It's not really clear to me what "background processing" might look like in a headset. If you've got 10GB of photos to import, do you need to keep the headset on while its transferring (the same way you've got to keep an iPad's screen on), or can you take it off and have it do work in the background?

Once the photos are on the device you can do the actual fun part of editing them. I assume apps like [Photomator][photomator] will be able to hook into the system photo library just like they do on iOS. Although if you want to do more complicated things that require multiple apps to work together (like stitch a panorama or blend parts of multiple images into one), you're probably going to have to jump through similar hoops as you do on iOS. The OS might support dragging and dropping images at the flick of your eye, but if the image is silently converted from raw to jpeg in the process, it's not very useful.

[photomator]: https://www.pixelmator.com/photomator/

Hand and eye tracking might make the level of precision control more akin to a mouse or trackpad rather than a touchscreen, which could allow apps like [Pixelmator Pro][pixelmator-pro] to bring their more complicated interface into the headset, but a lack of a wider ecosystem of professional-level tools (and OS features to make data-heavy workflows possible) might cause first movers to shy away.

[pixelmator-pro]: https://www.pixelmator.com/pro/

Once you've edited your photos, you can probably share them directly in the headset to friends, social media, or via something like AirDrop to your phone.

Then comes the real scary question: can you reliably back up your data without bring locked in to a single cloud storage provider? Again I see this as being more like an iPad than a Mac, backing up to dedicated photo storage services will be relatively easy, but if you want to backup to something you own, or handle storage off-device (on external drives, etc[^external-drive-backup]) you're probably out of luck.

[^external-drive-backup]: Not all data needs to be in an off-site backup, and the detritus of shots that didn't work out is a good example of something that should be backed up but doesn't require the same level of redundancy as high-quality edited photos.

Even if you choose to back everything up to a cloud service, you'll have to make sure that the headset is powered on for long enough for the data to transfer. In my neck of the woods, the internet upload speed I can get at a practical cost is 20Mb/s upload. Perhaps in five years this will have doubled and I'll have 40Mb/s upload. That's 5MB/s, so about 5 seconds for a 24MP image, which is about 2 hours to upload all the 1,300 photos from my trip to NZ earlier this year, assuming that the cloud provider can receive the photos that fast, and no one else is using the internet connection. It's not terrible, but definitely something I'd want to be able to happen in the background while the device isn't on my face.

# Workflow

Let's imagine that all these problems have been solved (or were never a problem to begin with), how would I see myself using this as my primary photo-editing machine?

Usually I edit photos on my laptop on the couch. I could replace the somewhat small 13" screen with an absolutely huge HDR screen, without even having a desk. The photos could be surrounded by a pure black void, so I could focus entirely on the image, or I could become self-important and place them in a virtual art gallery. Or in the middle of the two, I could edit them in pure black and then see which one would look best framed on my wall.

I'm not sure how I would show my in-progress edits to people, ideally something like my TV could be a bridge between the real and virtual worlds, allowing me to present a single window to it. This would probably work with my TV on my home network, but if I'm at someone else's house I doubt this would be possible across different platforms—given how fragmented doing this sort of thing is currently. What would probably end up happening is me exporting in-progress photos to my phone and using that to show people, and hopefully remembering to delete them later.[^share-screen]

[^share-screen]: A good gauge on how finicky this can be is to imagine you're in a holiday house and you want to show something on the TV. The only reliable thing to do is bring an HDMI cable and appropriate dongles, and plug in directly. There is no equivalent in the wireless realm yet.

When I go on a trip I'll usually bring my laptop so I can sort through my photos and edit some to get some gratification sooner, rather than waiting until I get back home. A headset could be a significant improvement as an on-the-go photo editor: at the very least it'll be smaller and lighter than my laptop so it'll take up less of the carry-on allowance and space in my bag[^different-space].

[^different-space]: Well, it'll take up a different space in the bag, the laptop is a convenient shape for putting in backpacks, a headset less so. Perhaps this means I need a new bag?

Usually my laptop would be left wherever I'm staying, since I can't realistically use it in bright sunlight or in a vehicle. But a headset could be used in these scenarios, so on the way back from an adventure I could plug myself into the virtual world and edit photos from the back seat of the car or plane or whatever, without having any glare on the screen or getting any debris in the keyboard.

You wouldn't use your laptop in the back seat of a car going down a windy dirt track from a ski field, but you could totally put on a headset and edit your photos through the car window.

---

The bottom line for me is that this type of device could be significant jump from what we have now, decoupling the physical limitation of device size from screen size and quality. Most of the hesitation I have is from a practicality perspective; can this be used for the way I work, or do I have to change what I'm doing to suit it?

Obviously the elephant in the room is the social aspect. People have been looking at markings on things ever since the first cave-dwellers realised that you can make a mark on a rock with a stick. Things have progressed slightly since then, but at its core a book or newspaper isn't that different to a phone or tablet. They're held in your hand, and you look at them with your eyes. The jump from hand to face is not something I think should be taken lightly.[^hand-face]

[^hand-face]: I haven't really shared my thoughts about this too much, but my general gist is that I think in order to avoid the chances of descending into a cyberpunk hellscape, bringing technology closer to our senses should be done hesitantly. It's already difficult to exist in society without a smartphone, and using a smartphone makes your activities in the real world more accessible to the online world. Augmenting your vision is allowing software to control your primary way of experiencing the world, and I don't think I ever want that to be necessary to operate in society.[^side-side-note]

[^side-side-note]: This is obviously not something that will happen in the foreseeable future, but examples that comes to mind is shops removing price tags "since it's visible in AR anyway", bus stops and other public markings are removed or outdated as the source of truth is in AR. Once AR is ubiquitous enough to basically be required, then your visual experience in the physical world can be used as advertising space.
