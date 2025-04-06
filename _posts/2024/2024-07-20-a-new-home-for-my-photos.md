---
title: "A New Home for My Photos"
tags: web photography
image: /images/2024/new-photos-website.webp
---

A few weeks ago Eugen Rochko (creator of Mastodon) published a [new photography portfolio website](https://eugenrochko.com). This quickly made me want to improve my own photography website. Eugen's site puts more of a focus on small groups of photos, and makes the photo metadata prominent—Eugen shoots on film so this is information about the camera as well as the type of film used and where it was developed.

My photo website was forked from this site a few years ago. The purpose of the design is to make it seem like it's part of the same site—the colours and header match exactly. It's built mostly around a photo grid, replicating the view you'd get on Instagram, with square thumbnails for all pictures. There isn't really anywhere to show additional information or commentary about the photo, and the fact that the style matches this site means I have to keep the two repositories in sync.[^no-theme]

[^no-theme]: If I did GitHub Pages with a custom build action, perhaps I could turn this into a theme that could be properly shared between the two sites.

![screenshot of my old photos website](/images/2024/old-photos-website.webp){:loading="lazy"}

That's my old photos website, with an Instagram-style grid layout.
{:class="caption"}

Over the course of about a day I pulled together a new site that is less of a copy of Instagram and more of a photo journal. You can [see it live here](https://photography.willhbr.net).

![screenshot of my new photos website](/images/2024/new-photos-website.webp){:loading="lazy"}

The current state of my new photos website.
{:class="caption"}

I also took inspiration from [Sebastiaan de With's photo blog](https://sdw.space/photography/). I am perpetually jealous of the stunning photos he shoots on his phone.

Probably the biggest pain was my decision to not have titles for posts. They can have a location, but otherwise they are just identified by the date. Whenever I show a post I display a heading built from the location, date, and number of photos. The format of this is changed depending on how many photos there are, and whether there is a location set on the post. The complexity in implementation is worth it for me, as it reduces the overhead to publishing something—photos can be added with no additional commentary.

The photos linked to a single post are defined as a list in the [Jekyll](http://jekyllrb.com) frontmatter. This includes information pulled from the EXIF metadata—camera, lens, aperture, shutter speed, and focal length. If any of these are omitted, they will be gracefully omitted on the website. The actual body of the post allows me to write as much or as little as I want.

The layout is fairly simple—it's mostly just a vertical stack of elements. I'm no CSS wizard. The one trick that I think is worthwhile is setting the `max-height` of an image to `80vh` so you'll always be able to see the whole image, no matter the size of your browser window. I decided that any kind of fancy flex-box-y layout wasn't really worth it since most people would be looking at this on a phone, where you only want to show one image at a time anyway.

I put the same amount of care into the RSS feed as I did into the main website. Since the photos are defined in the frontmatter and not in the body of the post, it's easy to render them differently for the feed with fewer HTML tags, as well as formatting the pseudo-title (built from the date and location, remember) for the plaintext title of the feed item. My hope here is that if you follow the site via RSS (or JSON Feed!) you'll get as good an experience as if you were viewing the web page.

There's also a little Ruby script that reads the EXIF data using [ImageMagick](https://imagemagick.org), creates the Markdown files with frontmatter, and recompresses the images. Who knows how I'll end up [publishing photos in the long term](/2023/05/22/complicated-solutions-to-photo-publishing/), but for now the script will have to do.

There are 80 posts and 200 photos already on there, a different collection to what I had on my previous site. Perhaps you should go and [have a look](https://photography.willhbr.net).
