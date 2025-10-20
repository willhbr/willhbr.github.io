---
title: "Light Mode InFFFFFFlation"
image: /images/2025/macos-light-mode.webp
tags: design opinion
---

Back in the day, light mode wasn't called "light mode". It was just the way that computers were, we didn't really think about turning everything light or dark. Sure, some applications were often dark (photo editors, IDEs, terminals) but everything else was light, and that was fine.

What we didn't notice is that light mode has been slowly getting lighter, and I've got a graph to prove it. I did what any normal person would do, I downloaded the same (or similar) screenshots from the [MacOS Screenshot Library](https://512pixels.net/projects/aqua-screenshot-library/) on [_512 Pixels_](https://512pixels.net/). This project would have been much more difficult without a single place to get well-organised screenshots from. I cropped each image so just a representative section of the window was present, here shown with a pinkish rectangle:

![screenshot of OS X Snow Leopard Finder window with toolbar section highlighted](/images/2025/macos-light-mode.webp)

Then used [Pillow](https://pypi.org/project/pillow/) to get the average lightness of each cropped image:

```python
for file in sorted(os.listdir('.')):
  image = Image.open(file)
  greyscale = image.convert('L')
  stat = ImageStat.Stat(greyscale)
  avg_lightness = int(stat.mean[0])
  print(f"{file}\t{avg_lightness}")
```

This ignores any kind of perceived brightness or the tinting that MacOS has been doing for a while based on your wallpaper colour. I could go down a massive tangent trying to work out exactly what the best way to measure this is, but given that the screenshots aren't perfectly comparable between versions, comparing the average brightness of a greyscale image seems reasonable.

I graphed that on the release year of each OS version, doing the same for dark mode:

<svg viewBox="0 -5 365 290" xmlns="http://www.w3.org/2000/svg">
  <style>
    polyline { fill: none; }
    polyline, line { stroke-width: 3px; stroke-linecap: round; }
    text { font-family: "system-ui"; fill: var(--tec); }
  </style>
  <defs>
    <linearGradient id="gradient" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0%" stop-color="white"  />
      <stop offset="100%" stop-color="black"  />
    </linearGradient>
  </defs>
  <rect id="rect1" x="0" y="0" rx=3 ry=3 width="320" height="255" fill="url(#gradient)" />
  <polyline style="stroke: {{ site.theme_colour.light }}" points="
    0,74
    40,58
    60,61
    80,53
    100,25
    120,24
    140,24
    160,24
    180,33
    200,33
    220,6
    240,6
    260,3
    280,10
    300,11
    320,0"></polyline>
  <polyline style="stroke: {{ site.theme_colour.dark }}" points="
      180,202
      200,197
      220,200
      240,199
      260,210
      280,215
      300,200
      320,215"></polyline>
  <text x="0" y="270" textLength="40">2009</text>
  <text x="280" y="270" textLength="40">2025</text>
  <text x="325" y="10" textLength="40">100%</text>
  <text x="325" y="255">0%</text>
</svg>

This graph is an SVG, which may not render correctly in feed readers. [View this post on the web](/2025/10/20/light-mode-infffffflation/).
{:class="caption"}

You can clearly see that the brightness of the UI has been steadily increasing for the last 16 years. The upper line is the default mode/light mode, the lower line is dark mode. When I started using MacOS in 2012, I was running Snow Leopard, the windows had an average brightness of 71%. Since then they've steadily increased so that in MacOS Tahoe, they're at a full 100%.

What I've graphed here is just the brightness of the window chrome, which isn't really representative of the actual total screen brightness. A better study would be looking at the overall brightness of a typical set of apps. The default background colour for windows, as well as the colours for inactive windows, would probably give a more complete picture.

For example, [in Tahoe](https://512pixels.net/projects/aqua-screenshot-library/macos-26-tahoe/) the darkest colour in a typical light-mode window is the colour of a section in an inactive settings window, at 97% brightness. In Snow Leopard the equivalent colour was 90%, and that was one of the _brightest_ parts of the window, since the window chrome was typically darker than the window content.

I tried to remember exactly when I started using dark mode all the time on MacOS. I've always used a dark background for my editor and terminal, but I wasn't sure when I swapped the system theme across. When it first came out I seem to remember thinking that it looked gross.

It obviously couldn't be earlier than 2018, as that's when dark mode was introduced in [MacOS Mojave](https://en.wikipedia.org/wiki/MacOS_Mojave). I'm pretty sure that when I updated my personal laptop to an M1 MacBook Air at the end of 2020 that I set it to use dark mode. This would make sense, because the [Big Sur](https://en.wikipedia.org/wiki/MacOS_Big_Sur) update bumped the brightness from 85% to 97%, which probably pushed me over the edge.

I think the reason this happens is that if you look at two designs, photos, or whatever, it's really easy to be drawn in to liking the brighter one more. Or if they're predominantly dark, then the darker one. I've done it myself with this very site. If I'm tweaking the colours it's easy to bump up the brightness on the background and go "ooh wow yeah that's definitely cleaner", then swap it back and go "ewww it looks like it needs a good scrub". If it's the dark mode colours, then a darker background will just look _cooler_.

I'm not a designer, but I assume that resisting this urge is something you learn in design school. Just like making a website look good with a non-greyscale background.

This year in iOS 26, some UI elements use the HDR screen to make some elements and highlights brighter than 100% white.[^not-me] This year it's reasonably subtle, but the inflation potential is there. If you've ever looked at an HDR photo on an iPhone (or any other HDR screen) then looked at the UI that's still being shown in SDR, you'll know just how grey and sad it looks. If you're designing a new UI, how tempting will it be to make just a little bit more of it just a little bit brighter?

[^not-me]: I'm still happily on iOS 18 so I've not used this myself.

As someone whose job involves looking at MacOS for a lot of the day, I find that I basically _have_ to use dark mode to avoid looking at a display where all the system UI is 100% white blasting in my eyes. But the alternative doesn't have to be near-black for that, I would happily have a UI that's a medium grey. In fact what I've missed since swapping to using dark mode is that I don't have contrast between windows. Everything looks the same, whether it's a text editor, IDE, terminal, web browser, or Finder window. All black, all the time.

Somewhat in the spirit of [Mavericks Forever](https://mavericksforever.com)[^popup-on-scroll], if I were to pick an old MacOS design to go back to it would probably be [Yosemite](https://512pixels.net/projects/aqua-screenshot-library/os-x-10-10-yosemite/). I don't have any nostalgia for skeuomorphic brushed metal or stitched leather, but I do quite like the flattened design and blur effects that Yosemite brought. Ironically Yosemite was a substantial jump in brightness from previous versions.

[^popup-on-scroll]: Whoever came up with the design trend where each block on a webpage pops up into view after you scroll past it needs to pay for their crimes.

So if you're making an interface or website, be bold and choose a 50% grey. My eyes will thank you.
