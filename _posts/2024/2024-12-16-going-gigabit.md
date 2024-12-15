---
title: "Going Gigabit"
image: /images/2024/gigabit-graph.webp
tags: homelab
---

I've finally got a network and internet connection fit for the 2020s. My internet connection is gigabit, and my wifi router has been replaced with one that can actually make use of it.

Firstly, the internet. Put simply, in Australia the internet situation is bad. Up until recently the fastest home internet plan was 100Mb/s. When faster plans were introduced they were significantly more expensive. I'm not well versed on the history but [Wikipedia sums it up well](https://en.wikipedia.org/wiki/Internet_in_Australia):

> The national broadband network aimed to provide up to 1000 Mbit/s speeds [...] This has since been revised [...] for 25 Mbit/s to 100 Mbit/s

Although 25Mb/s **is** "up to 1000Mb/s" if you think about it.
{:class="caption"}

Anyway, for boring reasons I was with [_Internode_](https://en.wikipedia.org/wiki/Internode_(ISP)) and had managed to get a secret deal for 250Mb/s at $90 per month after calling them up asking to cancel my service. Last month they sent me an email saying they were increasing the price to $100. I reminded them of their promise that the secret deal was permanent and that they weren't going to increase the price, but they weren't interested in negotiating.

Being too stubborn to go back to a 100Mb/s plan, I looked around for other options and found that for $99 I could get a gigabit plan from [_Buddy Telco_][buddy]—over three times faster than the $100 _Internode_ plan. I cancelled my existing plan (at the end of the billing cycle to not waste any money on internet I'd already paid for) and signed up for a new gigabit connection.

[buddy]: https://www.canstarblue.com.au/internet/aussie-broadband-launches-buddy-telco/

_Buddy Telco_ is an offshoot of the well-regarded _Aussie Broadband_ ISP, but saving costs by not having phone support. I was a little concerned that the setup would be painful, as when I've moved or swapped routers I've had to call tech support and either have them tell me some setting I needed to toggle on the router (it's always vlan tagging) or find out that everything on my end is correct and they just need to press a button on their end. That's always the most frustrating end to an evening of debugging. At this point if I can't find the problem in a few minutes of tinkering I'll just call up customer support, wait on hold while I tinker, and then follow along with whatever their script wants me to do. Reboot the router? Reboot the fridge? I don't think that'll do anything but I'll do it anyway.

My new connection activated last week, I expected to get sent [PPPoE][pppoe] credentials and some other instructions, but it just said "Please connect to UNI-D port 2, on your NBN device." I moved the WAN cable from port 1 to port 2, and it worked. No credentials, no vlan tagging, no calling customer support.

[pppoe]: https://en.wikipedia.org/wiki/Point-to-Point_Protocol_over_Ethernet

Their online portal _does_ have some self-service debugging tools. You can check your connection status, reset the connection, and things like that. They have some basic descriptions to say "do this if you've changed your router" and such, so I'm hopeful that the lack of customer support won't end up being an issue.

I checked Grafana, and there we are: 911Mb/s. I guess that's gigabit.

![Graph from Grafana showing connection speed increase from 269Mb/s to 911Mb/s](/images/2024/gigabit-graph.webp)

I've been monitoring my internet speed [since I setup Prometheus](/2023/07/16/simple-home-server-monitoring-with-prometheus-in-podman/). After a few days I noticed my new connection will periodically drop from ~900Mb/s to 400Mb/s. I wasn't sure if this is an issue with the connection, or my server that runs the speed test. It's running on my less powerful "production" server, a ["scooter computer"](https://blog.codinghorror.com/the-scooter-computer/) that I bought in 2017 with cheap 2015-ish era hardware. To narrow it down, I ran a parallel speed test on my (much newer) NUC. This seems to have fewer slowdowns, but it's hard to draw a definitive conclusion with only a few days of data, and a lot of the other changes to my network would confuse this result.

Speaking of hardware, my quest for gigabit also led me to finally take my home networking hardware seriously.

Up until now, I've been using the free router that my ISP gave me almost 7 years ago. It's a [TP-Link Archer VR1600v](https://www.tp-link.com/au/service-provider/xdsl/archer-vr1600v/), one of the handful of routers that Australian ISPs would give out[^no-routers] and it's somewhat [notoriously bad](https://www.markhansen.co.nz/doubled-ping/). It's never seen a software update; which is not what you want from the device between you and the rest of the internet.

[^no-routers]: This seems to be much less common now.

Without a fast internet connection, buying a "real" router just seemed like a waste. As I accumulated more home servers (like [my Synology](/2023/07/03/picking-a-synology/)), instead of being an adult and buying a switch to chain multiple devices off the poorly-placed Ethernet ports in my apartment, I used another free ISP router in bridge mode to do the job.[^positioning]

[^positioning]: To clarify, the router and scooter computer are in the cupboard where the fibre connection terminates, which also has a small ethernet patch panel for the other ports in the apartment. The NUC and Synology sit next to my desk, since they've got fans and appreciate having a bit more airflow. There's only one ethernet port there[^port-placement] so it has to get split between multiple devices.

[^port-placement]: I want to have a serious word with whoever decided the ethernet port placement in this apartment. There are more ports by my bed than there are at my desk. Are they expecting me to use an alarm clock with wired networking?

My home network looked like this:

```
 o TP-Link Archer VR1600v Router
 ├─ Wifi devices
 ├─ Steve (Scooter computer)
 ╰─o Technicolor TG789vac v2 Router (Bridge mode)
   ├─ Synology DS420j
   ├─ Brett (Intel NUC)
   ╰─o─ Thinkpad thunderbolt dock
     ╰─ MacBook Air M1 (sometimes)
```

It worked and didn't require buying any new hardware. I was optimistic about the capability of my Wifi 5 (ie 802.11ac) router, since the maximum speed of an 802.11/ac connection is a bit over a gigabit. Sadly this was not the case, it capped out at about 310Mb/s.

Knowing that my wifi router was likely to be the biggest bottleneck in my home network, I wanted to check that there weren't any other bottlenecks lurking. It would be especially bad if the wiring in my apartment was a limiting factor, since that would be expensive to replace.

I started by generating a 1 gigabyte file using `head -c 1G /dev/random > testfile`, and then starting a webserver with `python -m http.server` to see how fast I could download it—and what the download speed the browser reported. I ran this on my dev machine—Brett—and that capped out at 80Mb/s. Shouldn't this be at least as fast as accessing the internet?

Maybe the Python webserver isn't able to push data out fast enough? Ideally we'd want a server that is designed to push out data as fast as possible. This is where [_OpenSpeedTest_](https://openspeedtest.com) comes in. You can run it in a container and run a speed test across your local network:

```console
$ podman run -d -p 3000:3000 -p 3001:3001 docker.io/openspeedtest/latest
```

You just click the button in the web UI, and you get a speed test.

I tested from my laptop (over wifi) to both Steve (scooter) and Brett (NUC). Steve got the speeds I would expect: 298 down, 345 up. Brett gets 92 down and 364 up. It seems like Python wasn't the problem after all. The only difference in the two servers is Brett is going through the bridging router and Steve is directly connected to my wifi router. I plugged Brett directly into the main router and got 315Mb/s in both directions.

It's not clear why exactly the bridge-mode router can accept traffic at over 300Mb/s[^faster-not-wifi] but can't sent traffic that fast back in the other direction. Either way, it was a bottleneck and had to go. A quick trip to the shop and it was replaced with a TP-Link 5-port gigabit switch. Now both Steve and Brett have equally fast connections.

[^faster-not-wifi]: Presumably it would be able to go even faster if I wasn't limited by the speed of my wifi.

I feel a bit silly not having tested this earlier, because my Synology was also sitting behind the bridge-mode router, and so this would have also been slowing down transfers there. Lesson learnt, I guess. Now the limiting factor will be the wifi, rather than me being too lazy to spend $34 on a switch.

The final puzzle piece is wifi. So far all my tests from my laptop have been wireless, and so the limiting factor has been the crappy old VR1600v.

I consulted with a colleague who helped me navigate the complex world of wifi routers. I realised that I'd never actually bought a router before, there was always just one available somewhere. The two important things I learnt is that you can get a wifi 6 router for about $100, but you might not get your full gigabit out of that. For an extra $50 you can push the maximum speed up an extra gigabit.

The router I ended up getting was the [TP-Link A53][a53], largely dictated by what was in stock in shops a walking distance from home. It's exactly the boring appliance I was hoping for; it's router shaped, doesn't require you to download an app, has a handful of ports, and gives my laptop fast internet.

[a53]: https://www.tp-link.com/au/home-networking/wifi-router/archer-ax53/

It was tempting to get something super fast, but since none of my devices have faster than gigabit ethernet, having wifi that's substantially faster than my wired networking seemed like a waste. If I make the jump to 2.5 or 10Gb/s devices, I'll replace the router with something more capable, but I don't think that's likely anytime soon.

Is it worth upgrading your home network? If you're in Australia and have fibre coming into your house or apartment, go get a gigabit plan and a router to match. If you've got a slower connection but have some kind of networked storage? Get a better router and switch, I should have done this years ago. Will this make a meaningful difference in my real-world internet speed? Probably not, everything is hosted in the US or Europe anyway and the speed of light isn't getting any faster.
