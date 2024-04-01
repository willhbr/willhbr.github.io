---
title: Build and Install Tools Using Containers
tags: podman pod
---

Another challenge in my quest to not have any programming languages installed directly on my computer is installing programs that need to be built from source. I've been using [`jj`](https://github.com/martinvonz/jj) in place of Git for the last few months[^jj-review]. To [install it](https://martinvonz.github.io/jj/v0.12.0/install-and-setup/) you can either download the pre-build binaries, or build from source using `cargo`. When I first started using it there was a minor bug that was fixed on main but not the latest release, so I needed to build and install it myself instead of just downloading the binary.

[^jj-review]: Short review, it's good but has a long way to go. Global undo is excellent, and I like the "only edit commits that aren't in main yet" workflow.

Naturally the solution is to hack around it with containers. The basic idea is to use an base image that matches the host OS (Ubuntu images for most languages are not hard to come by) and build in that, and only copy the executable out into the host system.

To install `jj` and `scm-diff-editor` I make a `Containerfile` like this:

```
FROM docker.io/library/rust:latest
WORKDIR /src
RUN apt install libssl-dev openssl pkg-config
RUN cargo install --git https://github.com/martinvonz/jj.git --locked --bin jj jj-cli
RUN cargo install --git https://github.com/arxanas/git-branchless scm-record --features scm-diff-editor
COPY install.sh .
ENTRYPOINT /src/install.sh
```

This just runs the necessary `cargo` commands to install the two executables in the image. The `install.sh` script is super simple, it just copies the executables from the image into a bind-mounted folder:

```bash
#!/bin/bash
for bin in jj scm-diff-editor; do
  cp "$(which "$bin")" "/output/$bin"
done
```

So the last part is just putting it all together with a [`pod`](https://pod.willhbr.net) config file:

```yaml
images:
  jj-install:
    tag: jj-install:latest
    from: Containerfile
    build_flags:
      cache-ttl: 24h

containers:
  install:
    name: jj-install
    image: jj-install:latest
    interactive: true
    autoremove: true
    bind_mounts:
      ~/.local/bin: /output
```

I can then run `pod build` to create a new image and build new executables with `cargo`. Then `pod run` the container to copy them out of the image and into the `$PATH` on my host system.

This is the same approach I used for [the automatic install script for `pod`](https://github.com/willhbr/pod/blob/main/install.sh) itself—except using `podman` commands directly rather than a `pod` config. I've done the same thing to install [`rubyfmt`](https://github.com/fables-tales/rubyfmt) since that is only packaged with Brew, or requires Cargo to build from source.

I'm sure at some point an incompatibility between libraries inside and outside of the container will create a whole host of bizarre issues, but until then I will continue using this approach to install things.
