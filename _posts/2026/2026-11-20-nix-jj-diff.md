---
title: "Comparing Nix Derivations in a JJ Repo"
tags: homelab jujutsu
---

So far with NixOS I've been making changes to my `configuration.nix` and then running `nixos-rebuild switch` and seeing what happens. This has worked out so far, but I've just swapped my home server over to NixOS, which means breaking it could have consequences.

Switching my home server means I now have two separate Nix configs, and I'd really like them to be merged together, so all the common bits aren't duplicated a bunch of times. I could just try to refactor the Nix code and assume I'd got it right, but I really want to be sure that I haven't messed something up. Obviously if I mess it up really badly it won't build, but I'm more worried about accidentally removing all my SSH authorised keys, or something like that.

Thankfully there is a simple solution. The easiest thing you can do is build both versions and check if they point to the same path in the Nix store, but that's a bit of a hassle to do manually. It's also only good for verifying changes are identical, what do you do if they point to different things?

[`nix-diff`](https://github.com/Gabriella439/nix-diff) to the rescue! You give it to derivation paths, and it'll give you a (huge) output showing all the things that have changed. So if you remove an authorised key, that'll show in the diff.

To make this easier to work with, I've written [a script](https://codeberg.org/willhbr/dotfiles/src/commit/34107b121cd44a91fda89cb97600cefbe43ffbed/bin/nix-jj-diff.rb) that will get the derivation paths automatically, and pass them to `nix-diff`.

There are a few different derivation paths that you might want to compare. The simplest thing is to just build the current config and print the derivation path:

```console
$ nix eval --raw '#nixosConfigurations.yak.config.system.build.toplevel.drvPath'
/nix/store/xipq58d8c3x2ik0l64nv6xncf8ffy8dj-nixos-system-yak-26.11.20261116.e21fec3.drv
```

I could run that, note the path, make some edits, re-run the command, and pass the pair of paths to `nix-diff`. It's more useful to get the derivation that is currently being used by the live server, and compare against that:

```console
$ ssh root@yak "nix-store -q --deriver /run/current-system"
/nix/store/xipq58d8c3x2ik0l64nv6xncf8ffy8dj-nixos-system-yak-26.11.20261116.e21fec3.drv
```

Since I build everything locally, everything is guaranteed to be in my local `/nix/store`, so I have all the information necessary to `nix-diff` them.

Comparing the current config versus the live machine is what you'll want before you deploy (that's why I implemented the same thing in [Pod](https://codeberg.org/willhbr/pod)). However, I wanted to be sure that individual changes that I was making locally weren't making unintended changes, so I made my script work between JJ revisions.

This way I can diff what's changed between two commits, and make sure that lines up with the edits I made to the `.nix` files. You can build a derivation from a particular Git commit hash like this:

```shell
nix eval --raw \
  "git+file://$REPO_PATH$?rev=$COMMIT$&dir=$SUBDIR#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath"
```

It's a bit of a mouthful, which is why I wrote the script. Instead, I can just run:

```console
$ jj nix-diff yak
```

Which will show me what's changed between `@` and `@-`. I can also pass a custom revset to compare a chain of commits.

A nice improvement here could be for `nix-diff` to highlight some diffs (systemd services, open ports, users, etc) with special formatting, instead of the current generic diff, which can get very large and hard to follow.
