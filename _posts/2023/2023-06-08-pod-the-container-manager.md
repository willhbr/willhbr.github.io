---
title: "pod, the container manager"
tags: projects podman tools
---

I've been working on a project to make development using containers easier (specifically [Podman](https://podman.io)), to remove dependency conflicts, and make it easier to run applications on other servers.

The project is called `pod`, you can learn more at on [Codeberg](https://codeberg.org/willhbr/pod). It's a wrapper around the `podman` command-line tool, with the aim of reducing the amount of boilerplate commands you have to type.

Local versions of both [this website](https://github.com/willhbr/willhbr.github.io/blob/main/pods.yaml) and [my photos website](https://github.com/willhbr/photos/blob/main/pods.yaml) have been using `pod` for a while. This has made it really easy to run a server while I've been making changes, as well as allowing me to easily daemonise the server and have it continue to run in the background.

At its core, `pod` is a YAML file that configures the arguments to a Podman command. Most commands will map one-to-one. The simplest example is something like:

```yaml
# pods.yaml
containers:
  alpine-shell:
    name: pod-alpine-example
    image: docker.io/library/alpine:latest
    interactive: yes
    args:
      - sh
```

This defines an interactive container that runs an Alpine Linux shell. You can start it with `pod run`.

Where `pod` really shines is configuring a setup for a development server, and a production server. As I talked about in [my previous blog post](/2023/06/08/overcoming-a-fear-of-containerisation/), having a development container that mounts the source code from the host machine speeds up development massively. The server behind my [photo publishing system](/2023/05/22/complicated-solutions-to-photo-publishing/) follows this pattern, with this config:

```yaml
defaults:
  build: dev
  run: dev
  update: prod

images:
  dev:
    tag: pixelfed-piper:dev-latest
    from: Containerfile.dev
  prod:
    tag: pixelfed-piper:prod-latest
    from: Containerfile.prod

flags: &default-flags
  feed_url: https://pixelfed.nz/users/willhbr.atom
  repo_url: git@github.com:willhbr/sturdy-guacamole.git

containers:
  dev:
    name: pixelfed-piper-dev
    image: pixelfed-piper:dev-latest
    interactive: true
    autoremove: true
    bind_mounts:
      src: /src/src
    ports:
      4201: 80
    flags:
      <<: *default-flags

  prod:
    name: pixelfed-piper
    image: pixelfed-piper:prod-latest
    interactive: false
    ports:
      4200: 80
    flags:
      <<: *default-flags
      check_period: 54m
```

When I'm ready to deploy a change, I can build a production image with `pod build prod`—which will make a release Crystal build—and then start a container on a server using that image.

`pod` second half is a simple updating system. It will look at the containers running on your server, match their config against the config in `pods.yaml`, and update any containers that have changed. So instead of having to stop and start the prod container myself, I can just run:

```shell
$ pod update --diff prod
```

Which will show the difference and then update the running containers to match the intent. `pod` fully [supports podman-remote](/2023/05/05/setting-up-podman-remote/), so it can handle containers running on a different machine just as easily as it can handle those running locally.

I'm super happy with what `pod` is able to do, and plan on using it to manage building and running any container I use. You can find it on [Codeberg](https://codeberg.org/willhbr/pod), the [project website](https://codeberg.org/willhbr/pod), or read my [previous post explaining some more of the backstory](/2023/06/08/overcoming-a-fear-of-containerisation/)
