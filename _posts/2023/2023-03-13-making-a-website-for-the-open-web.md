---
title: "Making a Website for the Open Web"
---

The open web is complicated[^citation-needed]. Over the last few months I've been trying to make [my website]({{ site.url }}) work with as many standards as I could find. I couldn't find a guide on all the things you should do, so I wrote down all the things I've done to make my website integrate better with the open web:

[^citation-needed]: Citation needed.

# Accessibility

Running an accessibility checker on your website is a good start. I used [accessibilitychecker.org](https://www.accessibilitychecker.org), which can automatically detect some low-hanging improvements.

The easiest thing was setting the language on the root tag on the website, so that browsers and crawlers know what language the content will be in:

```html
<!DOCTYPE html>
<html lang="en">
```

Since I'm still young[^citation-needed], I don't have much trouble reading low-contrast text, I didn't notice how close in brightness some of the colours that I had picked were. I initially used [coolors.co](https://coolors.co/contrast-checker)'s tool, but then ended up using the accessibility checking devtools in Firefox to ensure that everything was within the recommended range.

> This was the colour that I had been using for the titles and links in dark mode. It's not very readable on the dark background.
{: style="color:#c972ff;background:#333"}

> This is the new colour that I changed it to, which has much better contrast.
{: style="color:#D4B3FF;background:#333"}

# Add Feeds

I already had an [RSS Feed](https://en.wikipedia.org/wiki/RSS) and a [JSON Feed](http://jsonfeed.org) setup, but I double checked that it was giving the correct format using the [w3 RSS Validator](https://validator.w3.org/feed/) and the [JSON Feed validator](https://validator.jsonfeed.org).

What I had missed adding was the correct metadata that allows browsers and feed readers to get the URL of the feed from any page. If someone wants to subscribe to your feed, they don't have to find the URL themselves and add that, they can just type in your homepage and any good reader will work it out for them. This is just a single HTML tag in your `<head>`:

```html
<link rel="alternate" type="application/rss+xml"
  title="Will Richardson"
  href="https://willhbr.net/feed.xml" />
```

> JSON Feed didn't take the world by storm and replace XML-based RSS, but it is nice having it there so I can get the contents of my posts programatically without dealing with XML. For example I've got a Shortcut that will toot my latest post, which fetches the JSON feed instead of the RSS.

# OpenGraph Previews

I [wrote about this](https://willhbr.net/2023/02/04/adding-opengraph-previews-to-jekyll/) when I added them, since I was so stoked to have proper previews when sharing links.

My assumption had always been that services just fetched the URL and guessed at what image should be included in the preview (I guess this is what Facebook did before publishing the standard?).

Sites like Github really take advantage of this and generate a preview image with stats for the state of the repo that's being shared:

![An OpenGraph image from Github, showing the stats for this repo](https://opengraph.githubassets.com/a4015b6689c0f7fb5165ee87dc844b747950f1797f2be54232113e3b8a2684b6/willhbr/willhbr.github.io)

# Dark Mode

Your website should respect the system dark-mode setting, which you can get in CSS using an `@media` query:

```css
@media(prefers-color-scheme: dark) {
  /* some dark-mode-specific styling */
}
```

This is fairly easy to support - just override the colours with dark-mode variants - but it gets more complicated if you want to allow visitors to toggle light/dark mode (some may want to have their OS in one mode but read _your_ site in a the other).

I won't go into the full details of how I implemented this, but it boils down to having the `@media` query, a class on the `<body>` tag, _and_ using CSS variables to define colours. Look at [`main.js`](https://github.com/willhbr/willhbr.github.io/blob/main/js/main.js) and [`darkmode.sass`](https://github.com/willhbr/willhbr.github.io/blob/main/_sass/darkmode.sass) for how I did it.

# Alias Your Domain to Your ActivityPub Profile

[Something else I wrote about earlier](https://willhbr.net/2023/01/24/webfinger-mastodon-alias/). Not something that I think everyone needs to do, but if you like the idea of a computer being able to find your toots from your own domain, it's probably worth doing. Especially because it's quite straightforward.

# Good Favicons

Back in my day you'd just put `favicon.ico` at the root of your website and that would be it. Things are a little more advanced now, and support a few more pixels. I used [this website](https://favicon.io/favicon-converter/) to turn my high-res image into all the correct formats. It also conveniently gives you the right HTML to include too.

# Add `robots.txt`

I added a [`robots.txt`](http://www.robotstxt.org) file that just tells crawlers that they're allowed to go anywhere on my site. It's entirely static, any nothing is intended to be hidden from search engines.

---

If I've missed a standard that belongs on my website, please [toot me]({{ site.urls.mastodon }})!
