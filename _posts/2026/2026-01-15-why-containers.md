---
title: "Why Containers?"
tags: homelab opinion podman
---

There seems to be a recurring sentiment that pops up every now and again on Mastodon: "this project looks interesting, but the installation instructions say to use Docker, so I'm not interested anymore". Now I totally understand the sentiment. If I came across a project and the instructions said to install it I'd need [Nix](https://nixos.org), I would also do a quick 180.

However, I've been using containers for development and for the services I run at home for a few years now, and I quite like it. So I thought it might be interesting to explain what I get out of containers, some of the bad bits, and right at the end some feelings about the mismatch between container enthusiasts and container skeptics.

# Use `podman`

I'll get this out of the way: I don't actually use Docker, I use Podman. Aside from being more permissively licensed, it's also much easier to install on basically any Linux system as it's available in most distros' package repository. On Ubuntu I can just `apt install podman` and on Alpine I can `apk add podman`. The [Docker installation instructions](https://docs.docker.com/engine/install/ubuntu/) are *much* more involved.

This is the main reason I would recommend Podman, maybe second only to the fact that Podman runs rootless by default, which reduces the chances of a rogue container stomping over something on your machine that it shouldn't.

# Process isolation

By far the biggest benefit of using containers for me is low-effort process isolation. I don't like the fact that if I run something myself it'll have access to all the data on my system and be able to read and upload it, or simply just corrupt or delete it.

You can of course get this same benefit by running services as different users, which most well-behaved services installed by system packages should be doing anyway.

Running services as different users does make sharing data between services more difficult, and I'm not very good at managing groups. Being able to just restrict the paths that the container has access to is really simple both to do and conceptually. I don't have to think about who is a member of which group and what access that grants them, I just say "you can access this folder" and that works really well for me.

The biggest benefit of container isolation is that when the container is gone, everything else goes with it. If the process was writing logs, config, temporary files, whatever, it's all constrained into the container. Once I've done `podman rm` I know that everything belonging to that container has been purged.

This makes trying new software a lot more like apps on a phone; you know that the risk of installing is very limited, and when you uninstall you know that everything gets removed. The exact opposite of installing software on Windows XP, where you'd have to go through a wizard, it would require full admin access, and it could make any change to your machine it wanted.

This isolation can also flip who is in control of the program. For example, some program might only support listening on a particular port or saving its data to a particular directory. This is of course bad software. Nevertheless I have the power to say "no thanks" and re-map the port and filesystem locations so from my perspective the program is working the way I want.

# Opaque storage

Since I'm in full control of what data in the container gets persisted, I have much more control about where it actually lives on my system, and thus how it gets backed up.

All the containers that actually store data—most important being [FreshRSS](https://www.freshrss.org)—I map their data into a Podman [volume](https://docs.podman.io/en/v4.4/volume.html), which I can treat as an opaque blob. Currently I have a script that will take these volumes, export them to TAR files, and upload them to my NAS.

I'm definitely missing out on incremental backup here, as the TAR file requires a full upload each time. This is not perfect.

# Processes versus programs

I like the fact that I can think of my programs more like programs instead of having to deal with OS processes. Perhaps I'd get this same benefit if I was good with systemd, but I'm not, so here we are. Instead of haphazardly calling `kill` with copy-pasted process IDs, I can just `podman stop` or `podman restart` with the container name—and it's a name that I can choose myself.

This grouping of processes also exposes better monitoring—on Ubuntu, at least. I use [`prometheus-podman-exporter`](https://github.com/containers/prometheus-podman-exporter) to grab metrics for each container, so I can see where I'm spending my RAM. Annoyingly, due to [some cgroups issue on Alpine](https://github.com/containers/podman/issues/9502) you just get aggregated stats, not per-container stats. So I can't actually take advantage of this for containers on my Alpine servers.

# Remote management

Something I like about Podman specifically is [podman-remote](https://docs.podman.io/en/latest/markdown/podman-remote.1.html). I've [written about this before](/2023/05/05/setting-up-podman-remote/), it's the secret behind [my container dashboard](/2025/03/10/endash-a-lightweight-container-dashboard/).

Since I can interact with the containers on my local machine in just the same way as I do the ones on my other servers, it is really easy to write scripts that deal with both transparently. Endash merges containers running on my two home servers and a VPS into one interface, even with a mix of Ubuntu and Alpine between them.

Even just for local containers, having an interface to get details about what's running in a computer-readable JSON format is really convenient. With Endash I can just list the currently running containers and get the ports that they're listening on to include as links in the dashboard. I can introspect the volumes they have access to, how long they've been running, and more all from one API.

# The rule of two

This is more geared towards development, but it is helpful for any kind of debugging. Since the process running in the container has no idea about what's happening in the real world, it's really quick and easy to run a second instance of some service.

All I have to do is assign it a different port and mount a different directory—or mount no directory to get a fully clean environment—and then I can have both running in parallel.

Paired with the fact that all the data can be isolated to a particular volume, I could duplicate the volume, run a new container pointing to the second copy of my data, and experiment with some alternative configuration or a major version upgrade. All with the peace of mind that if it doesn't work out, I haven't actually done anything to my actual service.

# Dependency Heaven

Dependency hell isn't particularly likely if you're installing the mainstream versions of packages from the package manager that comes with your distro. People have [managed to install a lot of packages at once](https://unnamed.website/posts/installing-every-arch-package/).

I don't think I actually run enough services for this to be a serious issue, but in theory you could have services that require mutually incompatible versions of shared libraries, command-line tools, or suchlike. Being able to run these without messing with load paths or `$PATH` is convenient.

The biggest advantage of this dependency isolation is development, where you can hack around with the system safe in the knowledge that you won't break something important.

# Development

I [originally came to containerisation](/2023/06/08/overcoming-a-fear-of-containerisation/) as a way to control my development environment, rather than a way to run things on my home server. For development, using `podman` directly kinda stinks, the commands are exceptionally verbose and easy to get wrong. So much so that I [wrote my own program to make this easier][pod].

[pod]: /2023/06/08/pod-the-container-manager/

Over two years later and I'm still mostly working this way, but I did walk it back a little. I use `cargo` directly on the system and I gave up on using containers for one-off scripts as it was just too much friction. But containers have made it exceptionally easy for me to write a little server, package it up, and keep it running on my home server. I've currently got 6 of my own containers running across 3 different servers. Running, deploying, and monitoring them is straightforward.

The other development advantage is being able to hack around in a safe sandbox to try and get something working. I try not to install too much weird stuff onto my development machine, especially old tools that might conflict with a more recent version that I rely on. If I containerise this, I can do almost anything without affecting my actual machine.

As a concrete example, I recently wanted to find out why [jekyll-admin](https://jekyll.github.io/jekyll-admin/) would show an error on basically every page load. To do this I needed to build the project, it's built with React which means installing [node.js](https://nodejs.org/en) and [Yarn](https://yarnpkg.com). Some part of this build process requires a Python interpreter, and the versions that jekyll-admin requires are old enough that it would only work with Python 2.[^jekyll-end] Now there's no way that I'd pollute my computer with a Python 2 install, but in a container I can hack around with whatever I want, knowing that it can all just disappear once I'm done.

[^jekyll-end]: The end result was that I tried updating some of the dependencies to work with the current version of Node, realised it would be a serious effort, then gave up. That would have happened with or without containers though.

I did the same thing while trying to work out [why I still couldn't use websockets in Swift](/2025/10/13/the-6-2nd-stage-of-swift-on-linux/). Firstly Swift only supports a few Linux distros,[^linux-swift-support] so being able to fake Ubuntu from within Alpine is a useful trick, but also the availability of the libcurl version depended on the underlying Ubuntu version, and I could just swap between two versions—or even run both at the same time—trivially.

[^linux-swift-support]: [Ubuntu, Debian, Fedora, RHEL, and Amazon Linux](https://www.swift.org/platform-support/) at the time of writing.

Running code in containers also forces you to understand what implicit dependencies you're pulling in, usually development headers for some library, the `build-essential` package, or maybe just `tzdata`. Usually these are things that you install and forget about, then when you go to help someone else it's really hard to remember what you need to do, or even to know what you need in the first place. Having a containerfile doesn't guarantee reproducibility—it might reference an image that changes—but at least there's some intention there that can be reverse-engineered.

# The bad bits

If you use containers, then you need to trust whichever registry you pull from just like you trust the system package manager. I don't know much on the relative security tradeoffs, but you're probably running a newer version if you pull from a registry, which might have unfound flaws. The package manager maintainers might be altering or re-building packages in a way that you find valuable, but they also might be doing something you disagree with.

Trust is definitely something I have in the back of my mind. I don't have a particularly robust approach here, but if there isn't a prebuilt image that I feel comfortable with, I'll just build my own from a standard OS image (probably Alpine) and install the package using `apk` or `apt`. That way I'm still getting a container, but using the package from the distro.

The `podman` CLI is complicated. Somewhat necessarily so, given the amount of stuff it can do, but nonetheless it is really an interface best used by computers, not by people—which I'll get to more at the end.

Podman networking (or container networking in general) is terrible. I've spent ages trying to understand what you can and cannot do, only to run into dead ends and [hard-to-debug problems](/2025/11/30/alpine-containers-forget-tailnet/). The key to a happy life is to set `ufw` to block all incoming connections outside of port 22, 80, and 443, have containers bind to particular known ports, and use [Caddy](https://caddyserver.com) as a proxy.

The opacity you get from using volumes as storage can turn around and bite you when you want to quickly grab something from a volume. The experience is about as good as trying to `scp` something without knowing the exact path. The less I have to do this the better, and if I'll need to look at the files with any regularity I'll use [a bind mount instead](https://docs.podman.io/en/v4.4/markdown/options/mount.html).

# I'm definitely over-invested

You've probably realised now that I'm over-invested. I've picked containers as the backbone of how I use computers and there's no going back now. I've [written a tool for managing them][pod] and then [rewritten it in Rust](/2025/07/25/rewriting-pod-with-wisdom/) and [written a custom web interface to view my containers](/2025/03/10/endash-a-lightweight-container-dashboard/). Without this, I'm lost.

This has definitely given me an appreciation for what you can do with containers, moreso than if I'd pasted in a few `podman run` commands to get something working. A large part of the reason why I wrote these tools was because I _didn't_ understand containers, and the way I get an understanding is to get right down into the weeds. I wouldn't be as comfortable using containers as heavily as I do without having my own system around them.

# Putting it all together

Just to make it super clear, I have a custom tool to build, run, deploy, and update containers, just because I didn't like any of the existing tools. In the shipping container analogy, I've built my own boat, harbour, dock, and crane system. So if you find yourself thinking that a particular podman command is hard to remember or complicated, just know that I've spent hours writing thousands of lines of code to manage that complexity.

Physical shipping containers aren't very useful if you don't have a ship that's built to transport them. In fact it's more difficult to cram shipping containers onto a pre-containerisation vessel than it would be to just carry the cargo directly.

That's the key really, I've built a whole system with containers as the foundation, which has made it really easy for me to use containers. But podman doesn't come with a system, it's just a box you can put stuff in, and that's only half the answer.

To get real value out of containers you need a vessel, whether that's [`podman-compose`][compose] or [Kubernetes](https://kubernetes.io), you need something that will let you take advantage of everything being the same shape.

[compose]: https://docs.podman.io/en/latest/markdown/podman-compose.1.html

For someone that just wants to run something on their server that they administer themselves, these tools are a whole new system to the way they're used to working. When a project says "run this with Docker" what they're doing is asking you to fit a 40 foot container onto a dinghy.

I think that containers at this scale should be treated as a tool instead of a whole system; developers can package their application and its dependencies in a standard way across all distros, and have it run in the same environment without needing to adapt to the actual machine it's running on. It's then up to the distro to provide a way for the user to manage the application _without_ knowing it's backed by a container. Let the container be a packaging tool.

With that in mind, if you're still reading, the tool that gets as close to this as possible is [podman quadlets](https://docs.podman.io/en/latest/markdown/podman-quadlet.1.html), which let you run containers as systemd services. You still have to know they're backed by a container, but it can be managed the same way as other services on your system.[^quadlet-reading]

[^quadlet-reading]: I'd [read this](https://matduggan.com/replace-compose-with-quadlet/) as a nice overview of how and why to use quadlets.
