---
title: "Configure Rootless Podman Remote on Alpine Linux"
tags: podman homelab
---

I thought this was going to be easy. I've [been using](/2023/05/05/setting-up-podman-remote/) `podman-remote` to manage containers across my two home servers for ages, but only ever on Ubuntu. It turns out there are a few tricky things that aren't easy to debug or documented anywhere, so here's how to get rootless `podman-remote` working on an Alpine Linux host.

Podman is available in the community APK repository, so either enable that during setup, or uncomment the line in `/etc/apk/repositories` then run:

```console
$ apk add podman
```

You'll then need to assign some more user IDs to yourself. I don't fully understand the mechanics of the user ID business in Podman, but you just need to edit these two files (changing the username, obviously):

```console
$ echo will:100000:65536 > /etc/subuid
$ echo will:100000:65536 > /etc/subgid
```

Then enable and start the `cgroups` service:

```
$ rc-update add cgroups
$ service cgroups start
```

Now you should be able to run a container:

```console
$ podman run -it alpine:latest
/ #
```

That's great, but we want `podman-remote`. On Debian systems you just need to [start a user-level `systemd` unit][setting-up], but we don't have `systemd` on Alpine. Thankfully podman has an OpenRC config, which we just need to tweak to run rootless.

[setting-up]: /2023/05/05/setting-up-podman-remote/

All the `systemd` unit is actually doing is running the [`podman system service`](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) command. That will start a server that listens on a UNIX or TCP socket and exposes the Podman API. You can run it yourself without any supervision:

```console
$ podman system service -t 0 unix:///home/will/podman.sock
...
```

Then in a separate console you can connect to that socket using `podman --url unix:///home/will/podman.sock`.

We do want our podman to be supervised, however. We just need to edit `/etc/conf.d/podman` to set the URI and user that Podman will run as:

```conf
# /etc/conf.d/podman
podman_uri="unix:///home/will/podman.sock"
podman_user="will"
```

This assumes that we'll only have one podman-remote user. I don't know what you need to do to get multiple users working, but since I'm just wanting to get one rootless user to manage my containers, this should be fine.

We can then enable and start the `podman` service:

```console
$ rc-update add podman
$ service podman start
```

This will now start the podman daemon on boot using the socket and user we configured. Before we get remote access working, check that you can connect to the socket:

```console
$ podman --url unix:///home/will/podman.sock ps
CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES
```

And then on your remote machine, check that you can connect over SSH:

```console
$ podman --url ssh://will@alpine-server:22/home/will/podman.sock ps
```

Podman will likely complain about not being able to open the connection, which after much trial and error I worked out was because the default Alpine OpenSSH config doesn't enable TCP forwarding, whereas the Ubuntu config does. I enabled it in `/etc/ssh/sshd_config`:

```conf
# /etc/ssh/sshd_config
AllowTcpForwarding yes
```

After restarting `sshd` (`service sshd restart`) that should be enough to get things working.

At this point you should add the config to `~/.config/containers/containers.conf` so you don't have to type out `--url` every time:

```conf
[engine.service_destinations.alpine-server]
uri = "ssh://will@alpine-server:22/home/will/podman.sock"
identity = "/home/will/.ssh/id_ed25519"
```

Then you can run `podman -c alpine-server` to do anything on the remote machine.

Originally I ran into a problem at this point where podman would constantly complain of mismatching host keys, but connecting with `ssh` would work just fine. If I deleted the entry in `.ssh/known_hosts` and connected with podman first it would work, but then connecting with `ssh` would complain of a mismatching key. Eventually I worked out that I could re-order the keys in `.ssh/known_hosts` and have both work, but that seemed like a horrible hack.

I thought this was a difference in the Go SSH client and the OpenSSH CLI, but it ended up being the hardened SSH config that [I setup a while ago](/2023/05/09/hardening-with-ssh-audit/). The `ssh` CLI wouldn't add the `ecdsa-sha2-nistp256` key, whereas Podman would _only_ add that key. The end result is they both think something nefarious is going on because the key in `known_hosts` doesn't match. Adding the hardened sshd config from [ssh-audit](https://ssh-audit.com) would make it work because Podman would be forced to use `ssh-ed25519` instead, which is what `ssh` expects. Removing the hardened ssh config from the client made it work without any issues as `ssh` would add the `ecdsa-sha2-nistp256` key to `known_hosts`, so Podman would see what it expected.

The aim of this exercise was to be able to setup a minimal host OS install with a single non-root user that will run containers. The host OS should have as little as possible installed, and the setup should be as scriptable as possible. Automating the setup in this post is a story for another time.
