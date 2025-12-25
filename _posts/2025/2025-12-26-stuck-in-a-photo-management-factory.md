---
title: "Help I'm Stuck in a Photo Management Factory and I Can't Get Out"
image: /images/2025/izamal.webp
tags: photography
---

![Photo of the convent at Izamal, México](/images/2025/izamal.webp){:loading="lazy"}

I feel obliged to include a photo, since this post is about photography.
{:class="caption"}

In 2019 I got into this whole photography business and used my iPad for photo editing in [Photomator][photomator]. This went pretty well until I started to shoot raw photos instead of JPEGs, and quickly ran into the meagre 250GB internal storage limit of the iPad.

[photomator]: https://www.pixelmator.com/photomator/

At the time I [wrote about](/2019/11/02/impracticalities-of-ios-photo-management-for-photographers/) how limitations of the iPad make using it as an exclusive photo-editing device impractical. Basically the only way to get photos off the iPad was to upload them to a cloud service—at the time I had a terrible internet connection, so this was basically infeasible. On paper it was possible to export to an external drive, but for any number of photos to actually make a dent in my growing library, this was unsupported.

The most reliable thing to do would be to copy the photos onto a "real" computer using the MacOS "image capture" utility, where you could then dump them onto an external drive or whatever you desired.

Eventually I decided that if I needed a real computer in order to use the iPad, I should just edit on the computer to begin with, and so I [moved from the iPad to an M1 MacBook Air][photos-macos] with a nice 1T SSD.

[photos-macos]: /2022/03/20/the-good-and-bad-of-photos-for-macos/

In 2022 [I wrote][photos-macos]:

> My photo library currently takes up 500G and I’m not looking forward to having to split it.

How right I was.

At the end of 2023 my photo library burst out of my laptop like an extra-terrestrial creature from the chest of an unsuspecting space-tug crew member. I did exactly what I had planned: I carefully duplicated, backed up, and split my photo library in two. One library with everything before 2023 would live on an external SSD, the other with all my new photos would live on the laptop's internal storage.[^how-split]

[^how-split]: Honestly this was such a process it could be a post of its own.

I could continue to import and edit any new photos into the photo library on the laptop just as I had been doing. If I wanted to look at the old photos, I'd just have to plug in the SSD.

Except it's not _quite_ that simple. To open an alternate photo library you have to hold the option key while Photos is launching, then select it from a list (or navigate to it in Finder).

To actually edit something in a third-party editor (like aforementioned [Photomator][photomator]) you have to go into Photos' settings and make the current library the system photo library. This is because the third-party app has no knowledge of anything _other_ than a monolithic system library. You have to redirect that API to your external drive, then re-redirect it back once you've finished.

The end result was that all my photos before 2023 were lost media. Dead and inaccessible to the world.

So sometime last year I moved _everything_ onto a bigger 2T SSD[^ssd-brand]. This required whole extra process where I merged the two libraries back into one using [PowerPhotos](https://www.fatcatsoftware.com/powerphotos/). Multiple backups, merged, checked. Finally I had everything in one place with a path forward: the 2T SSD left me 700GB of headroom, and if I filled that I could just go and get a 4T or 8T drive and copy everything across.

[^ssd-brand]: A Samsung T7 drive. I've got that and a T5 and they seem good. I use SanDisk MicroSD cards but am [scared of their SSDs failing](https://www.theverge.com/22291828/sandisk-extreme-pro-portable-my-passport-failure-continued).

This even works better than just buying a new laptop with more internal storage, since the MacBook Air doesn't (currently) come with more than 2T of storage. So even if I'd spent the extra $600 to go from 1T to 2T, going to 4T means getting a bulky MacBook Pro.[^macbook-pro-costs]

[^macbook-pro-costs]: Going from a 2T MacBook Air to the cheapest MacBook Pro with 4T costs an extra $2000. Getting 8T costs $3200 on top of that.

It seemed like a great solution. It's even a [supported way to use the Photos app](https://support.apple.com/en-us/108345) and [mentioned by internet-resident Photos experts](https://sixcolors.com/post/2025/08/work-around-icloud-photos-optimized-limitations/).

What this documentation doesn't mention is that the system expects the library to always be available. The processes that slowly dawdle through your library identifying faces and whatnot will keep the database open, so the drive basically can't be safely ejected.

Of course you can just rip the cable out or click "force eject" and gamble with data integrity every time. Plenty of people seem to think that ejecting or unmounting is a thing of the past, from the era of floppy disks and CD drives.

Most of the time when I want to unplug the drive I'd have to resort to force ejecting it, since you can't stop the Photos system from retaining its access to the library. I don't know if this is what caused it, but fairly often Photos would open the library and have to spend a few minutes "repairing" it before you could do anything.

Other times it would completely fail to open the library with absolutely no recourse, just an error message saying "the library could not be opened". Through completely dumb luck I worked out that opening PowerPhotos would kick Photos back into gear and it would load the library.

While I haven't actually got into an irrecoverable state yet, it's disconcerting seeing your carefully organised photo collection fail to load every so often. Maybe a future OS update will fix whatever causes it to get into this state—but maybe an update will stop PowerPhotos' ability to kick it back into shape?

Then even after all this trouble, that's just the photo library. The edits from Photomator (and Pixelmator Pro) are saved in "sidecar" files in `~/Pictures/Linked Files` (this has moved around a little). There isn't a supported way of storing these on the external drive, I have tried to use symbolic links to keep all the files for Pixelmator Pro and Photomator together in one folder, but at least when I last tried one or both of them wouldn't follow the link and would just fail to save the file.

So here I am, 1.3T of photos sitting on an external drive in a photo library that _might_ be corrupted any time I go to use it.

It won't come as a surprise that since I filled up my internal drive, the number of times I've gone out to take photos has dropped off dramatically. Some of this is me [spending my time on other interests](/2025/12/13/programming-with-tmux-for-beginners/), but a large part is the sense of dread I get knowing that every photo I take is just digging me further into a pit of data management hell that I have no way out of.

I don't know what the solution is, no one seems to _enjoy_ using Lightroom. [Affinity](https://www.affinity.studio/) Photo has been merged into one mega-app, but it didn't have photo library management in the first place anyway.

There are interesting other options like [Aspect](https://aspect.bildhuus.com), but it's only organisation software—no editing. They say it'll recognise "popular" editors, but the exact details of that could make or break the workflow for me. I really value being able to flick between photos and go from viewing to editing with minimal faff. This was the main [reason for me to buy Photomator](/2023/05/24/photomator-for-macos/) even though it doesn't offer different editing capabilities from Pixelmator Pro.

Even if I did find another system, it would likely require a substantial (stressful) migration of my existing library. Would a move just be digging further into the hole, or would it actually get me onto a more sustainable path?
