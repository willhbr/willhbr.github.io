---
title: "Interoperability Tier List"
---

There is almost nothing built-in to your computer, phone, tablet, etc that allows you to interact directly with someone else's computer. If you have a photo on your phone, and your sitting next to someone with their phone, the easiest way to transfer the data between those two devices usually involves using someone else's computer in a datacenter thousands of kilometres away.

In general, the interoperability of physical devices is pretty good. If you've got a monitor or TV, you're almost guaranteed to be able to plug it into your computer with HDMI or DisplayPort. Maybe you'll need a dongle, but you don't need to worry about buying a new TV just because you switched to a different game console. The same goes for ethernet, USB, and the 3.5mm headphone jack. However as soon as you cut that cable, things get more limited.

We can think of this as tiers of interoperability:

Starting at the bottom, we have vendor-specific features, tied to a specific hardware or software platform. My favourite example is AirDrop, it's excellent for proximity-based file transfers, and gets decent speeds because it creates an ad-hoc wifi connection, but it's only available on Apple hardware. (There are of course projects that have reverse-engineered the protocol, but for the purposes of this post I'm only considering things that are generally available).

Moving up one level gives us software that runs across different platforms because the vendor chooses to develop for multiple platforms. This is what most people would consider "cross platform", as you can use the software on basically any mainstream hardware/software combination. Most proprietary software falls into this bucket.

Often "cross-platform" software leverages the web to run on less popular (read: non-mobile) OSes. This has the side-effect of allowing it to run on any platform with a compatible browser. Obviously this makes it much easier to access proprietary software from an "unsupported" platform (for example if you use Linux), but often the limitations of web APIs (or lack of investment from the vendor) make this an incomplete experience. You may be able to access the web interface for your favourite cloud storage provider, but it's unlikely that you can do automatic syncing to a local folder using the web app.

Another half-step up the interoperability ladder is vendor-specific servers that allow for arbitrary cross-platform clients. If you squint, this is how most web applications work—there's a server controlled by the vendor, and the clients are browsers that can be running on any platform. Similarly you could have a centralised service that allows for third-party clients to use a full-featured API. This is _almost_ what Twitter used to allow (pre-2023) where you could use the service on the web, or via an app of your choice.

The point at which we get practical interoperability is federated services, like email. No two email "users" have to be signed up to the same service, use the same client application, or even have the servers running the same software. There is both a standard API between the servers ([SMTP][smtp]) as well as standard APIs for clients to interact with mail servers ([POP3][pop] and [IMAP][imap])—although there is of course nothing stopping an email provider from only supporting their own API, as long as they interact with other mail servers using SMTP. Your provider not supporting IMAP has no effect on my ability to use IMAP with my provider.

[smtp]: https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol
[pop]: https://en.wikipedia.org/wiki/Post_Office_Protocol
[imap]: https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol

On a similar level there are SMS, RCS, and the phone system. However they require certain hardware, and are treated differently to email by the operating system. Most OSes don't allow for replacing the interface used to interact with SMS, RCS, or phone calls, and so even if the standard is open, users don't get the benefit of being able to swap components out to gain more features or an alternate interface.

If you'd asked me even just a year ago I would have said that the messaging [interoperability requirements in the DMA][dma-message] were pointless, but in lieu of mandating a protocol that must be supported by all devices, this is likely the best way to allow for breaking the network effects of social software. I'd love to be able to use a single app for messaging, instead of having to swap between five different apps depending on who I'm talking to. Of course, the actual result of this is yet to emerge.

[dma-message]: https://www.eff.org/deeplinks/2022/04/eu-digital-markets-acts-interoperability-rule-addresses-important-need-raises

Where there is an amazing amount of interoperability is networking. Every consumer device that is designed to connect to the internet either supports wifi or ethernet, and has an implementation of the various protocols necessary to send and receive data—allowing most applications to just interact with a higher-level protocol like HTTP. Imagine if this wasn't the case, and you had to buy a new wifi router when you bought a new device. Or you visited someone and they had an incompatible network, leaving you without a connection.

It's hard to imagine that would ever happen, since the interoperation is such a huge convenience. Although you don't have to look very far to see places where there is little to no interoperability: smart home devices are rife with them. I have a handful of LIFX smart lights,[^lifx-ok] and they're basically just an accessory to my phone—and only my phone. LIFX have to integrate with each platform individually, so if you're not on one of those platforms they are useless, and if you have any kind of heterogeneity in your devices, you'll have to pick a platform that supports all of them. At this point I think having a smart home in a household that spans multiple platforms—Android and iOS, say—is so impractical you might as well not bother. At least if you want to make use of any vaguely "smart" features _and_ don't want to be a sysadmin.

[^lifx-ok]: They're fine. I wouldn't really recommend them for all the annoying incompatibility issues I've mentioned here, my attitude to smart devices now is that you should only buy things you'd be ok with replacing every time you got a new phone.

In theory [Matter][matter] will solve the cross-platform problems, but the rollout is happening at a glacial pace and for me will almost certainly require replacing my lights. I can use a years-old wifi router with no problem, but similarly aged smart lights are counting their days until the e-waste bin.

I have to tell you about a burger franchise in Sydney that is not cross-platform. How can burgers have platform dependence? Well, previously you could order takeaway on the web, which I would often do in advance so I could pick up my order on my way home. A few months ago they removed this functionality from the website, instead they would only take orders through their app. So if you didn't have an iOS device or Android device (with access to the Play Store), you couldn't make a takeaway order. Why they made this decision is beyond me. I can only assume that they're trying to get people to install the app as a ploy for more data or high-engagement promotions via push notifications.

Of course what actually happened is that I just phone them up—they've still got a phone number—and place an order the old-fashioned way. Or I could just show up and make an order in person.

[matter]: https://www.theverge.com/23568091/matter-compatible-devices-accessories-apple-amazon-google-samsung

Devices supporting open standards gives them a longer useful lifetime, especially if you end up changed computing platform at some point. I have a [UE Boom 3][boom], and while it does have some platform-specific features, the core functionality of playing audio is just bluetooth. Sadly one of the platform-specific features is that the biggest button (that everyone thinks is the power button) is tied to starting playlists in specific music streaming services that I do not use. But I know which button turns it on, and I can find a playlist myself.

[boom]: https://en.wikipedia.org/wiki/UE_Boom

While they're not quite in the same category, smart speakers that have built-in voice assistants and music streaming will become virtually useless if you switch platforms. Either you must remain using the services supported directly on the device, or use applications that support the proprietary streaming protocol for the device (ie Google Cast or AirPlay). The same is true for video streaming; there is a standard for video streaming ([Miracast](https://en.wikipedia.org/wiki/Miracast)[^mattercast]), however platform vendors prefer their proprietary protocols.

[^mattercast]: While writing this I learnt about [Matter Cast](https://www.theverge.com/2024/5/10/24153556/fire-tv-amazon-matter-casting-hands-on) which is _another_ standard for doing video streaming to a TV, seemingly only supported by Amazon at the moment.

It's easy to take the standards that we do have for granted—the idea of worrying about wifi compatibility seems absurd—but for many things there isn't even the possibility of worrying about compatibility, you just know that it won't work. It's worth thinking which tech islands you inhabit, and whether the rising tide of tech advancements is ensuring that it's never practical for you to migrate. If you switched to Linux, would you just be giving up some convenience, or the ability to be part of social life? At the moment I'd say that you can only really rely on three things: support for networking, a mostly standards-compliant web browser, and the ability to execute _mostly_ arbitrary code.

My barometer for "interoperable standard" as examples for this post are things that you can count on being supported on any device without additional software, and without reverse-engineering a protocol. It's likely that I've got some things wrong, but hopefully the general gist is still somewhat clear.
