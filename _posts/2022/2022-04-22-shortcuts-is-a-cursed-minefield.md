---
title: "Shortcuts is a Cursed Minefield"
tags: opinion shortcuts
---

This all starts with me wanting to [host my photos outside](https://pics.willhbr.net) of [Instagram](https://instagram.com/willhbr). I ended up using GitHub pages and wrote a simple iOS Shortcut to resize and recompress the image to make it suitable for serving on the web.

The shortcut is fairly simple - it takes an image, creates two versions (a main image and a thumbnail for the homepage), crops the thumbnail into a square to fit on the homepage grid, then saves the images to [Working Copy](https://workingcopyapp.com) ready to be published to GitHub Pages.

The problem arises when cropping the thumbnail. See what I need is:

![image showing cropping/resizing](/images/2022/resize-diagram.png)

The image needs to be resized to that the shortest side is 600px long, and then crop the centre of that image to a square. Shortcuts has a built-in action for resizing the _longest_ side to a certain length, but not the shortest side.

Instead you have to compare the width and height of the image and resize accordingly:

![image showing if statement in shortcuts with resizing](/images/2022/resize-conditional.png)

However this gives me stretched out images for landscapes:

![squished image after resize](/images/2022/resize-squished.png)

After much head-scratching at what was going on, I figured it out. I was accessing the width and height of the image like this:

![accessing height/width with photo media type](/images/2022/photo-media-width.png)

While debugging I could print this value and see the correct dimensions for the images that I was selecting. I tried assigning these to separate variables just in case there was some weird type-casting happening when they got passed to the `if`, but you can't do less-than or greater-than on arbitrary shortcuts variables:

![image showing no less/greater than](/images/2022/no-greater-than.png)

In a moment of desperation I swapped the `Type` to be "Image" rather than "Photo media" (getting desperate at this point), and it worked exactly as it should.

![correctly resized and cropped image](/images/2022/resize-correct.png)

Being thorough, I tried changing the `Type` back to "Photo media"... and it also worked. I made a new shortcut and left it at the default of "Photo media"... and it failed again.

The shortcut would only work if I either left the `Type` as "Image", **or** set it to "Image" and then set it back, obviously flipping some invisible internal value[^internals] of the shortcut to correctly compare the width and height.

No programming language, API, library, or framework has made me as frustrated as writing even the most trivial Shortcuts.

[^internals]: I briefly tried inspecting the internals of the `.shortcut` file [as I have done before](https://willhbr.net/2018/12/26/compiling-for-shortcuts/), but the signing that is now included made that more difficult than I had enthusiasm for.
