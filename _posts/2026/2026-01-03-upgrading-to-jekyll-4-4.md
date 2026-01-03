---
title: "Upgrading to Jekyll 4.4"
tags: web
---

This all started as I was getting confused about [how syntax highlighting broke](/2025/12/24/my-website-broke-and-you-wont-believe-why/) on my website, and my confusion as to what GitHub could have possibly done to break it. As it turns out they didn't do anything, but the idea of moving to an [actions-based website][gh-pages-actions] seemed less daunting.

[gh-pages-actions]: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages

Originally GitHub Pages only supported one way of building a website, which was with Jekyll and a fixed set of plugins. You couldn't write any custom code (apart from in Liquid templates) or depend on additional gems. Later they added support for building the website from [GitHub Actions](https://github.com/features/actions), allowing the use of custom code, dependencies, or even swapping out Jekyll entirely.

I had been keeping a list of all things I _could_ do if I moved to using a custom build instead of the default Pages setup. I only wanted to move if I had reasons to actually justify doing it, rather than just complicating the deployment for no real benefit. This list was getting to a reasonable length, so I started to consider taking the plunge.

The thing is that [GitHub Actions feels bad](https://www.youtube.com/watch?v=9qljpi5jiMQ). Setting it up correctly and keeping it working just seemed like a lot of effort, whereas the previous branch-based setup had already been working for me for literally a decade. Sure there are some hiccups, but it doesn't require any extra YAML files.

So instead I setup a mirror of my website on GitLab Pages. GitLab CI is much easier to setup, the most basic config can just be "use this docker image, and run this command". You then just put `pages: true` on an action that writes to `public/` and you're done.

Here's the whole config:

```yaml
create-pages:
  image: ruby:3.4
  script:
    - gem install bundler
    - bundle install
    - bundle exec jekyll build -d public
  pages: true
  only:
    - main
```

It's a little more complicated if you want to cache the result of `bundle install` to save time, but what I really love about this is I can see exactly what's going to happen. If there's some problem, I can just pull `ruby:3.4`, run a new container with my website in it, then run the commands in the `script` section.

Jumping ahead a little, I did end up configuring GitHub Pages, but the config is much longer, it has to configure permissions, you need a special action to actually get your code, as well as two more actions to setup and deploy to Pages.

Interestingly while the basic setup is simpler, GitLab doesn't auto-compress your files like GitHub does. You have to manually create `.gz` versions of each file to have them be served with gzip compression. This is a little inconvenient, but they do support serving other compression schemes like [Brotli](https://brotli.org):

```shell
find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec gzip -f -k {} \;
find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec brotli -f -k {} \;
```

Brotli cuts 1kB off the homepage of my website (4.8kB versus 5.9kB) which is a nice improvement, so all in all I'd accept this slight increase in complexity for smaller response sizes. GitHub is limited to whatever they decide to serve, which currently is just gzip applied automatically where they see fit.

So I had a copy of my website on GitLab Pages working with compression and everything on an auto-generated `gitlab.io` domain. Everything worked, but you can tell just by looking at it that it's slower to load. I'm very used to my website loading almost instantly because I pointlessly code golf down the size of the HTML and CSS to be as small as possible. I sent a link to a friend who I assume doesn't check my site as obsessively as I do, and asked "what's the performance like?" Their immediate response was they thought it was just a bit slower than my actual site.

Right now if I look at the timing in the web inspector, the increase in load time is entirely in the browser waiting for the server to start sending the actual data. Getting the SSL connection is 300ms versus 19ms, then waiting for the response is 500ms versus 8ms. Downloading the actual data from both is 0.1ms. Time to first byte is 817ms versus 32ms.

Doing a bit of a `traceroute` seems to indicate that GitLab is getting served from somewhere in Missouri, whereas the GitHub response headers include `x-served-by: cache-syd10177-SYD` so my request probably isn't going further than 50km.

I also used the [Pingdom website speed test][pingdom] which is probably a bit more scientific than doing random requests from my laptop, and it shows a similar story: GitHub spends almost no time (13ms) establishing the SSL connection, whereas GitLab takes 700ms. Moving the request source from Sydney to San Francisco cuts this down to 300ms, so I'm definitely paying a tax for being on the wrong side of the globe.

It's fun to see that all the responses are smaller because of the Brotli encoding on the GitLab version, but if you're spending 700ms initialising the connection that doesn't really matter.

[pingdom]: https://tools.pingdom.com

Probably the only thing that would make me use GitLab Pages would be the ability to configure cache expiration. Both hosts set a default `Cache-Control: max-age=600` header to cache the response for 10 minutes, but for web fonts, CSS, and my tiny JS file, it would be great to set this to be much longer.

So it seemed like the best option was to stick with GitHub. I know there are plenty of other static site hosts, but I didn't really set out to do an exhaustive comparison. Adding a different service would likely complicate my build process even more, and the whole reason I started looking at GitLab was that their CI is so much simpler than GitHub's.

I rolled up my sleeves and flailed around with GitHub Actions YAML until I had a working site. I actually made a new repository so I could just commit and push over and over until it worked, then squash it all down into one perfect commit and push that to my actual repo, saving my git history.

The jump from Jekyll 3.10 to 4.4 (and updating all the other dependencies at the same time as well) did expose some issues.

Either [Rouge][rouge] (syntax highlighter) or [Kramdown][kramdown] (markdown processor) have stopped adding a `highlighter-rouge` wrapper `div` around code blocks with no highlighting. I was using this in my CSS, and so any non-highlighted code blocks didn't get styled correctly. This actually ended up being quite convenient, as it forced me to delete and re-write my CSS with respect to `<pre>` and `<code>`, resulting in simpler rules.

[rouge]: https://rouge.jneen.net/
[kramdown]: https://kramdown.gettalong.org/

Kramdown also changed the HTML generated for footnote links, so they no longer have `role="doc-noteref"`. I was using this for styling and all my footnotes jumped back up to being superscripts. This was another easy fix, just change the CSS selector to be `sup:has(.footnote)`.

With the new Sass version, I started getting a lot of deprecation warnings for `lighten()`, `darken()`, `change-color()`, and `@import`. The colour adjustments could just be rewritten to use `color.change()` and `color.adjust()`. Correcting the imports turned out to be trickier, as I'd just split the file somewhat arbitrarily and this didn't really fit with how Sass wanted imports to work. Instead of working out how rules, variable declarations, and functions should be separated, I just put everything into one file. Maybe I'll work something smarter out in the future, but for now it works with no warnings.

So after all that I had a website that looked and worked just like it did before. Thankfully I had my list of improvements I could make, and now there was nothing to stop me.

The first thing I did was write a [custom Jekyll converter that uses a custom Kramdown converter][markdown-converter] to always add `loading="lazy"` to `<img>` tags. I'd been doing this manually by tacking `{:loading="lazy"}` onto the end of every markdown image, but now it'll just happen by default.

[markdown-converter]: https://github.com/willhbr/willhbr.github.io/blob/76efea5f89aba57914d8f34afc0e383c5df2bd23/_plugins/markdown.rb

Next I removed the liquid template that I used to get [more accurate publication times][jekyll-times] for my latest post. Now it is just [a custom Liquid filter][smart-date], so I just have to write `post.date | smart_date | date: site.date_format` instead of including and capturing a template.

[smart-date]: https://github.com/willhbr/willhbr.github.io/blob/76efea5f89aba57914d8f34afc0e383c5df2bd23/_plugins/filters.rb#L2
[jekyll-times]: /2024/07/18/lazy-jekyll-hacks-for-more-accurate-publication-times/

The next thing is slightly cursed. In both the JSON and RSS feeds any code block has the HTML markup to be syntax highlighted, but feed readers don't have the CSS and so they'll always render it without styling. Including it in the feeds is a pure waste of bytes, but there's no great way in Jekyll to render posts differently depending on where they're being included. Instead I wrote [another filter][strip_highlighting] that will [use a regex to parse the HTML][html-regex] and strip any `<span>` tags from within `<code>` blocks. Obviously it depends on how much code is in the post, but this cut down the size of the RSS feed by 82kB. And you know how I feel about code golfing the size of my pages.[^golf-styles]

[^golf-styles]: I just had a thought that I could use this same thing to strip out any `<span>` with a class that I don't actually apply a style for. Actually I could include that directly in the custom markdown processor. You see, this is the kind of rabbit hole I was concerned about.

[html-regex]: https://stackoverflow.com/a/1732454/692410
[strip_highlighting]: https://github.com/willhbr/willhbr.github.io/blob/76efea5f89aba57914d8f34afc0e383c5df2bd23/_plugins/filters.rb#L11

A minor fix I made is the character used in the footnote backlinks—the link in the footnote text at the bottom of the post that jumps back up to where the footnote is referenced. The default character is &#8617; (`#8617`, LEFTWARDS ARROW WITH HOOK), which renders differently on iOS versus MacOS. On MacOS it's similar to other HTML arrows and renders like a letter, like this: &#8617;&#xFE0E;. On iOS it renders like a colour emoji, a blue shaded box with a white arrow in it, similar to 🆒.

This has always bugged me. I have no idea why there's this inconsistency, the emoji character looks out of place. I went to see where in Kramdown I needed to make a change to get a different character, and to my surprise I found out there's already a feature to replace the character—I could have had a different one all along. I chose to swap it to &uarr;, which I like more as a "jump up to where this was mentioned" link.

There's actually some interesting discussion on the [feature request](https://github.com/gettalong/kramdown/issues/247) in Kramdown. You can actually just add another code point afterwards and force it to display in the text mode, but I'm not particularly attached to that character and will stick with the up arrow.

Now we get to bigger changes. Up until now the way to view posts with a particular tag is to [go to the tags page](/tags/) and scroll to find the right tag. This is _fine_, but not particularly nice. Now that I have unlimited power, I can write a [custom generator][generator] that creates a new page for each tag that's been defined. Now there's a dedicated page for each tag which gives me a little more room to group the posts by year instead of just in one big list.

[generator]: https://github.com/willhbr/willhbr.github.io/blob/76efea5f89aba57914d8f34afc0e383c5df2bd23/_plugins/generator.rb

Probably the biggest change is adding a list of related posts to the footer of each post. Previously I just had links for the next and previous post. I don't even know why I had those links, it must have been in the Jekyll example template or somewhere in the documentation. However since I'm not writing a series it's not really that important to specifically go to the next or previous entry.

Instead I've [written some logic in a filter][related_posts] that gives me a certain number of relevant posts to include. Right now this will be posts that share any tags with the current post. I didn't want to completely throw out the next/previous links, so the related posts list will always include those as well. This gives it a little more variety, and any posts without tags will still get two links at the bottom.

[related_posts]: https://github.com/willhbr/willhbr.github.io/blob/76efea5f89aba57914d8f34afc0e383c5df2bd23/_plugins/filters.rb#L17

The obvious other thing to do would be to use third-party plugins or my own Ruby code to generate the RSS and JSON feeds. I've held off on this because while templating JSON or XML isn't the best idea, the templates are pretty good at this point and have been working without me fiddling with them for years. Maybe if I want to add something more complicated to the feeds, but for now I think they're fine as they are.

Another bit of work would be JavaScript-free footnotes. I've recently added a few lines of JS to make footnotes open in a popover instead of just jumping down to the bottom of the page, but it would be nice to do this with no JS at all. Now I've got complete control over the HTML generation, maybe there's a better option here.

If you want to make the same move yourself, you can see [my GitHub Actions config](https://github.com/willhbr/willhbr.github.io/blob/main/.github/workflows/jekyll.yml) as well as my [GitLab CI config](https://github.com/willhbr/willhbr.github.io/blob/main/.gitlab-ci.yml) which are both currently working to publish the site live and to the GitLab mirror.
