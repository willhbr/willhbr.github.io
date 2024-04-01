---
title: "Complicated Solutions to Photo Publishing"
tags: projects photography homelab
---

As [previously discussed](/2022/04/22/shortcuts-is-a-cursed-minefield/) there have been some challenges keeping the photos on [my website](https://pics.willhbr.net) up-to-date. The key constraint here is my insistence on using Jekyll for the website (rather than something with a web-based CMS) and wanting somewhat-efficient photo compression (serving 20MB photos is frowned upon). Obviously I considered writing my own CMS for Jekyll with a web interface that I could access from my phone—this seemed like the natural thing to do—but I quickly realised this would spiral into a huge amount of work.

My intermediate idea was absolutely brilliant—but not very practical, which is why it's the intermediate idea. The key problem that I had before was that Shortcuts is cursed and every second I spend dragging actions around takes days off my life expectancy due to the increase in stress. The resizing and recompression would have to happen on a Real Computer™. Thankfully I have a few of those.

Something I didn't mention in my previous blog post was that there was another bug in shortcuts that made this whole situation more frustrating. The "Convert Image" action would convert an image to the output format (eg JPEG) but it would _also_ resize the output file to be about 480px wide. This was really finally broke my will and made me give up on Shortcuts. If I can't trust any of the actions to do what they say and instead have to manually verify that they're doing what they say after every software update... I might as well just do the actions myself.

> _Speaking of OS updates breaking how images are handled: [MacOS 13.3.1 broke rendering of DJI raw files](/2023/05/10/dji-dng-rendering-broken-on-ventura/), which stopped me from editing drone photos. This is thankfully now fixed in 13.4._

So the main challenge was how to get the images from my phone to a real computer that could do the conversion and resizing. My brilliant solution was to use a git repository. Not the existing GitHub Pages repo, a second _secret repository!_

On my phone I would commit a photo—at full resolution—to the secret repo and write the caption and other metadata in the commit message. This would be pushed to a repo hosted on one of my computers, and a post-receive hook would convert the images, add them to the _actual_ git repo, and write out a markdown file with the caption. Truly the epitome of reliability.

Thankfully, I never actually used this house of cards. I ended up signing up to [Pixelfed](https://pixelfed.org) ([you can follow me!](https://pixelfed.nz/willhbr)), which has a decent app for uploading photos with a caption. Being a good web citizen, Pixelfed publishes an RSS feed for user posts. So all I have to do is read the feed, download the images, copy it over to my website, and publish them.

Naturally the program is written in [Crystal](https://crystal-lang.org) (and naturally I came across a [serious bug in the stdlib XML parser](https://github.com/crystal-lang/crystal/issues/11078)). It checks if there are any posts in Pixelfed that aren't already on the website, downloads the photos, uses the ImageMagick CLI (which I think can do just about anything) to resize, strip metadata, and re-encode them, and then commits those to a checkout of the GH pages repository.

This was running via `cron` on my home server for a while, but I've recently containerised it for a bit of additional portability. It does still need access to my SSH keys so it can push the repo as me, since that was just much easier than working out the right incantations to get GitHub to give me a key just for writing to this one repo.

The biggest drawback of this solution is that images on Pixelfed (or at least [pixelfed.nz](https://pixelfed.nz), the instance that I'm on) are only 1024px wide, which is just a bit narrower than a normal sized iPhone screen so the images don't look _amazing_.

To be honest, now that I've gone through all this effort and have a container running a web server at all times... I might as well just make an endpoint that accepts an image and commits it to the repo for me.

Shortcuts can somewhat reliably send HTTP requests, so it's just a matter of base64-ing the image (so you don't have to deal with HTML form formats and whatnot), making a cursed multi-megabyte JSON request, and have the server run the exact same resizing logic on the image it receives.

So now if you look at [my photo website]({{ site.urls.photos}}) you should see some recent photos are a bit higher quality now:

[![A drone photo of the Sydney city skyline](https://pics.willhbr.net/photos/2023-05-22.jpeg){:loading="lazy"}](https://pics.willhbr.net/2023/05/22/post.html)

You might even be able to zoom in and spot me somewhere in that photo!
