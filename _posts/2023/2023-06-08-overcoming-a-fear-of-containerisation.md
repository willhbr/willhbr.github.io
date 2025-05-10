---
title: "Overcoming a Fear of Containerisation"
tags: pod podman opinion
---

I was first introduced to containers at a Docker workshop during my first software engineering internship. The idea was enticing; the ability to package up your applications configuration in a standard way, and run that on a server without having to first to through manually installing dependencies and adjusting configuration. This was while I was still deep in Ruby on Rails development, so setting up servers with things like [Puma](https://puma.io) and [Unicorn](https://en.wikipedia.org/wiki/Unicorn_(web_server)) were all too familiar.

However I never really managed to live the containerised dream. The Docker CLI was clunky (you've either got to write out the tag for your image every time, or copy-paste the image ID), and I couldn't find much information on how to deploy a Rails application using docker without going all the way to [Kubernetes](https://kubernetes.io).

There were tonnes of blog posts that described how to use containers for development, but then said that you should just deploy the old-fashioned way—this was no good! What's the point of using containers if you still have to toil away compiling extensions into nginx?

Another questionable practice I saw was people using one Dockerfile for development and one for production. To me this seemed to be against the whole point of Docker—your development environment is supposed to match production, having two different configs defeats the whole purpose.

Although if we fast forward to sometime earlier this year, when I decided to have a look at Podman and understood more about the tradeoffs with designing a good Containerfile. What I realised was that having one Containerfile is a non-goal. You don't need to have your development environment match production _perfectly_. In fact you want to have things like debug symbols, live reloading, and error pages so the two are never going to be the same anyway.

I shifted my mind from "one config that deploys everywhere" to "multiple configs that deploy anywhere". Instead of having one Containerfile I'd have multiple, but be able to run any of them in any context. If there's a problem only appearing in the "production" image, then you should be able to run a container from that image locally and reproduce the issue. It might not be as nice of a development experience, but it'll work.

---

So then we get really deep into the land of designing effective Containerfiles. Let me take you on a journey.

We'll start out with a simple Ruby program:

```ruby
# main.rb
puts "I'm a simple program"
```

And we'll make a fully productionised[^not-production] Containerfile for it:

[^not-production]: My productionised Containerfile might not match your standards of productionisation. This is for tinkering on in my free time, so corners are cut.

```docker
FROM ruby:latest
WORKDIR /src
COPY Gemfile .
RUN bundle install
COPY main.rb .
ENTRYPOINT ["ruby", "main.rb"]
```

Our development iteration then goes something like:

1. Make a change to `main.rb`
1. Build a new image: `podman build -t my-image .`
1. Run the image: `podman run -it --rm test:latest`
1. Observe the results, and go back to 1

Building the image takes a few seconds, and that's without any dependencies and only one source file. If we're not careful about the ordering of our commands in the containerfile, we can end up with a really slow build. And we have to do that every time we want to run the container! We've just taken the fast iteration of an interpreted language and made it as slow as a compiled one.

Thes is the point that I had previously lost interest in containers, it seemed like a very robust way to slow down development for the sake of uniformity. However, if we allow ourselves to have multiple images we can significantly improve our iteration speed.

The key is to use the development image as a bag to hold all of our dependencies, but not our source code. It has all the pieces the application needs to run (a compiler/interpreter and all our libraries) but none of the source code.

We then use a [bind mount](https://docs.podman.io/en/latest/markdown/podman-run.1.html#mount-type-type-type-specific-option) to mount the source code to the container when we _run_ it—which stops us having to re-build the image every time we make a change to our source files. Development looks something like this now:

1. Make a change to `main.rb`
1. Run the development image:[^long-command]
```shell
podman run --mount=type=bind,src=.,dst=/src -it --rm test:latest
```
1. Observe results

[^long-command]: Wow that's a long command, if only we [didn't have to type that every time!](/2023/06/08/pod-the-container-manager/)

Starting a container has very little time difference from starting a new process, so by omitting the build step we're working at the same speed as if Ruby was running directly on the host. We only need to do the slow re-build if our dependencies change.

When it comes time to deploy our amazing script, we can use a more naive containerfile that copies the source code into the image—build time doesn't matter nearly as much here.

Since I'm writing in [Crystal](https://crystal-lang.org) most of the time, I've ended up with a Crystal containerfile that I'm pretty happy with:

```docker
FROM docker.io/crystallang/crystal:latest-alpine
WORKDIR /src
COPY shard.yml .
RUN shards install
ENTRYPOINT ["shards", "run", "--error-trace", "--"]
```

This installs the dependencies into the image, and sets the entrypoint so that arguments will be passed through to our program, instead of being interpreted by `shards`. The source files are mounted into the container in the same way as with the Ruby example.

I noticed that builds were always a little slower than I would expect, and remembered that Crystal caches some build artefacts, which would get thrown away when the container exited. So I mounted `~/.cache/crystal` in the container to a folder, so that it would be persisted across invocations of the container. Doing this sped up the builds to be in line with running the compiler directly.

This frees me up to have a fairly involved "production" containerfile, optimising for a small final image:

```docker
FROM docker.io/crystallang/crystal:latest-alpine AS builder
WORKDIR /src
COPY shard.yml .
RUN shards install
COPY src ./src
RUN shards build --error-trace --release --progress --static

FROM docker.io/alpine:latest
COPY --from=builder /src/bin/my-project /bin/my-project
ENTRYPOINT ["/bin/my-project"]
```

Living the multi-image lifestyle has meant that I can use containers to run any one of my projects (including when I run this website locally to make changes) in the same way without having a major development experience impact.

Although these commands are quite long, and I can't type that fast or remember all those flags. So [I made a command-line tool](https://pod.willhbr.net) that makes dealing with multiple images or containers easier. _That's_ actually what I have been using to do my development, and to run projects on my home server. You can read more about it:

- [In my other blog post](/2023/06/08/pod-the-container-manager/)
- [On Codeberg](https://codeberg.org/willhbr/pod)

The tl;dr is that with some fairly simple config, I can run any project with just:

```shell
$ pod run
```

Which runs a container with all the right options, even simpler than using `shards run`.
