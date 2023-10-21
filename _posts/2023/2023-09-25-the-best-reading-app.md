---
title: The Best Reading App
---

Since the start of this year—for some reason, I [can't put my finger on what](https://www.theverge.com/2023/1/13/23553161/third-party-twitter-clients-apps-outage-twitterific-tweetbot)—I've been reading far more RSS feeds and articles that I've come across. I've sporadically used RSS in the past, but never really got into a groove with it. Currently I'm using [NetNewsWire][nnw], which is good but doesn't quite match the experience that I want, and so I'm writing this to manifest into existence the perfect app.

[nnw]: http://netnewswire.com

I'm an absolute fiend for a reverse-chronological list of items where my position is perfectly preserved. [Tweetbot][tweetbot] and [Ivory][ivory] are absolutely perfect for this; I can open the app, scroll a little bit, and then leave and come back later. It's been part of my daily routine to scroll through the tech news and gossip each morning as I start my day.

[tweetbot]: https://tapbots.com/tweetbot/
[ivory]: https://tapbots.com/ivory/

Sadly no RSS reader seems to have quite the interface I want. So I'm going to describe it in enough detail that someone can find one for me, or some enterprising developer can implement it.

The main interface would of course be a reverse-chronological list of posts (oldest at the bottom), with the key feature that your scrolling position would remain where you left it. New posts would be loaded "above" your scroll position, so you would just continue to scroll up as you read through the feed. The feed should make use of article and feed images to present a visually engaging view, rather than a simple list of titles.

It's not a use case that I particularly care for, but if I were making this app it's something I'd be sure to handle: viewing a single feed. This doesn't really mesh too well with the main list of posts, but wouldn't be an insurmountable UI challenge. What I would probably do would allow viewing a single feed (or group of feeds) like you'd open a user profile on a social media app. Except that you'd be put into another reverse-chronological feed in the same position as the main feed—but just for posts from that publication. You could then scroll through the single feed, and once you were at the top there would be an option to clear those posts from the main feed. That way you could swap back to the main feed and continue reading without repeating posts. This would be useful if a single feed has dumped a big collection of posts and you just want to see if there's something interesting, otherwise get them out of the way.

The second most important feature would be a built-in read-later service. I switched from [Instapaper](https://www.instapaper.com) to [GoodLinks](https://goodlinks.app) and am very happy with it so far, but I would be a lot happier if it were built right into my feed reader. I'll often come across an interesting post, but won't have time or be in the mood for reading a longer or more technical post. Ideally in this case I could just mark it for reading later, without having to share the post to a different app (even if that other app is very good). This would unlock the ability to read half a post, realise you've run out of time, and then just close the article and have it automatically saved for later—with your position already saved.[^position-saved]

[^position-saved]: It's not too uncommon for me to save stuff straight to GoodLinks if I think I might not read it in full immediately, so I don't have to find where I got up to later.

Automatically saving posts would definitely be a UX challenge. You don't want to flag every single post that gets opened as "read later", but you also don't want to have the interaction be unreliable. I would probably lean towards just having a very convenient "close and keep for later" button that is just as easily accessible as swiping back to exit the article.

The next UI challenge would be presenting the main feed and the read-later feed in such a way that neither appears to be playing second fiddle to the other, while also making it easy to swap between them. Perhaps you'd automatically switch between the two depending if there were new posts? Or maybe that would just end up being annoying.

The app would need all the features of a good read-later app; saving links from other apps, presenting web pages in a friendlier reader view, saving reading progress, and saving pages for offline reading.

A problem that I would like solved—but I'm not sure if link-sharing APIs allow for this—is knowing where the link was shared from. I find myself getting to the bottom of a post that I've saved from somewhere and thinking "oh whoever shared this obviously has excellent taste, I should see what else they do" but have no good way to find where I got it from. Alternatively I think of someone that I should share it with, only to find out that they were the person that sent it to me in the first place.

I have considered creating a second Mastodon account and just subscribing to the feeds of websites I follow (or using RSS-to-activitypub translators), and adding this account to [Ivory][ivory]. What stops me from doing this is that it would only get me half way there—no read-later integration—and Ivory would be doing double duty, meaning I'd have to switch accounts constantly.

---

If you're looking for some fresh feeds, I quite like [grumpy.website](https://grumpy.website) (examples of frustrating UI design), and [Pixel Envy](https://pxlnv.com/) (links and commentary on technology with a focus on privacy and open design, which is my jam).
