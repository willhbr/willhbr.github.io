---
title: "Setting up podman-remote"
tags: podman projects homelab
---

[`podman-remote`](https://docs.podman.io/en/latest/markdown/podman-remote.1.html) is a way of running Podman commands on a remote machine (or as different user) transparently. It allows you to add a transparent SSH layer between the `podman` CLI and where the actual podding happens.

For the uninitiated, [Podman](http://podman.io) is basically more-open-source [Docker](https://docker.com) that can be used (mostly) as a drop-in replacement. The biggest difference is that it can run _rootless_—which means even if a process can escape the container, they're still limited by standard unix permissions from doing anything too nasty to the host.

There doesn't seem to be foolproof instructions on setting up `podman-remote` from zero, so I thought I'd write down what I did here. I'll refer to the computer that will run the containers as the "host machine" and the computer that you'll be running `podman` commands on the "local machine".

The first thing to do is log in to the host machine and enable the `podman.socket` system service:

```shell
$ systemctl --user --global start podman.socket
```

On one of my machines I got an error:

`Failed to connect to bus: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)`

I don't know why these environment variables are not getting set, but I managed to find the values they should have, set them, and re-ran the command:

```shell
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$UID/bus
export XDG_RUNTIME_DIR=/run/user/$UID
```

We should be able to see that it's running:

```shell
$ systemctl --user status podman.socket
● podman.socket - Podman API Socket
     Loaded: loaded (/usr/lib/systemd/user/podman.socket; enabled; vendor preset: enabled)
     Active: active (listening) since Fri 2023-03-24 10:38:41 UTC; 1 month 11 days ago
   Triggers: ● podman.service
       Docs: man:podman-system-service(1)
     Listen: /run/user/1000/podman/podman.sock (Stream)
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/podman.socket

Mar 24 10:38:41 tycho systemd[917]: Listening on Podman API Socket.
```

Make note of the `Listen:` path, as we'll need that later. If we're running rootless, it should have the UID of the user that will run the containers in it—in my case that's `1000`.

Next we need to configure how to get to the host machine from your local machine. You can pass this config to the CLI every time, or set it via environment variables, but plopping it all in a config file was the most appealing approach for me. There's even a Podman command that will add the config for you:

```shell
$ podman system connection add bruce ssh://will@hostmachine:22/run/user/1000/podman/podman.sock
```

The first argument is the name of the connection (that we'll use to refer to this particular config). The second argument is a URI that specifies the transport (you can use a unix socket or unencrypted TCP, but SSH is probably best). The URI is in this form (with `$SOCKET_PATH` being the path we noted down earlier)

```
ssh://$USER@$HOST_MACHINE:$PORT/$SOCKET_PATH
```

We should see that `~/.config/containers/containers.conf` has been updated with the new config:

```conf
[engine]
  [engine.service_destinations]
    [engine.service_destinations.bruce]
      uri = "ssh://will@bruce:22/run/user/1000/podman/podman.sock"
      identity = "/home/will/.ssh/id_ed25519"
```

Podman **won't** use your SSH key by default, you need to add the `identity` entry yourself.

So I don't know enough about SSH encryption schemes to explain this next bit. Basically if you use your "normal" RSA key, Podman won't be able to make an SSH connection—seemingly even if manually `ssh`-ing to the host machine works. The solution is to generate a more secure `ed25519` key on the local machine, and use that instead.

```shell
$ ssh-keygen -t ed25519
```

Then append the contents of `id_ed25519.pub` to `authorized_keys` on the host and you're good to go.

Let's test that it works: (replace `bruce` with the name you gave your host)

```shell
$ podman --remote --connection=bruce ps
CONTAINER ID  IMAGE                                 COMMAND               CREATED       STATUS           PORTS                   NAMES
4dd7d2e41348  docker.io/library/registry:2          /etc/docker/regis...  4 days ago    Up 4 days ago    0.0.0.0:5000->5000/tcp  registry
0c986c819fc2  localhost/pixelfed-piper:prod-latest  https://pixelfed....  27 hours ago  Up 27 hours ago                          pixelfed-piper
```

Success! We can now chuck `--remote --connection bruce` (or `-r -c bruce`) into any `podman` command and have it run on another machine. Possibilities include:

- Lazy deployments
- Transparent builds on more powerful hardware (note that `COPY` and such reads from the filesystem on the local machine!)
- Quick debugging of remotely-deployed containers

And probably some more things, I'm quite new to this whole container lifestyle.
