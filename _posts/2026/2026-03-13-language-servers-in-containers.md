---
title: "Language Servers in Containers"
tags: tools podman
---


The purpose of [my container-management tool `pod`][pod] is to make it easier to do development and deployment using containers, specifically with Podman. Read more about [why I wrote it](/2023/06/08/overcoming-a-fear-of-containerisation/) and [what it does](/2023/06/08/pod-the-container-manager/).

 Recently I've been trying out the [Helix editor][helix-editor] in place of Vim (more on that once I've been using it some more). The standout feature of Helix for me is first-class [Language Server Protocol][lsp] (LSP) support. This isn't something I'd set up in Vim. I have [Syntastic](https://github.com/vim-syntastic/syntastic) installed and it'll occasionally show me errors.

[helix-editor]: https://helix-editor.com
[pod]: https://codeberg.org/willhbr/pod
[lsp]: https://microsoft.github.io/language-server-protocol/

I wanted to write Swift using [SourceKit LSP][github] in Helix, but sadly Swift only supports up to Ubuntu 24.04 and I'm currently running 25.10. Trying to run the LSP on my newer version will fail as it [can't find `libxml2`][swift-xml-forum]. I could run a VM, run my whole editor in a container, or even downgrade my whole machine to the old Ubuntu version, but there's a better way.

[swift-xml-forum]: https://forums.swift.org/t/ubuntu-25-10-and-libxml2/83239/4
[github]: https://github.com/swiftlang/sourcekit-lsp

LSP works by the editor running a command (like `rust-analyzer`) which exposes a [JSON RPC][jsonrpc] connection using standard input and output to read and write requests and responses. This is great when the LSP command is installed directly on your system, especially because the default Helix config will point it to the right executable without you having to do anything.

[jsonrpc]: https://www.jsonrpc.org/specification

Since the LSP is just running an arbitrary command and looking at the input/output streams, we can just change that command and run the LSP in a container ourselves. The editor doesn't have to know anything about containers. As long as both processes have access to the same files, they'll be happy.

This was a little bit tricky to get working. If the SourceKit LSP gets input it's not expecting it will crash, and if Helix gets back a weird response it'll just do nothing. Thankfully you can debug this a little with the `:log-open` command in Helix, which will show standard error for the LSP command.

Basically we can set the LSP to run something like this:

```shell
$ podman run \
  --workdir=/src \
  --interactive \
  --mount=type=bind,src=.,dst=/src \
  '--entrypoint=["sourcekit-lsp"]' \
  docker.io/library/swift:latest
```

The issue with this is that the editor and the LSP have to agree on the file paths.[^remapping] The editor will say "I'm opening `/home/will/Projects/some_file.swift`" and then since the container has the code in `/src` and has no idea what `/home/will/Projects` is, it'll just fail to do anything. Eventually I got this working by setting the `--workdir` to match the current directory path, but that's finicky.

[^remapping]: Some editors support config to do this remapping themselves, but Helix does not.

In order to make this as easy as possible, I've [added a new `pod lsp` subcommand][pod-lsp-commit] that will manage running the server in a container. It looks at the configured bind mounts and rewrites the requests and responses so the host and container get the paths they're expecting.

[pod-lsp-commit]: https://codeberg.org/willhbr/pod/commit/efabf9d4eaa9441327a2f8465a8112e5dd5e5c5e

The LSP can be configured in the `pods.yaml` config file, either as a standard container:

```yaml
defaults:
  lsp: lsp-container

containers:
  lsp-container:
    image: docker.io/library/swift:latest
    bind_mounts:
      .: /src
    entrypoint: [sourcekit-lsp]
```

This allows for multiple LSPs in the same project, which might be handy. However since this is a tool for me and I'm usually using one language at a time, I added a shorthand LSP config. This will add bind mounts and set the entry point, similar to how development containers work.

```yaml
lsp:
  image: docker.io/library/swift:latest
  command: [sourcekit-lsp]
```

This works for actions and jumping to definitions within your own code, but when you jump to the definition of a standard library type, SourceKit will write a temporary file for the editor to display. That file lives in `/tmp/sourcekit-lsp` inside the container, which the editor doesn't have access to. Of course you can add the appropriate `bind_mount` config, but instead I've made a shorthand `expose_paths` field that will translate into temporary directories on the host that get bound to the paths in the container.

```yaml
lsp:
  image: docker.io/library/swift:latest
  command: [sourcekit-lsp]
  expose_paths:
    - /tmp/sourcekit-lsp
```

Since the config for the LSP lives in `pods.yaml`, you just need one Helix config to point a certain language at Pod instead of a local command:

```toml
[language-server.pod]
command = "pod"
args = ["lsp"]

[[language]]
name = "swift"
scope = "source.swift"
file-types = ["swift"]
roots = ["Package.swift"]
language-servers = ["pod"]
```

I've only just added this, so no doubt there will be changes to the config as I use it more and find the sharp edges. You can [see the code for the feature][pod-lsp-commit] or [read more about pod on Codeberg][pod].
