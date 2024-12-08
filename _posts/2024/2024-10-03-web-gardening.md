---
title: "Web Gardening"
image: /images/2024/new-website.webp
tags: web
---

Just over four months ago—in [a post celebrating the 10th birthday of my website](/2024/05/05/happy-birthday-to-website/)—I wrote:

> What will the site look like in another ten years? Have I reached the optimal design, or has drudging through ten years of website screenshots inspired a proper redesign? Wait until 2034 to find out!

And it turns out you won't need to wait until 2034, because we've got a redesign right now! If you're reading this in a feed reader, break out of the confines of your client's default styling and [read this post on the web][this-post]!

[this-post]: /2024/10/03/web-gardening/

![A screenshot of my previous design, from May](/images/2024/website-2024-05-05.webp)

In case you forgot, this is what my site used to look like.
{:class="caption"}

# New Header

The most obvious new feature is the big purple header:

![The new website](/images/2024/new-website.webp)

I'd been thinking about a new design basically since I made that comment at the end of the 10th birthday post. No ideas really stuck. I played around with the most minor of changes—putting the navigation links to the side of the site title—and then thought that maybe the header could be designed as a block that dropped down from the accent strip at the top. I quickly realised that this would look terrible, but realised that on a sufficiently small screen, it would take up the full width—why not just do that for all screens?[^especially-mobile]

[^especially-mobile]: Especially since most visitors are probably on phones anyway.

That ended up looking pretty good, and made me happy with both the light and dark themes for the site (whereas before the light theme just didn't really hit the spot). The big colourful header makes the site stand out a little more, and hopefully makes it a bit more memorable than the previous mostly-grey or mostly-white design. I did tweak the dark mode colours to be a little more vibrant (the lavender is a little more saturated, the grey background is much darker) which I think better matches the feel of the light mode colours.

# No JavaScript

Previously the main use of JavaScript was to provide an override to the theme, so that you could have my site in dark mode while your device was in light mode, or vice-versa. The control for this was somewhat unceremoniously plonked in the upper-right corner. With the new header design it stood out much more, and I made the decision that providing the toggle wasn't worth the effort of finding a home for the button, or having every visitor make an additional HTTP request to fetch the JavaScript file.

# Web Fonts

After shunning the idea of web fonts earlier this year, I experimented with using web fonts and liked the look more than I disliked the amount of extra content that has to be downloaded. I hadn't realised before this that you needed to have a separate font file for regular, italic, bold, and bold italic, each costing around 20kB and a separate network request. I'm currently committing the [type crime](https://ellenlupton.com/Thinking-with-Type) of allowing the browser to create a fake bold font instead of providing one myself, since bold text isn't crucial to my site.

The fonts I settled on were [DIN](https://en.wikipedia.org/wiki/DIN_1451) and [IBM Plex Sans](https://www.ibm.com/plex/). DIN—for titles—is very similar to what I was using before, which was either _DIN Alternate_ or [_Bahnschrift_](https://learn.microsoft.com/en-us/typography/font-list/bahnschrift) depending on the platform. DIN is slightly tighter leading than either of those two, which I liked enough that I couldn't go back. I remember when I first changed to using DIN Alternate and Bahnschrift I was sure that I was only a fan of the fact that I'd changed something, rather than the look of the fonts themselves. Well however much time later, and I think I quite like it.

I took a bunch of inspiration from [_Pixel Envy_](http://pxlnv.com) while re-thinking some of the design, the most visible being the use of Plex Sans. It's just distinct enough that you might notice it, but definitely not out-there enough to make things a pain to read.

A really useful resource for doing web typography is [this blog post](https://sinja.io/blog/web-typography-quick-guide) which touches on a much of things to consider. It also introduced me to [Modern Font Stacks](https://modernfontstacks.com/), which includes `font-family` declarations to get similar-looking fonts across different platforms for a variety of different font styles. If I hadn't ended up using web fonts, I would have picked a set of fonts from here.

This is where I learnt about [`text-wrap: balance`](https://sinja.io/blog/web-typography-quick-guide#text-wrapping) which makes your titles look better by soft-wrapping pre-emptively instead of filling the entire width first.

Another interesting post was [this one](https://sia.codes/posts/making-google-fonts-faster/) about web font performance, which explains what Google Fonts is _actually_ doing when you use the single-line include, and how that can impact the load time on your website. I've tried to make my fonts as fast to load as possible by adding a `preload` for each in the HTML, so that by the time the browser has loaded the CSS it should already be well on its way to downloading the fonts.

# Needless Optimisation

In order to justify the increased initial download size from adding web fonts, I tried to optimise the rest of the site to be as small as possible. The biggest optimisation was to move the paginated list of posts off the front page. Instead of putting 10 posts on the homepage, there's only one. This cuts the size of the HTML file from >300kB to ~25kB.

Another optimisation that I did—but didn't end up mattering—was inlining duplicate SASS styles. I had assumed that this was done automatically, but it isn't (at least not in the version of Ruby-SASS that Jekyll on GitHub Pages uses). So if you have a SASS file with two rules containing the same styles:

```sass
h1
  font-family: DIN, "DIN Alternate", Bahnschrift, sans-serif
  text-align: center
  color: tomato
h2
  font-family: DIN, "DIN Alternate", Bahnschrift, sans-serif
  text-align: center
  color: tomato
```

The resulting CSS file is a one-to-one syntactic conversion:

```css
h1 {
  font-family: DIN, "DIN Alternate", Bahnschrift, sans-serif;
  text-align: center;
  color: tomato;
}

h2 {
  font-family: DIN, "DIN Alternate", Bahnschrift, sans-serif;
  text-align: center;
  color: tomato;
}
```

So all the styles are pointlessly duplicated—or at least they are in simple cases like this, I don't know if SASS could guarantee that merging the two rules into one would always result in the same behaviour. In this case though, you can inline them into a single rule, and avoid repeating the bodies twice:

```css
h1, h2 {
  font-family: DIN, "DIN Alternate", Bahnschrift, sans-serif;
  text-align: center;
  color: tomato;
}
```

In my case the styles for the syntax highlighting included many duplicates, since there are many different token types, each with their own rule, and only a handful of colours that are applied to them. By replacing rules like this:

```sass
.ne
  color: #ffb964
.nf
  color: #fad07a
.nl
  color: #ffb964
.nn
  color: #e8e8d3
.nx
  color: #e8e8d3
.py
  color: #e8e8d3
```

With rules like this:

```sass
.ne, .nl
  color: #ffb964
.nf
  color: #fad07a
.nn, .nx, .py
  color: #e8e8d3
```

I saved a whole kilobyte of CSS. Although that is before compression, so the actual gain of minimising data transferred over the network would be much smaller. And then of course I decided to make my own highlighting theme, which made this whole exercise pointless.

# Syntax Highlighting

For the longest time I had just used the [Pygments](https://pygments.org) [_Railscasts_](http://railscasts.com/about) theme, which didn't really fit in with the rest of the site, and would always be set on a dark background. I'd thought about finding another theme to use in light-mode, but never got around to it.

Instead, I bit the bullet and committed to making my own (very simple) theme that used the site's purple highlight colour as a base. I then hue-shifted that same colour to get a green (for strings), blue (for keywords) and orange (for literals). I've tried to make syntax highlighting themes before and every time I get a newfound appreciation for anyone that makes a well thought-out theme that works with many different languages (like my long-time fave theme [dogrun](https://github.com/wadackel/vim-dogrun)).

Initially my process was to assign colours based on [the token types from Rouge](https://github.com/rouge-ruby/rouge/wiki/List-of-tokens) but later ended up just making a markdown file with the languages I might include in a post[^languages], and tweaking the theme until they all looked reasonable.

[^languages]: So far that's Bash, Clojure, "conf" (for tmux config files), Console (for shell sessions), C++, Crystal, CSS, Docker, Elixir, ERB, Go, Haskell, HTML, Java, JavaScript, JSON, Kotlin, Markdown, Python, Ruby, Rust, Shell, SQL, Swift, TOML, and YAML.

# Front Page Design

The decision to shrink the size of the front page meant that I needed (or wanted) to have some way of showing some older posts on the homepage. My theory is that someone might come to visit my site, see one post and not be interested, and then leave. If I put a few titles of posts at the bottom, then maybe they'll find what they're looking for. Of course this is assuming anyone visits my site in the first place.

I wanted to keep the paginated full-text posts on the off chance that someone wants to skim-peruse the back catalog. If I come across a new blog I like to be able to scroll as much as possible, instead of having to click-click-click between different pages. The difficult decision here is deciding when to link to the archive versus linking to the paginated list of posts. I imagine I'll end up tweaking this in the future.

Something I did to make this slightly more seamless is to add pagination controls to the front page, so it appears as a very short page with one post on it, followed by many pages with 10 posts each. This created a second problem that the first proper paginated page would include the post from the front page, so you could read the first post, then click to view the next page, and appear as though you've not moved. To avoid this, I never show the first post in the pagination—so the first page will actually have 9 posts.

The older Jekyll version used by GitHub Pages uses the also-old `jekyll-paginate` plugin (instead of the newer `jekyll-paginate-v2`). This is accessed with the `paginator` object, but I discovered that this is only available on the page that is going to be paginated, not on any other pages. Since my front page isn't paginated (there's a separate page for the paginated content) I couldn't include the same pagination layout on the front page. Instead, I created a separate layout that does some hacks to approximate the same information. It can be a bit simpler since it'll always be focussed on the "home" page, and it can just use the total post count to count the number of page links to create.

# Permalinks and URL Formats

Something I considered was changing my URL format. Currently this is `/YYYY/MM/DD/:title` (the default Jekyll "pretty" URL style), but since I don't post multiple times per day (especially with the same title) the format is overly verbose. I could just use `/:title` since my titles are (so far) unique, but I like indicating the approximate age of the post in the URL. `/YYYY/:title` was tempting, but in the end I decided that changing URLs was too big a change for not that much benefit. Especially since I'd have to ensure that all the existing posts maintained their existing links.

---

I've seen a [bunch](https://blog.jim-nielsen.com/2024/person-in-personal-website/) [of](https://www.citationneeded.news/posse/) [posts](https://manuelmoreale.com/@/page/acx1bK7UldiQW556) come across my RSS inbox about making personal websites _personal_ and accepting that they're not necessarily going to be flawless, and showing some character is part of the point. I started to think of my website (and also my [shell config](https://github.com/willhbr/dotfiles)) like gardening. It'll never be finished, there's always something to move or tweak or move back, it's in a state of constant refinement. Unlike real gardening I can leave it untouched and know that it won't get worse.
