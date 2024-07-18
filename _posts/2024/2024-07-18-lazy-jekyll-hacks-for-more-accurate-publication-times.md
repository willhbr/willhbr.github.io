---
title: "Lazy Jekyll Hacks for More Accurate Publication Times"
tags: web
---

So here's something terrible that I've just done. Enthusiastic readers with an attention to detail (especially those who read the RSS feed) will notice that all my posts are published at midnight. This is actually a lie—I do usually write posts late at night, but I don't carefully wait until exactly midnight to publish them. The real reason is that I don't include a published time on my posts—just a date—so if your feed reader wants to show a time, it'll show `00:00`.

Of course I could just add a time to each post, but that requires effort. The time only really matters for the first 24 hours or so after publication to make posts from multiple websites appear in order in a feed reader. After that, only the date matters, since I almost never publish multiple posts in one day.

Instead of adding the time in manually, I've made a lower-effort solution to do some terrible things with [Jekyll](http://jekyllrb.com) to fake it.

Jekyll includes a `site.time` variable which is the current time when the site is built. Anywhere that uses this will be updated every time the site is regenerated. I use this in my feeds for the "last updated" fields, and in the footer to put `$CURRENT_YEAR` in the copyright notice.

What I've now done is when I need a post time, I check if the post was published on the same day as the site was built. If it was, I use the site build time instead of the post date. So when I add a new post, the site is built and that build time is used in all post metadata. When feed readers come along they will have an accurate publication time to show to users.

Of course if I push another change on the same day that doesn't update the post, the publication date will jump ahead, and when I push a change the following day, the publication date will be truncated back to just being midnight. I did say it was a hack.

I don't _think_ this will cause problems for feed readers, as they should be using the `guid` (for RSS) or `id` (for JSON Feed) fields to identify posts. The most realistic failure most I can see is that the post jumps up or down a few places in a list of posts when the feed is re-fetched, but I don't think that's any worse than having the post appear out-of-order for everyone all the time.
