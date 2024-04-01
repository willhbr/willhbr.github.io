---
title: "DJI DNG Rendering Broken on Ventura"
image: /images/2023/bad-dng-render.jpeg
tags: photography
---

As [previously mentioned](/2022/03/20/the-good-and-bad-of-photos-for-macos/) I use my M1 MacBook Air to edit photos, which I post on [my website](https://pics.willhbr.net) and on [Instagram](https://instagram.com/willhbr). This past weekend I went to the beach and flew my drone (a wee DJI Mini 2) around, and got some nice pictures of the rocks, sand and the stunningly clear water.

Well, I thought they were good until I got home and looked at them on my laptop—every one of them had a horrible grid of coloured blobs overlaid on it, which made them basically unsalvageable. This is not something I'd come across before with my drone, so it was definitely a surprise. Naturally I started debugging.

![A photo from my DJI Mini 2 with coloured splotches over it in a grid](/images/2023/bad-dng-render.jpeg)

My first thought was that it was glare from the polarising filter that I usually have attached, however it was present on all the photos—not just the ones facing towards the sun. Nevertheless I powered the drone up and took some shots without the polariser on. My next thought was that there was a bad software update, and that another software update would fix the issue. There was an update available so I applied that, and took a few more test shots.

When I had the images loaded onto my laptop I could see that photos without the polariser and even with the software update still had the issue. JPEGs were unaffected, so this is just a raw image problem. Very strange. Thankfully I have plenty of other images from my drone in similar situations, so I can compare and see if maybe I was missing something. There aren't any issues with any of my old photos, but then I remember that Photos is probably caching a decoded preview, rather than reading the raw file every time. So that means if I export the DNG file and try to preview it, it _should_ fail.

Gotcha! It's a bug in MacOS! If I export any raw file from my drone and preview it on Ventura, it renders with terrible RGB splotches in a grid all over it. The silver lining is that the photos I took at the beach are still intact—I just can't do anything with them right now.

I wondered if other DNG files have the same issue, so I took a photo with Halide on my iPhone and downloaded a [DJI Mini 3 Pro sample image](https://www.dpreview.com/sample-galleries/2271796398/dji-mini-3-pro-sample-gallery/3814760755) from DPReview. The iPhone photo rendered fine, and the Mini 3 photo was even more broken than my photos:

![Sample photo from Mini 3 Pro with brightly coloured vertical lines all the way across the image](/images/2023/bad-mini-3-pro.jpeg)

Naturally the next thing to do is to try and work out how widespread the issue is while chatting with support to see if they can tell me when it might be fixed. I only managed to work out that my old laptop (Big Sur) has no issues, and that there are [some forum posts](https://www.pixelmator.com/community/viewtopic.php?p=72482#p72482) if you already know what to search for ("DNG broken MacOS" didn't get me many relevant results at the start of this escapade).

Support says that I just need to wait until there's a software update that fixes it. So no drone photos until then.

> Update: MacOS 13.4 appears to have fixed this issue.
