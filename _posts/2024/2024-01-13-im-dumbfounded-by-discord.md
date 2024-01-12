---
title: I'm Dumbfounded by Discord
---

I find [Discord](https://discord.com) baffling. Not in its popularity in group messaging for a class, team, or friend group—it seems fine at that—but the other, larger use cases.

In 2020 and 2021 I learnt how to create digital art in [Blender](https://blender.org), the 3D modelling software. I watched both [Clinton Jones's videos](https://www.youtube.com/user/pwnisher) (who I had been following from his time at [RocketJump](https://www.rocketjump.com) and [Corridor Digital](http://corridordigital.com)) and [Blender Bob](https://www.youtube.com/channel/UC3HUESS7z-P1KqeuVMNAe4Q). It was Clinton's work and the videos showing his process where I learnt that you could use computer graphics without ever thinking about video or "VFX"—that's just where I was exposed to these ideas initially. [His Instagram](https://www.instagram.com/_pwnisher_) has a mix of both film photography and rendered computer graphics, but since he targets the same aesthetic in both, it's often hard to tell at a glance which is which.

Anyway. Both of these creators have Discord servers where subscribers could chat, share their work, and potentially get some guidance from people in the community or the creator themselves. When I joined, both were open for anyone to join, but I think that now Clinton's Discord is for Patreon supporters only.

This is where the bafflement comes in. Discord is designed as a synchronous messaging system. You can obviously view or reply to messages at any time, but the interface expects you to read messages almost as soon as they are received, and reply immediately or never.

For a team or group of friends this makes sense, you're probably all in the same timezone and share a similar schedule. If you're not, then at least the group is probably small enough that it's easy to catch up on anything that you missed. Discords for "fan communities" are basically the exact opposite—they're large and highly trafficked. The time difference is exacerbated by me being in a significantly different timezone than the typical North American audience.

The experience that I would have was every time I checked the servers, there would be at least tens—if not hundreds—of new messages in every channel, with topics of conversation shifting multiple times. Any attempt to ask a question or have a conversation is drowned out in the noise of additional messages and threads.

The Discord app just isn't designed for reading _all_ the messages. Even if I treated the server as a read-only experience (much like [I do with Mastodon]({{ site.urls.mastodon }})[^no-toot]), it's difficult to go through and look at the history of a channel. If you do, you're going to be reading it backwards as the app probably isn't going to perfectly preserve your scroll position (something that [I'm especially keen on](/2023/09/25/the-best-reading-app/)).

[^no-toot]: Go on, toot me.

It seems to me that these Discord servers have a few roles; a support forum, a showcase of work, and a space for informal discussion.

You know what works really well as a support forum? An actual forum with first-class support for topics, threads, and detailed discussion that can happen asynchronously as the question-asker works through their problem. As someone that remembers a time before Stack Overflow, it seems like people have collectively forgotten the experience of describing your problem on a forum, and then a day later having a kind and knowledgable person ask you to give them some more information so they can pin down the solution.

I've seen it mentioned on Mastodon that some software projects use Discord in lieu of a support forum _or_ documentation, which I find absolutely baffling as trying to find something that someone mentioned within a chat conversation—and understanding all the surrounding context, while filtering out any unrelated noise in the channel that was happening alongside it—seems completely impossible. Those conversations are also not going to be indexed by a search engine, so people that aren't aware of the Discord are almost certainly not going to stumble across it while searching for information about a problem they're having.

> If the infamous [discussion about whether there are 7 or 8 days in a week](https://forum.bodybuilding.com/showthread.php?t=107926751) had happened on Discord, I wouldn't be able to effortlessly find it 16 years later with a single search.

The other two use-cases—showcasing work and having informal discussions—are less well suited to forums, but I think they'd still be passable if implemented that way. However, the actual point of this whole post was to propose an alternative for this kind of fan community: a private Mastodon server.

As web creators move towards sharing their work on their own terms, rather than via an existing platform ([an example](https://citationneeded.news/citation-needed-has-a-new-home/)), a suitably tech-focussed[^read-mastodon] creator could offer membership on a private Mastodon server as a perk of being a supporter.

[^read-mastodon]: Read this as "willing to put up with the complexities of Mastodon and able to understand the nuance of having a de-federated instance of a federated system".

Mastodon's soft-realtime and Twitter-like flat-threaded structure give it a nice balance of working reasonably well for quick conversations as well as time-delayed asynchronous communication. Since the instance would be private, the "local" timeline would just contain posts made by the community, allowing members to see everything, or create their own timeline by following specific people or topics.

Ideally, Mastodon clients would allow mixing and merging accounts into a single timeline—so I could have the accounts I follow from my [main account]({{ site.urls.mastodon }}) and accounts on this private instance show up in the same timeline, so I don't have to scroll through two separate timelines.

The biggest challenge would obviously be explaining that you're signing up to an instance federated social media platform that has disconnected itself from the federated world in order to provide an "exclusive" experience only for supporters of the creator.

I don't think that Mastodon will reach a level of mainstream success that such a niche use of it could be anything but a support headache, but it's interesting to think how open platforms could be re-used in interesting ways.
