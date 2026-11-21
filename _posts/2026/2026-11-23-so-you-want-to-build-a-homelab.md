---
title: "So You Want to Build a Homelab"
tags: homelab
---

Last week I was talking to someone about cancelling my music streaming subscription and instead [hosting my own streaming service](/2026/09/28/owning-my-streaming-with-navidrome/) of music that I'd bought. They wanted to know how it all fit together, and quickly I was explaining how I'd actually just [swapped to use NixOS](/2026/10/11/inevitably-nixos/) and how setting up Navidrome was easy because [my container dashboard](https://codeberg.org/willhbr/endash) can autoconfigure the reverse proxy, so I don't have to set that up separately.

That is all very well and good for me, but what if you're a little more normal, and want to run a home server?[^as-normal-as-can-be]

[^as-normal-as-can-be]: As normal as you can be while still wanting to run a home server.

# Hardware

The best hardware is whatever you've already got. Whether that's an old laptop or a Raspberry Pi that you were totally going to use for some project, it's best to reuse instead of going out to buy something.

If you don't have anything at hand, my recommendation is to get a second-hand small form-factor computer. Usually if you search for "mini PC" you'll find them. It's basically the [Intel NUC](https://en.wikipedia.org/wiki/Next_Unit_of_Computing) and derivatives. Typically there is a steady supply of these coming from businesses that are upgrading and looking to get rid of their old stock. In 2026 the typical spec I'd expect to see is 8GB of memory, a 250GB SSD, and a 5-ish-year-old processor, for about $150.

I always look for computers that have a CPU with a 15W [TDP](https://en.wikipedia.org/wiki/Thermal_design_power), which is basically the CPUs with the lowest power consumption, typically reserved for laptops, but often found in these mini PCs. This gives me a little bit of confidence that if the airflow isn't perfect, it's unlikely to make enough heat to damage itself, and leaving it running all the time isn't going to have a huge impact on my energy bill.

The important thing to keep in mind here is that almost everything you might do on this machine can be done with a fairly low-end or old CPU.

The exception is if you want to transcode video on the fly, either to reduce the data sent over the network or because a device can't play back a certain format. This will need more CPU (or GPU) power, and some formats rely on specific hardware to be decoded efficiently.

My advice here: don't get into a situation where you need to transcode video. Make sure any media you get is small enough to stream over your network. This usually isn't a problem as long as all your devices are connected to your home wifi. Additionally, only get media that can be played back natively on your devices, so that the server can act as a simple file server, instead of doing compute-intensive work trying to transcode the video.

One limitation that I would put on any hardware I use would be that it must have ethernet. Not for the speed, but for the fact that when the cable is plugged in, the computer will connect with basically no additional config. This makes any debugging so much easier.

If you get a mini PC with 250GB of storage, that will probably be enough for music streaming, but if you want to store video, that'll fill up fast. Most mini PCs don't have space for extra drives, and replacing the [M.2](https://en.wikipedia.org/wiki/M.2) SSD with a larger capacity one will probably cost more than the machine did.

External hard drive enclosures are a simple way to get more storage for a machine with no other expansion. USB 3 is more than fast enough to not be a bottleneck with an HDD. Even with an SSD, it's unlikely that you'll notice a speed difference. I'd try and get a bus powered one (that gets its power over USB, instead of a separate power supply) as it's less bulk and fewer cables to manage.

# Operating System

Obviously it should be Linux, managing Windows or MacOS on a server would be a pain, and I'm too casual to use BSD.

My advice is to go with something that is tried and tested, has stood the test of time, and is well supported. I'd recommend Ubuntu, or plain Debian. Everyone else is using them, and so when there are instructions for "Linux" it usually means "Debian/Ubuntu".

In general I'd always stick with the "root" distributions that are well established (Debian, Arch, Fedora, etc) and avoid straying too far afield, especially if you want something low maintenance.

Whatever you pick, you should look up some information on setting it up as a server. I always make sure that SSH password authentication is off, and the firewall is on. Check if there's anything else you might need to do with your distribution of choice.

# Accessing the Machine

In order to reduce the chance of someone gaining access to your server, it's best to not leave it accessible to the outside world. You can then use a VPN to give yourself secure access from anywhere, without leaving your proverbial front door open.

The VPN I use is [Tailscale](https://tailscale.com), but I've also used [Nebula](https://nebula.defined.net/docs/) before—enough that I wrote [instructions on how to set it up](/2021/06/22/configure-nebula-vpn-on-ios-android/). Nebula now have a hosted option, which should cut out a lot of that fiddly work.

In general I like to only run open source software, so that I'm not one business model change away from having to re-think my entire setup. However, Tailscale is convenient enough that I use it instead of configuring [Wireguard](https://www.wireguard.com) myself. I do try to make sure I'm not relying on any feature that can't be easily replaced, I don't use Tailscale's web server proxying and similar features for this reason.

# Running Software

Obviously [I think that containers offer a lot of benefits](/2026/01/15/why-containers/), which is why I use them for the software I run. A large part of that is my [custom container management tool](https://codeberg.org/willhbr/pod) and [dashboard](https://codeberg.org/willhbr/endash) that make this easy for me, and only me.

Whether containers are the right answer for you will really depend on what you're aiming to run. If it can be installed directly through your system package manager (like `apt` or `yum` or whatever) then that's probably the easiest thing.

For example, the [Navidrome installation instructions](https://www.navidrome.org/docs/installation/linux/) involve downloading a Deb archive, installing it, and starting the program with `systemctl`. None of this is particularly complicated, but it's a little fiddly. It's probably fine as a one-off install, but I'm not sure if this method will update when a new version is available.

My recommendation here for Navidrome and other software that isn't currently available via `apt` would be to use [Quadlets](https://docs.podman.io/en/latest/markdown/podman-quadlet.1.html). They basically wrap your containers in [systemd](https://en.wikipedia.org/wiki/Systemd) units. Systemd is the way to run managed background processes on many Linux distributions, and so it'll handle things like starting your application when the machine boots.

Mat Duggan [has a nice overview](https://matduggan.com/replace-compose-with-quadlet/) of what you can do with quadlets. You basically just make a config file like this:

```systemd
[Unit]
Description=Navidrome
After=network-online.target

[Container]
Image=docker.io/deluan/navidrome:latest
ContainerName=navidrome
AutoUpdate=registry
PublishPort=4533:4533
Volume=/path/to/my/music:/music:ro
Volume=/path/to/data/storage:/data
Environment=ND_LOGLEVEL=warn

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
```

For illustrative purposes only, I have not tested this.
{:class="caption"}

This will auto-update periodically whenever there's a new image pushed to `docker.io/deluan/navidrome:latest`, which is especially nice if you want something a bit more hands-off.

For most people, I'd recommend against using [Caddy](https://caddyserver.com) as a reverse proxy and setting up a DNS record. It's easier to just accept remembering a couple of port numbers and creating bookmarks.

# Backups

[I use Restic](/2026/07/19/backups-with-restic/) to back up my servers, which gives me confidence that my self-hosted data won't just disappear when my USB HDD enclosure dies. At the very least, keep a copy of your data (like, your music library) on your main computer, and _presumably_ you back that up. Or at the very least, it's less likely to fail.

Depending on the amount of data you have, you could keep everything on your internal SSD and use an external HDD purely as a backup drive. It doesn't give you off-site safety, but you'd have a second copy in case you formatted the wrong drive.

---

Obviously self-hosting isn't a low-effort solution, and requires a fair amount of enthusiasm or sysadmin experience. The good thing about self-hosting music is that you can just get a client (I use [Nautiline](https://nautiline.app)) that has good client-side caching, so if—or more realistically, _when_—your server goes offline, you still have some music available until you get around to fix it.

Hosting [your own RSS aggregator](/2024/02/21/a-successful-experiment-in-self-hosted-rss-reading/) is a bit more annoying, as the whole purpose is to show new things that rely on an internet connection. Although I can go a few hours without reading RSS and just catch up later.
