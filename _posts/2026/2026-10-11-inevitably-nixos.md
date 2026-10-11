---
title: "Inevitably, NixOS"
tags: homelab
---

Look it was bound to happen at some point. It's like when I [rewrote some stuff in Rust](/2025/04/26/writing-in-crystal-rewriting-in-rust/), it wasn't a matter of if, but when. I've just swapped over my little VPS (that [runs NZ Topomap of the Day](/2025/03/28/building-nz-topomap-of-the-day/) and some other stuff) to [NixOS](https://nixos.org), and plan to swap my home server soon.

My go-to Linux has been Ubuntu since around 2008, for desktops, laptops, and servers. Even though I've been using MacOS since 2012, for years now I've been doing basically all of my development over SSH to an Ubuntu server.

Last year I wrote about how I'd [swapped my home server to Alpine Linux](/2025/03/09/a-slim-home-server-with-alpine-linux/). I didn't really have a well-justified reason for doing it, apart from the fact that it seemed interesting and a vague notion of "simplicity" or whatever. It would probably be easier if I could just say it was because I dislike [Snaps](https://en.wikipedia.org/wiki/Snap_(software)).

# Why NixOS?

Nix (the package manager) and NixOS (the operating system) have a bunch of interesting features, which I know next to nothing about. The thing that entices me is that you can configure the entire operating system from a single declarative config file. This has two benefits. The first is that to set up a new computer, I just use the same config and it'll work like the previous one. The second is that because everything is declaratively configured, the config is the source of truth and reflects what's _actually_ on the computer.

I have scripts to set up an Alpine server, but often I'll have to SSH in to fix something and end up running some random command (like `ufw enable`) and forgetting about it. Now _that_ computer has a firewall, but any new ones don't. My servers might all start out the same, but from then on they'll slowly diverge.

# NixOS on Test Laptop

Before committing to reinstalling the OS on one of my "real" computers, it seemed like a good idea to get my hands dirty and play around with NixOS. I've got an old ThinkPad for exactly this purpose. Installing directly on a laptop meant I couldn't lock myself out from SSH or something like that if I made a config error.

The GUI installer was as easy as any other Linux distro I've used. I clicked "next" a bunch of times and then had NixOS running. I was pleasantly surprised that it offered a handful of different window managers (Gnome, KDE, Xfce, and some others) as options during the install. I've always just stuck with the default of whatever distribution I'm using, so it's nice to have a choice right in the installer.

Drivers for wireless were also installed correctly with no trouble right out of the box. This is the kind of convenience and wide support that I go to Ubuntu for, so it's nice to see it elsewhere. It has been a long time since I've used wifi on Linux, so I guess this is just standard now.

Once NixOS was installed, I had a great time editing `/etc/nixos/configuration.nix` and running `sudo nixos-rebuild switch` to see what I'd done. My goal was always to see how I could use NixOS as a host for containers, so I got the laptop set up in the same way I'd set up a server. This involves Tailscale, a separate no-sudo user for Podman, a firewall, [node exporter](https://prometheus.io/docs/guides/node-exporter/), and the correct SSH public keys.

This process was reasonably easy, so I went ahead and created a temporary VPS to try out the server/non-GUI install process.

# NixOS Server Install

I created one of the second-smallest shared-CPU servers on Vultr to test with. I would've used the smallest one, but they're not available in all locations. For interactive use, latency is worth the extra cost. Especially when the cost of running a server for a few hours of tinkering is about $0.10.

My first attempt was to follow the [NixOS installation instructions](https://nixos.wiki/wiki/NixOS_Installation_Guide) on the NixOS wiki. The process basically involves running `fdisk` to partition the drive, generating the `hardware-configuration.nix` file, making some edits to `configuration.nix`, then running `nixos-install` to set up the OS on the newly-formatted drive.

When I realised that I'd have to manually create partitions, I mostly lost interest in NixOS. Both Alpine and Ubuntu have guided installers with a sensible default "wipe the drive and use the whole thing for the new install" option. I can run through `setup-alpine` with my eyes closed. If setting up a new server meant finding the documentation for `fdisk` and working out whether I needed DOS or UEFI partitioning, NixOS probably wasn't going to be for me.

I then found Samuel Ainsworth's [`nixos-up`](https://github.com/samuela/nixos-up) script. It's basically `setup-alpine`, but for NixOS. It partitions your disk, creates a user, sets a password, and delegates to `nixos-install` with a sensible default configuration. I was a big fan.

Sadly my optimism was short-lived. When `nixos-install` runs it needs to evaluate the whole Nix config to understand the intended state of the machine. Doing this—even on a trivial install—takes about 1.7GB of memory. Since I was running on a VPS with 1GB of memory, the process would OOM and the install would fail.

To test this, I created a higher-spec'd VPS with 4GB of memory, and the install completed in a few minutes. This is a useful data point, but not very useful since my actual VPS only has 1GB of memory.

I could just configure a swap file, but I'd have to do that in the booted installer as a separate step before running `nixos-up`. Any subsequent changes to the OS (running `nixos-rebuild switch`) would also require swap, and presumably take the server out of action while it's running, as any other process would be starved of memory.

My next approach was to use [NixOS-Infect](https://github.com/elitak/nixos-infect), which runs on an existing install and swaps the OS in-place to NixOS. I set up a new Ubuntu VM and gave it a whirl.

I had to make a few modifications to the script to not write to `/tmp`, since that's a tmpfs, and doesn't have enough space for NixOS-Infect to work in. The end result was a working install, but it didn't _feel_ robust. It installed an older version of NixOS (from 2024, I think) and the whole process of editing a downloaded shell script to change random paths is not something I want in my server setup process.

There is an alternative. The NixOS config can be built on a remote machine and then the artefacts copied to the target server. No evaluation actually needs to run on the VPS; it can all happen on my (comparatively) beefy local computer.

I vaguely followed the instructions in [this blog post](https://yashgarg.dev/posts/nixos-on-low-memory-servers/). The basic idea is that you can build the config locally:

```console
nixos-rebuild build -I nixos-config=./configuration.nix
```

Then import that into `/nix/store` on the target (low memory) machine:

```console
nix-store --export $(nix-store -qR result) | ssh root@target "nix-store --import --store /mnt"
```

And finally install that result:

```console
$ ssh root@target "nixos-install --system $(readlink result)"
```

The author does say that they create a swap file, but I skimmed over that since their machine only had 512MB of memory, so I assumed that my 1GB machine would be fine.

I'm not completely sure this is the root cause, but despite `nix-store --import` receiving piped input, it does actually need to use a lot of memory to validate the input. Or something like that. The result was that I'd run the command to export from my local machine and import onto the VPS, and it would stall completely. I thought this was because of my slow home internet (copying 5GB of data isn't going to be quick) but I realised later that the `nix-store` process had been OOM killed.

Before I realised that memory was the culprit, I exported the result to an archive, copied the archive up to the VPS, and only then realised that importing from archive was exhausting my memory.

I also tried [`nix-copy-closure`](https://nix.dev/manual/nix/2.35/command-ref/nix-copy-closure.html) but you can't override the destination Nix store path. Since the remote machine was booted from an ISO, I needed to write into the mounted drive, which was at `/mnt/nix/store` instead of `/nix/store`.

During this whole process I was emailing back and forth with my friend Tom, a certified NixOS expert. He did some more research and pointed me to [nixos-anywhere]( https://github.com/nix-community/nixos-anywhere). This was how I wanted NixOS to work.

# NixOS Anywhere

[NixOS-Anywhere](https://github.com/nix-community/nixos-anywhere) allows for a fully declarative install—including partitioning—and then you use the same config to do updates.

In theory you can do the same trick as NixOS-Infect and [`kexec`](https://en.wikipedia.org/wiki/Kexec) from another distribution into your new NixOS install, but for simplicity I booted a NixOS image on the VPS and installed from that.

I followed the [quickstart guide](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md) and used their example configs, merged with the config that I'd created on my laptop earlier. The process basically involves adding a public key so you can SSH in as root, setting the right disk in the [disko](https://github.com/nix-community/disko) config, then running:

```console
$ nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --flake .#<flake name> \
  --target-host root@<ip address>
```

This generates `hardware-configuration.nix` based on the actual target machine and saves it locally. It'll then do all the necessary `nixos-install` stuff for you.

Overall it's a very straightforward process. I've only done it twice though, so maybe there's some other problem I don't know about.

# Verdict

Apart from the installation process, I haven't had _that_ many problems. I basically have no understanding of Nix as a language, so I've just been updating `configuration.nix` by pattern-matching it as a config file, which is fine so far. Tom pointed me to [this reference](https://code.tvl.fyi/about/nix/nix-1p), which I will read at some point.

It is really satisfying to be able to edit a file, do `nixos-rebuild switch`, and then have your system just _be_ updated. I have run into two instances where updating the config just didn't apply changes to the system. The first was changing the user ID of a particular account. That's fair enough, since it would have to delete and recreate the account, but it would be nice if that was an error instead of just doing nothing. The second was when I removed Zsh (since I wouldn't need an interactive shell) and unset it as the login shell. I ended up with an account that still had Zsh as the login shell, but no Zsh binary to run. Explicitly setting Bash as the shell worked, but shouldn't it fall back to some default? Maybe rebooting would have saved me, but like the user ID switch, I would like this to fail at build time or on `switch`.

When something does fail (because I don't know Nix) the error messages are not intuitive. I think a good analogy is the classic JavaScript "`undefined` is not a function" error. It's technically correct from the perspective of the interpreter, but from the programmer's perspective, the error should be "you tried calling method `X` and it doesn't exist".

The command-line interface is also stuck between the old commands (like `nixos-rebuild` or `nix-copy-closure`) and the new unified `nix` CLI. Finding the right command, subcommand, or flag was difficult. You don't have to rewrite it in Rust, but the default behaviour of [Clap](https://docs.rs/clap/latest/clap/) does make very nice and consistent flag handling behaviour with good defaults and error messages.

Everyone that uses Nix seems to use flakes, but it's experimental so all or most of the documentation pretends they don't exist. Any explanation I read of what a flake _is_ reads to me like the unhelpful descriptions of a Haskell Monad. I've definitely made it more difficult for myself by starting from the finish line (installing and using NixOS) rather than building up my understanding of the Nix package manager and how it builds software. But why walk when you can run?

So far only my VPS is running NixOS. I do plan to swap my home server soon, but since it does actually store some useful data I want to be a little more careful with it. I [do have backups](/2026/07/19/backups-with-restic/), but it's even better to not have to use a backup.

My first task is to understand the Nix language enough to structure my existing configurations to allow for most of the stuff to be shared (Podman, SSH, firewall) alongside some server-specific config (hostname, mounts and partitions).
