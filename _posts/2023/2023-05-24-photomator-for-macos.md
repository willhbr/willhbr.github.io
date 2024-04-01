---
title: "Photomator for MacOS"
tags: photography
---

Since moving my [photo editing to MacOS just over two years ago][macos-migration], I have been using [Pixelmator Pro][pro] as my photo editor of choice. The move from [Pixelmator Photo][photomator] was easy—the editing controls are the same, and I'm generally familiar with layer-based image editors from a misspent youth using [the GIMP][gimp].

However, the workflow using Pixelmator Pro in Apple Photos was not ideal—it works as a photo editor extension, so you need to first enter the standard edit mode in Photos, and _then_ open the Pixelmator Pro extension. Once you're done with your edits you need to first save in Pixelmator and once again in Apple Photos. While this is no means a dealbreaker—I've been doing this for over two years—it is clunky. On the occasion I deviate from landscape photography and take photos of people, I typically have many photos that require a little bit of editing, rather than a few photos that require a lot of editing. This is where the Pixelmator Pro workflow really falls down.

So of course [Photomator for MacOS][photomator] is the natural solution to my photo-editing problems. It's been out for just over a week now, and I've been using the beta for a few weeks before the release.

Just like its iOS counterpart, Photomator provides its own view into your photo library, along with the familiar editing interface that is shared with Pixelmator Pro. The key improvement is that you can immediately jump from the library into editing a photo with just a single keypress, since there are no Photos extension limitations at play here. I'd say this saves a good 5 seconds of waiting and clicking on menus per image. It also makes me more likely to try out editing a photo to see what an adjustment looks like, since I don't have to navigate through any sub-menus to get there.

# Previously

My workflow with Pixelmator Pro was fairly simple—I'd import photos into Photos, creating an album for each photo "excursion" I went on. I would flick through the album a few times, favouriting the ones that stood out (in Photos pressing "." will toggle favourite on a photo).

I'd then switch over to the Favourites view, and on each photo I'd click open the edit view, open "Edit with" > "Pixelmator Pro", and then actually do the editing. After editing I click "Done" in the Pixelmator extension, and "Done" in the Photos edit interface.

Since the extension is full Pixelmator Pro, you have full layer control and the ability to import other images. So if I'm stacking photos, I would just add a new layer using the Pixelmator photo picker. This is the quickest way of editing multiple photos as layers while staying inside the Photos system (ie having your edits referenced to a photo in the photo library).

If I need to create a panorama or stack stars for astrophotography, I'd export the originals to the filesystem and import them into [Panorama Stitcher][pano-stitcher] or [Starry Landscape Stacker][star-stacker][^star-stacker-foot], and then re-import the result.

[^star-stacker-foot]: Starry Landscape Stacker does what it says on the tin, but it is also an example of software that requires some significant UX consideration before anyone would enjoy using it.

# Currently

With Photomator, this workflow hasn't changed that drastically. The main difference is that I don't have to do multiple clicks to get to the Pixelmator Pro editing interface.

I start out the same way by importing from an SD card into Photos (I could do this in Photomator, but I don't see a benefit currently). In the album of imported photos I flick through my photos, favouriting the ones worth editing. This is still done in Photos as Photomator has a noticeable (about 400ms) delay between showing a photo and rendering an appropriate-quality version. This is distracting if you're trying to go quickly, so I stick to doing this part in Photos.

Next I go through the favourites in Photomator (the delay doesn't matter here as every photo is worth an edit) and apply basic edits. If something requires adjustments that Photomator doesn't support (basically anything with multiple image layers, like an exposure bracket, or other multi-photo blend) then I'll go back to Photos and open the Pixelmator Pro extension to make the changes.

With time, I'm sure the shortcomings in Photomator will be patched up, and I'll be able to simplify my workflow.

Ideally I would import straight into Photomator—perhaps through a Shortcut or other piece of automation to filter out unwanted JPEGs[^unwanted-jpegs]—and then triage the photos in the Photomator interface. I could then work through my edit-worthy photos, applying quick adjustments and crops right there.

Anything that requires more tweaks, could be seamlessly opened in Pixelmator Pro with a reference back to the original image in Photos. When I save the edit in Pixelmator Pro, the original image should be modified with my edits. If I re-open the image in Photomator, it should know that it was edited in Pixelmator Pro and use that as the editing interface.

I could use Photomator full-time without smart albums, but they are such a powerful feature in Photos for keeping things organised that I would almost certainly go back to Photos to use them. [A quick search](https://stackoverflow.com/questions/57108923/swift-how-to-fetch-all-photos-phasset-except-screenshots-burst-live) seems to show that `NSPredicate` supports arbitrary expressions, so it doesn't seem like there's an API limitation that prevents Photomator from doing this.

[^unwanted-jpegs]: Consumer-level DJI drones can shoot in RAW, but can't _only_ shoot in raw. They will shoot raw+JPEG, so you're forced to fill your SD card with JPEGs just to delete them before importing the raw files to your computer.

We're definitely still in early days of Photomator on MacOS. I've had a few crashes (no data loss, thankfully), and there are a few odd behaviours or edge cases that need to be tidied (most annoying is that images exported and shared via Airdrop lose their metadata). The team is responsive to feedback and support email, so I'm confident that this feedback is heard.

So after using the beta for a few weeks, I ended up buying the lifetime unlock (discounted) as soon as the first public release was out. I have edited thousands of photos in Pixelmator Pro on MacOS and Pixelmator Photo on iPadOS, and am quite happy to pay for a more convenient and focussed version of the tool that I'm most familiar with.

Photomator would be my recommendation to anyone that is wanting something more powerful than the built-in editing tools in Photos, as long as they're not likely to need the layer-based editing currently only offered by Pixelmator Pro. Although the pricing is a bit weird, Photomator is about the same cost in yearly subscription as Pixelmator Pro is to buy. I wouldn't be surprised if Pixelmator Pro becomes a subscription soon.

---

A side note that I can't fit elsewhere: [Nick Heer (Pixel Envy) wrote](https://pxlnv.com/linklog/photomator-mac/):

> For example, the Repair tool is shown to fully remove a foreground silhouette covering about a quarter of the image area. On one image, I was able to easily and seamlessly remove a sign and some bollards from the side of the road. But, in another, the edge of a parked car was always patched with grass instead of the sidewalk and kerb edge.

The Pixelmator folks definitely lean into the ML-powered tools for marketing, but I generally agree with Nick that they don't work as flawlessly as advertised—at least without some additional effort. You can get very good results by combining the repair and clone tools to guide it to what you want, but expecting to be able to seamlessly remove large objects is unrealistic.

> I also found the machine learning-powered cropping tool produced lacklustre results, and the automatic straightening feature only worked well about a quarter of the time.
> But, as these are merely suggestions, it makes for an effectively no-lose situation: if the automatic repair or cropping works perfectly, it means less work; if neither are effective, you have wasted only a few seconds before proceeding manually.

This is the real key, the ML tools can be a great starting point. They have a very low cost to try (they typically take less than a second to compute on my M1 MacBook), and they're easy to adjust or revert if they do the wrong thing. Almost all edits that I make start with an ML adjustment to correct the exposure and white balance—and it often does a decent job.

[macos-migration]: https://willhbr.net/2022/03/20/the-good-and-bad-of-photos-for-macos/
[pro]: http://pixelmator.com/pro/
[photomator]: https://www.pixelmator.com/photomator/
[gimp]: https://www.gimp.org
[roadmap]: https://www.pixelmator.com/photomator/roadmap/
[pano-stitcher]: http://panoramastitcher.com
[star-stacker]: https://apps.apple.com/us/app/starry-landscape-stacker/id550326617
