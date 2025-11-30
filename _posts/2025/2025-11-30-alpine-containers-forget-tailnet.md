---
title: "Why Do Containers on Alpine Forget My Tailnet?"
tags: debugging podman
---

Earlier this year I wrote about [how I'd swapped my home "production" server][slim-alpine] over to use [Alpine Linux][alpinelinux]. Overall it's gone well, I swapped the VPS that runs [NZ Topomap of the Day](https://topomap.willhbr.net) ([read more about that][nz-topomap-post]) to Alpine in June, and my [script that sets up an Alpine install](https://codeberg.org/willhbr/alpine-podman-setup) has made this straightforward.

[nz-topomap-post]: /2025/03/28/building-nz-topomap-of-the-day/
[alpinelinux]: http://alpinelinux.org
[slim-alpine]: /2025/03/09/a-slim-home-server-with-alpine-linux/

This weekend I swapped the hardware that I was using for the home "production" server to be a little more recent and reliable, and was reminded of a wrinkle in Alpine that I'd run into before. Thankfully I'd written down some notes that helped me solve the issue again. I can highly recommend keeping notes on random problems you've seen or solved, it's saved me loads of time trying to find the right docs again. Or even better, writing it in a blog post so other people can solve the same problem.

Anyway.

The issue I was seeing was that some containers that need to talk to other devices on my [Tailnet][tailscale] (ie Tailscale network) would just lose the ability to resolve their addresses after a while. Frustratingly this wasn't consistent, it would be working but then a while later it would stop.

[tailscale]: http://tailscale.com

I use Tailscale's [MagicDNS](https://tailscale.com/kb/1081/magicdns) feature which allows you to refer to any device by its hostname instead of the fully-qualified name or IP on the Tailnet. The culprit containers were [endash](https://codeberg.org/willhbr/endash) (my container dashboard) and [Prometheus](http://prometheus.io), both of which connect to other devices on the Tailnet by hostname.

What I learnt is that the MagicDNS feature isn't actually magic, it's just setting a [search domain](https://en.wikipedia.org/wiki/Search_domain) for the unique Tailnet domain name (like `my-tailnet.ts.net`) and running a custom DNS server that resolves these to the Tailnet IP addresses.

This works by setting some config in `/etc/resolv.conf` that looks like this:

```conf
nameserver 100.100.100.100
search my-tailnet.ts.net
```

It's not magic, it's just a config file.
{:class="caption"}

When you create a container, there are a bunch of flags you can pass ([like `--dns`][podman-run]) that override the `resolv.conf` file. If you don't provide any of these options, Podman will use the host DNS configuration from the host's `resolv.conf` file.

[podman-run]: https://docs.podman.io/en/latest/markdown/podman-run.1.html#dns-ipaddr

Where the problem comes in is that some process in Alpine will fight Tailscale and write its own `resolv.conf`, removing the MagicDNS config. Tailscale might rewrite the file, but the config is copied into the container on create and so any containers created while the incorrect config was present will continue to be broken. Updating the file and restarting the container isn't even enough to fix it—you need to delete and recreate the container, since the config is part of its overlay filesystem.

I wish I had a wonderful solution that made all the pieces play nicely together, but instead you can just tell Alpine to please not overwrite the file. In `/etc/udhcpc/udhcpc.conf`, ensure that this section is uncommented:

```conf
# Do not overwrite /etc/resolv.conf
RESOLV_CONF="no"
```

Then make sure `/etc/resolv.conf` is in the state you expect (with `search` for your tailnet and the Tailscale `nameserver`), then delete and recreate any containers that need this DNS config.
