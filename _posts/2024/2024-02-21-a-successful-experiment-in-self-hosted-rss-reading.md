---
title: "A Successful Experiment in Self-Hosted RSS Reading"
tags: projects homelab
---

For just over a month, my RSS reading has been self-hosted. Usually I'd write about this kind of thing because there was an interesting challenge or something that I learnt in the process, but it has basically been a completely transparent change.

I'm still using [NetNewsWire](http://netnewswire.com) to do the actual reading, but I've replaced [Feedly](http://feedly.com) with [FreshRSS][freshrss] running on my home server (well, one of them).

[freshrss]: https://www.freshrss.org

I didn't really have any problems with the quality of the Feedly service—they fetch feeds without any issues and most apps support their API, and their free tier is very generous. I've had my Feedly account for years. However they use their feed-scraping tools to provide [anti-union and anti-protest strikebreaking services](https://www.citationneeded.news/feedly-launches-strikebreaking-as/), which is a bit gross to say the least.

The ease of moving between RSS services is really what makes this an easy project, as [Dan Moren wrote on Six Colours](https://sixcolors.com/post/2024/01/cutting-out-the-rss-middleman/) it's as simple as exporting the OPML file that includes all the feed URLs, and importing that into another service. Dan ended up using the local feed parser offered by NetNewsWire, but I'm morally opposed to having my phone do periodic fetches of 61[^as-of-now] feeds when I have a computer sitting at home that could use its wired power and internet to do this work.

[^as-of-now]: As of the time of writing, that is.

NetNewsWire supports pulling from [FreshRSS][freshrss], which is an open-source self-hosted feed aggregator. It supports running in a container, so naturally all I needed to do was add the config to a [`pod`](https://codeberg.org/willhbr/pod) file:

```yaml
freshrss:
  name: freshrss
  remote: steve
  image: docker.io/freshrss/freshrss:alpine
  interactive: false
  ports:
    4120: 80
  environment:
    TZ: Australia/Sydney
    CRON_MIN: '*/15'
  volumes:
    freshrss_data: /var/www/FreshRSS/data
    freshrss_extensions: /var/www/FreshRSS/extensions
```

You just do some basic one-time setup in the browser, import your OPML file, add the account to NetNewsWire, and you're done.

The most annoying thing is a very subtle difference in how Feedly and FreshRSS treat post timestamps. Feedly will report the time that the feed was fetched, whereas FreshRSS will use the time on the post. So if a blog publishes posts in the past or there is a significant delay between publishing and when the feed is fetched, in Feedly the post will always appear at the bottom of the list, but FreshRSS will slot it in between the existing posts. I want my posts to always appear [in reverse chronological order](/2023/09/25/the-best-reading-app/) so this is a bit annoying.

> An example of a website where the times on posts are not accurate is **this very website!** I don't bother putting times on posts—just dates—since in 10 years of posts I only have [two](/2023/06/08/overcoming-a-fear-of-containerisation/) [posts](/2023/06/08/pod-the-container-manager/) that are on the same day. Feedly assigns a best-guess post of when the post was published (when Feedly first saw it) whereas FreshRSS just says they were published at midnight. Which isn't too far from the truth, as it's half past ten as I write this.

To avoid exposing FreshRSS to the outside world, it's only accessible when I'm connected to my VPN, so I don't have to worry about having a domain name, SSL cert, secure login, and all that.

I haven't had any reliability issues with FreshRSS yet, obviously the biggest disadvantage is that I'm signing myself up to be a sysadmin for it, and the time that it will break is when I'm away from home without my laptop.
