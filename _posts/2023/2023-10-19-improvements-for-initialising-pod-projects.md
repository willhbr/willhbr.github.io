---
title: Improvements for Initialising Pod Projects
tags: projects podman tools
---

One of the major usability misses with [`pod`][pod] was that it was tricky to setup a new project. My goal was remove the need for language-specific development tools installed directly onto my computer, but whenever I started a new project with `pod`, I would need to run `crystal init` to create the basic project skeleton. With the new `pod init` command, this is now unnecessary.

[pod]: https://codeberg.org/willhbr/pod

To create a new project that wasn't Crystal (like when I was [messing around with Swift websockets](/2023/08/23/the-five-stages-of-swift-on-linux/)) I would manually run a shell in a container using the image for the language and bind mount my working directory. I'd then use the package manager within the container to setup a project (eg: running `swift package init`) and then copy-paste some containerfiles from a previous project. This is incredibly fiddly and tedious. So I added functionality to `pod` that does this automatically.

Now when you run `pod init`, it asks for a base image to use—I use the latest Crystal Alpine image—and runs a container using that image with the working directory already available as a bind mount. Using the shell in that container you can run whatever tools are needed to setup the files for your project (`npm init`, `crystal init`, `cargo init`, etc). When you exit that shell, `pod` will create containerfiles and a `pods.yaml` file for the project, so in most cases you can just build with `pod build` and then `pod run` without any further changes.

Another thing that is more difficult in a container-only world is running REPLs inside the project. I don't do this often—since the Crystal interpreter isn't shipping in the main release yet—but I really enjoyed this way of working when I was using Elixir or Ruby more. Running an `iex` shell where I could recompile and interactively test my code was probably the most pleasant development experience I've ever had, and I wanted to support that with `pod`.

This is now possible with `pod enter`. By default you can run a shell using any of the images in your `pods.yaml` file, or you can configure `entrypoints` and jump straight into a REPL by running a particular command. So for example this:

```yaml
entrypoints:
  iex:
    image: my-elixir-project:dev-latest
    shell: iex -S mix
```

Will allow me to do this:

```shell
$ pod enter iex
Erlang/OTP 26 [erts-14.0.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit]

Interactive Elixir (1.15.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

This bind-mounts the working directory in, so your code is available to any tools that run in the entrypoint. If you've got something more complicated that requires more customisation of the container (like exposing ports or binding additional directories) you can always make a custom `run` target that spawns an interactive shell.

You can imagine that if you were working on a Ruby on Rails project, you might setup something like this:

```yaml
entrypoints:
  console:
    image: my-rails-project:dev-latest
    shell: bin/rails console
```

I've enjoyed working in a container-first and now largely container-only way, and improving `pod` is what has made this possible for me to do. You can [check it out here][pod], specifically the documentation for getting started.
