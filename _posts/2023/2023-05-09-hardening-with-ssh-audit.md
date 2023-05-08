---
title: "Hardening with ssh-audit"
date: 2023-05-09
layout: post
---

My [comment the other day](/2023/05/05/setting-up-podman-remote/) about how I didn't understand SSH encryption or key types very well got me thinking that maybe it's something that I should understand a bit more.

Sadly I still don't understand it, but thankfully you don't have to because of the amazing [`ssh-audit`](https://github.com/jtesta/ssh-audit) tool, developed by [Joe Testa](https://github.com/jtesta) (which is an excellent name for a penetration tester).

It tests both hosts and clients. You either give it the `host:port` to scan, or run it as a server and when a client connects it will print information about the encryption schemes supported by the client. It is not particularly reassuring when you see this printed in your terminal:

> `-- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency`

There are some [hardening guides](https://www.ssh-audit.com/hardening_guides.html) for host and client configs for various distros—to be honest I would have rather just looked at an example config, rather than running a huge command that uses `sed` to edit what it expects to be in there. The huge commands did work, and the client guide even translated over to MacOS.

After a quick test connecting from various devices, I don't seem to have cut off access for anything. I was able to:

- Connect to my Synology DS420j (which has SSH security set to "High")[^synology-security]
- Connect to Ubuntu Server 22.04 from:
  - MacOS
  - [Blink Shell](https://blink.sh)[^default-keys]
  - [Secure Shellfish](https://secureshellfish.app)[^default-keys]
- Push to GitHub

[^synology-security]: The "High" setting scored pretty decently on the audit, enough that I didn't bother trying to alter the config further.
[^default-keys]: Both of these apps generate their own RSA keys, but they're obviously generating with whatever the current recommendations are.

Of course the best bit is that `ssh-audit` is written in Python—so I was expecting to go through `pip` hell—BUT it has a Docker image that you can run instead:

```shell
$ podman run -it -p 2222:2222 docker.io/positronsecurity/ssh-audit host-to-check:port
```

So there's basically no excuse not to just give it a quick check and make sure you're up to snuff.
