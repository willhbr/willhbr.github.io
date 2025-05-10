---
title: "Building NZ Topomap of the Day"
tags: projects
image: /images/2025/topomap.webp
---

The idea for this project came while watching some YouTube video. The background of a graphic was a collection of non-intersecting morphing lines that looked just like [contour lines](https://en.wikipedia.org/wiki/Contour_line). It makes for a [nice simple background](https://duckduckgo.com/?q=contour+background+wallpaper&iax=images&ia=images), which I assume most people just generate using [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise) or something similar.

Wouldn't it be cool to have wallpapers with contours that corresponded to real geography, rather than just random noise? Quickly I realised the thing I actually wanted was to make wallpapers from the [New Zealand topographic maps][nz-topomap].

[nz-topomap]: https://geodata.nz/geonetwork/srv/api/records/eb3e0bd2-fd4a-7f71-30d1-3128d268ae44

![a section of topomap showing forest and mountains](/images/2025/topomap.webp){:loading="lazy"}

The topomap for March 13th, 2025.
{:class="caption"}

Topomaps were a common sight while growing up in New Zealand, they're the first port of call for scoping out a hiking route. The entire country is mapped at 1:50,000 scale.

I knew you could access the maps online on [topomap.co.nz](https://www.topomap.co.nz), but only after looking at the about page for that website did I realise that the maps are part of a [publicly available dataset][nz-topomap]. You can go over to Land Information New Zealand and download 10GB of images and have all the maps right there. They are Creative Commons licensed, and my not-a-lawyer interpretation is that I could make a tool that creates wallpapers from the image data.

The map is downloadable in a [GeoJPEG][geojpeg] format—a big pile of images with some associated metadata files. I made a decision that would definitely come back to haunt me to not parse the metadata correctly, and instead take some shortcuts.

[geojpeg]: https://help.koordinates.com/file-formats-and-data-types/geojpeg-format/

The simplest thing to do would be to pick a random image—representing a 24x36km area in a 5671x8505px image—and crop a random section out of that to be our wallpaper. This would work and be very easy, you wouldn't even need to look at the GeoJPEG metadata.

However since the images are tiles, cropping solely inside one image will guarantee that you will never get a wallpaper that is centred on the border between two images. The areas in the centre of each tile would be more likely to appear in a wallpaper, with the chances reducing the further you got to the edge.

My way to get around this was to find four images that made a 2x2 grid and merge them into one 48x72km image, and then crop _that_ into my wallpaper. This lets the crop straddle a vertical or horizontal border between two images.

This did require finding the neighbours of a given image, which meant I had to parse the GeoJPEG data at least a little bit to work out each image's relative coordinates. The first approach here was to work out a coordinate that would be in the centre of the adjacent map tiles (the x/y position of the root tile plus 1.5x of the width/height), then find a tile that overlapped that coordinate. This worked most of the time, but it turned out that there are a lot of tiles that have some amount of overlap. This meant that I'd select the wrong tile and get a mis-matching seam in my image.

The solution that worked here was to get the coordinates of each corner of the base tile, and look for tiles that are at those coordinates. There's a little bit of fudging required here since the "coordinates per pixel" value in the GeoJPEG metadata is a float, and the coordinates are sufficiently large that the calculated coordinates are ever so slightly different from the actual coordinates of the neighbouring corners. So instead of looking for an exact match, I find a tile that's within 100 units of the target coordinate, which seems to be working so far.

The actual image manipulation uses [Pillow][pillow], a fork of the [Python Image Library](https://en.wikipedia.org/wiki/Python_Imaging_Library). I'd used Pillow before and knew that it was pretty capable, fast enough, and easy to use. Of course I looked at image manipulation support in my favourite esoteric languages[^langs] first, but most of the libraries I could find seemed to focus on conversion of images, rather than image manipulation. I didn't find anything that would beat the ease of using a well-supported library in a widely-used language.

[pillow]: https://pypi.org/project/pillow/

[^langs]: Crystal, Rust, and Swift were my top contenders here.

Implementation-wise, it's not actually that complicated: load the image metadata, pick an image, find the neighbours, merge them, crop a random section from that. The thing that I wasted the most time on was stubbornly attempting to implement image- and map- coordinate calculations without drawing a diagram first. Instead I would go around in circles flipping additions to subtractions until I eventually would just give up, draw a diagram, and solve it immediately.

There is one trick, which is discarding images that have too much sea in them. I want the maps to be interesting, and having a completely-blue image is not very exciting. To avoid this, I count the number of blue pixels and compare that with the number of non-blue pixels:

```python
def is_mostly_blue(image):
  h, _, _ = image.convert('HSV').split()
  histogram = h.histogram()
  # this is where the blues are at
  blues = sum(histogram[140:150])
  total = sum(histogram)
  ratio = blues / total
  return ratio > 0.85
```

Using a histogram makes this much faster than counting the pixels manually. I could have found the exact shade of blue that is used for the sea, but picking a range of blues gets the job done. Anything over 85% blue is deemed too boring and I'll restart the whole image generation process to pick a new base tile and crop that.

Originally I wasn't planning to make a website, instead I just wrote the script to generate a few hundred different wallpapers, copied them onto my iPad, and used those as a randomised wallpaper. It was only after I had fun trying to guess where each wallpaper was that I decided to make a map of the day.

I needed to refactor the code so that instead of generating many different images, I could generate many different crops and scales, all focussing on the same point. I wanted there to be a wallpaper download in the exact right size for different devices, all focussed on the same centre point, without one size just being a crop of the middle of another. For example, a 16:9 laptop wallpaper shouldn't just be the middle bit of a 9:16 phone wallpaper. They should both be cut from a square 16:16 image, so that they both have a shared area in the centre, with the phone showing additional vertical detail, and the laptop showing additional horizontal detail.

This required more image-coordinate calculations, which of course I refused to learn my lesson from and attempted to implement off the cuff.

Making the website is where I decided things weren't complicated enough. You see, I spend my workday making technical decisions to ensure the codebase remains understandable, maintainable, and reliable. When I'm working on a personal project, I don't want to make those same decisions.

The obvious thing to do here would be to implement the website in Python. After generating some images, you use some static site generator library to build some HTML and dump all of that into a folder so your web server can pick it up. You schedule the generation using `cron`. There are few moving parts and everything is easy to develop and debug.

This is not what I did.

Instead I wrote a persistent server in Crystal that runs the Python program as a subprocess. It passes all the parameters for how to generate the images in as command-line arguments—encoded in JSON. Once the wallpapers are generated, it writes a metadata file that tells the Crystal program about the images that have been generated, and then the Crystal program uses [ECR][ecr] templating to build the website, with a very basic (custom) static site generator sitting on top.

[ecr]: https://crystal-lang.org/api/latest/ECR.html

This does have a very small list of advantages: the server runs my [status page library][status-page] so I can look at the logs and suchlike from my phone, and has an endpoint to re-generate the image for a particular day in case I run into a poorly-merged tile.

[status-page]: https://codeberg.org/willhbr/status_page

The biggest disadvantage in terms of development is that I didn't spend the time to build a single container image that included both the Python dependencies _and_ a Crystal compiler. Instead I would work on the generator using a Python-based image, then work on the website using a Crystal image, then test them together by building a release image using a multi-step containerfile that copied the compiled Crystal program into the Python image.

I didn't do anything particularly complicated for the website, it shows off the map prominently at the top, with download links for each wallpaper size. I spent a little extra effort to make the background of the page match the most prominent colour in the map, and of course generating RSS and JSON Feeds.

While reading [how Wesley Moore created a CDN][wezm-cdn] for his [link blog](https://linkedlist.org/), I learnt that [RackNerd](https://racknerd.com/)'s lowest-end VPS was actually pretty decent. 1 CPU core, 1GB of RAM, and 20GB of SSD. In my mind that would be the specs on a $5/month plan, but after taxes and currency conversion I ended up paying just AU$20 for a whole year.

[wezm-cdn]: https://www.wezm.net/v2/posts/2024/tiny-cdn/

I was planning on doing a [more involved deployment][alpine-server], but instead I got distracted one evening and haphazardly setup the whole thing. The standard OS images from RackNerd are quite old. The Ubuntu image is 22.04, which I guess isn't _that_ big of an issue, except that I want to run a somewhat-recent version of Podman, so I did a couple of `do-release-upgrade` to get onto 24.10 and Podman 5.0. After a bit of faff I setup podman-remote, and [Caddy](http://caddyserver.com) as a static file server.

[alpine-server]:/2025/03/09/a-slim-home-server-with-alpine-linux/

It's a long time since I've [used nginx](/2016/03/03/why-i-use-nginx/), but Caddy really makes life even easier. All I needed to get a file server working with SSL is:

```conf
topomap.willhbr.net {
  root * /data/http
  file_server
}
```

The final configuration is a little more complicated, as I want to set some reasonably aggressive caching, enable compression, and enable access logs for my own curiosity:

```conf
topomap.willhbr.net {
  root * /data/http
  encode zstd gzip

  @static {
    file
    path *.css *.png *.webp *.ico
  }
  header @static Cache-Control max-age=604800

  @html {
    file
    path *.html *.xml *.json
  }
  header @html Cache-Control max-age=600

  file_server

  log {
    output file /var/log/caddy/access.log
  }
}
```

The config is fairly easy to read, but a bit annoying to write. I don't really have a good understanding of the structure of the file, for example I assume the `@static` is defining some kind of match block, could I put that inline into the `header` statement? I don't know. Thankfully there are plenty of examples to choose from and the options that I'm setting are quick and easy to verify.

To deploy the actual map generation, I'm using my container-management tool, [`pod`](https://pod.willhbr.net). I just define the config in the `pods.yaml` file, run `pod build prod` to get the production image—with both the compiled Crystal binary and Python dependencies—then `pod update` to stop the old container and replace it with one running the new image.

I did run into one wrinkle with this approach. Up until now all the containers I've been deploying have run on my home servers, which have access to a container registry running locally. All the images get pushed to the registry, and any server can just pull the new version from the registry. I didn't want the VPS to have access back into my home network, so it couldn't pull from the registry.

Thankfully there is a really simple workaround for this in Podman, which was very easy to add into Pod: `podman image scp`. It does exactly what you expect: it copies a local image to a remote server, either using SFTP or podman-remote—I don't know which. So instead of pushing to the registry and then pulling from the server, I can push directly from my development machine to the server with `podman image scp localhost/topo:prod-latest badger::`. After I added this into Pod it was as simple as running `pod push`.

To be honest, for my use cases this is much more convenient than running a registry. I might just add some smarts to `pod update` so that it can push local images to the remote servers and remove the need for having a registry at all.

Of course the code isn't very useful without the source topomaps to pull from. I used `scp` to copy the 10G zip file onto the VPS and then realised that I didn't have enough disk space to decompress it, so instead I used `rsync` to copy the decompressed images. The images take up most of the disk space, so I spent some time experimenting with different filetypes to see if I could claw back some space.

JPEG-XL was promising, it saves up to 50% on the smaller images and around 15% on the largest. However, Pillow doesn't support opening them so I had to convert them on the fly back to regular JPEGs.

WebP actually gave me better compression: 75% less on the smallest files, and 20% less on the largest, and it's supported by Pillow. However my program will naively check the size of every image when it loads them[^unneeded-size], and for whatever reason getting the size of a WebP image is slower than getting the size of a JPEG. I decided to just accept the disk usage and go back to JPEGs. JPEGs work well.

[^unneeded-size]: It doesn't _strictly_ need this as I no longer need to know the bounds now that I'm just looking at the root coordinate for each image, rather than the area it covers.

Something that I couldn't get working to my satisfaction was an automatic dark mode. I tried exporting a LUT that would do a value-invert—flipping the colours based on their brightness, rather than their RGB values—as well as some other adjustments, but it doesn't quite look right. This is because as well as having contours, the maps have subtle shading on the hills, and inverting the brightness flips the shading. I'm not sure if there's a really robust solution here, it's not as simple as just replacing each colour that appears in the legend, as you've got to handle the tiny gradients between any pair of colours as well or else you'll get artefacts.

What excites me the most about this project is the realisation that you can get good hosting for a low annual price. In my mind the cheapest somewhat-usable VPS was US$5 per month, which ends up with you paying closer to AU$10 per month. This isn't exactly expensive, but it's a notable recurring cost. Paying $20 up front for a whole year basically makes the server feel free, and I now need to find some other things to use it for.

You can follow the daily topomap [on the website][topomap], via [RSS](https://topomap.willhbr.net/feed.xml), [JSON Feed](https://topomap.willhbr.net/feed.json), or via [Mastodon](https://mastodon.social/@nz_topomap).

[topomap]: https://topomap.willhbr.net
