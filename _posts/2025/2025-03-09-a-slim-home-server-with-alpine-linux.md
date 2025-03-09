---
title: "A Slim Home Server with Alpine Linux"
tags: homelab
---

Like any normal person, I have many computers. Most of these computers run Ubuntu, since that's what I'm used to and it's easy to find documentation for Debian-based systems. However, everything that runs on my home server—the main home server, not my development server which is completely different—is inside a container. This makes the host OS is basically irrelevant. It does feel somewhat counter-initiative to run a full-featured server OS with all the bells and whistles just to host containers. I'm not storage constrained here, but I am interested in reducing the storage overhead of the OS for use on VPSes.

I was a bit hesitant with switching to Alpine, given that all I really know is Debian-based systems, and if you mention using Alpine with containers no one expects the Alpine to be running on the _outside_. I came across [Wesley Moore's post](https://www.wezm.net/technical/2019/02/alpine-linux-docker-infrastructure/) where he'd done basically the same thing, and [seemed happy about it three years later](https://www.wezm.net/v2/posts/2022/alpine-linux-docker-infrastructure-three-years/). This made me a lot more confident that I wasn't going to run into some insurmountable problem.

The first task in this project was to work out exactly how to get rootless podman-remote working on Alpine, since most of the instructions assume you've got systemd. Instead of using my local machine for testing, I repeatedly re-created a VPS and ended up spending $0.24. I [wrote exactly how I set this up][alpine-podman] before. Doing this setup over and over and over meant that all the mistakes and misconfigurations could be worked out quickly, and by the time I was ready to do the install on my real hardware, I knew exactly what needed to be done and how to do it.

[alpine-podman]: /2025/01/18/configure-rootless-podman-remote-on-alpine-linux/

Most of the action will be happening inside the containers, but there are two things that I run directly on the host: [Tailscale](http://tailscale.com) and [node-exporter](https://github.com/prometheus/node_exporter). I was pleasantly surprised that Tailscale is packaged for Alpine (`apk add tailscale`) which is nicer than having to download and execute the install script—even if the packaged version isn't the most up-to-date.

There isn't much to setup here, I just used `ufw` to block all ports except `22`, `80`, and `443`. I can access things via Tailscale or Caddy anyway. [My setup script][setup-script] overrides `/etc/conf.d/podman` and `/etc/ssh/sshd_config` with to [get podman-remote working][alpine-podman].

[setup-script]: https://codeberg.org/willhbr/alpine-podman-setup

On my Ubuntu install I had been running [Caddy](http://caddyserver.com) on the host, but I wanted to move this into a container so that it could be updated in the same way as everything else. Otherwise I'd have to SSH into the machine and manually edit the config file.

I want all my containers to be rootless, which meant I needed to allow non-root users to bind to ports below 1024. This is configured in `/etc/sysctl.conf`, I've set it to 21 so I can have Forgejo bind an SSH server to port 22 in the future:

```conf
net.ipv4.ip_unprivileged_port_start=21
```

I've also committed a bit more to using Caddy alongside Tailscale to simplify how I access services. Previously I just relied on Tailscale's "Magic DNS" feature where they'd resolve the hostnames of any device in your VPN. I would navigate to `http://steve/` and see my custom container dashboard (post about that coming any day now), and then click on a link to get to the UI for any particular container. This setup is a bit cumbersome as there's an intermediate step preventing you from going directly to a particular service.

What I've replaced this with is a combination of a custom DNS entry, Tailscale's "search domain" feature, and a Caddy reverse proxy.

I have a wildcard match on an old domain I still own so that any subdomain will resolve to the Tailscale domain name for my home server. This is just adding a `CNAME` record with a host of `*` and a value of `$server-hostname.$my-tailnet.ts.net`. Any request to a subdomain will be directed to my home server, routed inside the VPN.

My server then runs Caddy with a very basic configuration for each container I want to make accessible:

```conf
grafana.willhbr.net:80 {
  reverse_proxy host.containers.internal:61300
}
```

Requests to `grafana.willhbr.net` will be forwarded to the container running on port `61300`. I no longer have to use semi-memorable port numbers or navigate through my dashboard, instead just visiting `grafana.willhbr.net` and immediately see graphs.

This can be made a little bit neater with a [search domain](https://tailscale.com/kb/1054/dns#search-domains). By adding the domain in here, any hostname that doesn't resolve will get directed to my home server. I don't know _exactly_ what the limitations of this are—I assume it won't absorb all my traffic for any domain that doesn't resolve—but the end result is that I can visit `http://grafana/` and Caddy running on my home server will receive the request and route it appropriately based on the domain. I just have to add `grafana:80` as another host for the reverse proxy.

I still access some services through my container dashboard, but those that I access the most are now setup to proxy through Caddy with a custom subdomain. This simplifies my FreshRSS client config, the address is now just `http://rss/` and I'm free to move that around just by updating the Caddy config.

I had been looking at improving how I managed my home server for a while. [Fedora CoreOS](https://fedoraproject.org/coreos/) was really tempting, especially after reading how [people used it on home servers](https://major.io/p/coreos-as-pet/). In the end that was too much of a departure from what I'm used to—maybe I'll come back to it later—and so a container-first usage of a more traditional OS was a good middle ground for me.

Another option would have been to embrace [quadlets](https://www.redhat.com/en/blog/quadlet-podman), again after [seeing other people use it successfully](https://matduggan.com/replace-compose-with-quadlet/). A benefit is that you can setup some auto-updating policies, which would be great for a lower- or no- touch environment, but I'm tinkering fairly regularly and so it's not a big deal for me to re-build and run [`pod update`](https://pod.willhbr.net). This also seems less well-suited to running ad-hoc containers—I like using podman-remote to just start something running on another machine, without having to copy a config file anywhere.

There are a few issues that I've run into, the most significant is [that `podman stats` will not show information for individual containers](https://github.com/containers/podman/issues/9502). This is quite annoying as I gather this information with Prometheus and like to see how each container is doing. In reality the RAM utilisation is so low on this server it doesn't really matter.

Alpine uses [busybox](https://www.busybox.net), and I ended up getting frustrated with the more limited `less` implementation. It doesn't support `C-u` and `C-d` for scrolling, and doesn't handle transparently passing output to the terminal based on the window height quite the same as GNU less. I eventually realised I could just `apk add less` and get [the version](https://pkgs.alpinelinux.org/package/edge/main/x86/less) I'm used to.

I'm still not sure whether I'm going to commit to using Alpine on my development machine. The tools I use are pretty common and are packaged for Alpine, and anything that's a bit weird I will be running in a container anyway. Before I realised I could install the GNU version of less, my experience using any command line tool was frustrating as my muscle memory would expect the same passthrough and scrolling behaviour.

Ubuntu will probably stay on this machine for a while, maybe when it's due for wipe and reinstall I'll come back to this decision. For my home server and any VPSes that I don't have to directly interact with, I'm pretty happy with my Alpine setup.

If I were to continue this a bit more, I'd like to get the setup more automated. To do an OS install on my servers I have to move them to get a monitor and keyboard connected so I can do the initial setup manually. I don't do this often so it's usually not a big deal, but it would be nice to just build an image onto a USB drive, plug it in and have it boot into a remotely-accessible environment where I can run an automated setup script.
