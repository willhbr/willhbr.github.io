---
title: "Some Hot JJ Tips"
tags: tools
---

I spent a bunch of time learning how to use JJ properly after I [gave up on git](/2024/04/01/its-not-me-its-git/). Up until this point, I had been dumping commits directly onto `main` and just pushing the branch occasionally. I had avoided learning the pull/merge request flow because it's not something I use on personal projects, but it turns out to work pretty well. With a few tactically-deployed aliases I've got a pretty simple flow going.

We start a new change with `jj new`, and make some edits to some files. We'll end up with something like:

```
@  lw Will Richardson now 2
│  (no description set)
◉  w Will Richardson ago main main@origin HEAD@git 03
│  Bump version number to 0.8.1
~
```

Once we've made some changes and got stuff working, we'll give it a commit message with `jj commit -m 'do some stuff'`. With that super meaningful commit message, I'm ready to send this change for review. The easiest way to do this is to use `jj git push -c lw` (`lw` is the change ID we're pushing):

```shell
$ jj git push -c lw
Creating branch willhbr/push-lwwlpunxnpnu for revision @-
Branch changes to push to origin:
  Add branch willhbr/push-lwwlpunxnpnu to af2e2412e623
remote:
remote: To create a merge request for willhbr/push-lwwlpunxnpnu, visit:
remote:   https://gitlab.com/willhbr/.../-/merge_requests/new?merge_request?...
```

JJ auto-creates a branch for us based on the change ID. I've customised this with the `git.push-branch-prefix` option to include `willhbr/` at the front so I know it's mine.

The change has been pushed, and the remote—GitLab—has given us a handy link to create a merge request. This command is a bit wordy, so I've got an alias that will push the change automatically:

```toml
[aliases]
cl = ['git', 'push', '-c', '@-']
```

A little side note: `@-` refers to the parent of the current change, since when I'm running this I will have just created a new commit, and my log will look like:

```
@  x Will Richardson 4 minutes ago 6
│  (empty) (no description set)
◉  lw Will Richardson 4 minutes ago HEAD@git a
│  do some stuff
◉  w Will Richardson 1 month ago main main@origin 03
│  Bump version number to 0.8.1
~
```

So to push that first non-empty, non-working-copy commit I use `@-` as the change ID.

Now I just need to wait for someone to review and approve the merge on GitHub or GitLab or whatever, and do the merge via the web UI. Once that's done, I can fetch changes from the remote, and my changes will disappear from the default log view as they're now just part of `main@origin`.

Depending on how the remote is setup, we might have to do one more step. If the changes were merged into the main branch, the commit hashes remain the same and everything works normally—JJ knows the commits now in `main` are the ones you authored. This is the default behaviour in GitHub and GitLab. However, if a GitHub project is setup to rebase or squash into `main`, you'll end up seeing duplicate changes. This is because the commit hashes get updated when they're rebased, so JJ can't reconcile them when it fetches new changes. If you rebase your existing changes on top of main, your local changes will become empty—since their content is already present in the other commits. Instead when you rebase, pass `--skip-empty`, and these empty commits will be dropped.

I've got two more aliases to make this easier:

```toml
[aliases]
sync = ['git', 'fetch', '--all-remotes']
evolve = ['rebase', '--skip-empty', '-d', 'main']
```

So I just `jj sync` to get all the changes from the internet, and then `jj evolve` to put my changes back on the new location of `main`.

If you use a web UI to accept some changes based on reviewer feedback, the next time you `jj sync`, the changes will be added to your local branch. You could then make further edits, or squash the suggested changes back into the original commit to have a cleaner history.

If you make any alterations locally the branch name in the log will have an asterisk after it to indicate that it has changes that need to be pushed. Update all branches with `jj git push --all` (I have this aliased to `jj upload`).

Something of note is that if you have two changes in succession (one is the parent of the other) and you make two pull requests from them, the child pull request will contain _all_ the content from both changes. Unless your code review tool has some way to change the base of the diff[^iykyk], you'll want to get them reviewed in sequence. Alternatively, if the child change doesn't actually depend on the parent—perhaps it's just an unrelated bug fix you made while working on a feature—you can just rebase it to be a sibling of its parent

[^iykyk]: If you know, you know.

If you end up in this situation, and now want to get that bug fix submitted ASAP, but it's currently sitting on top of a huge feature that'll take ages to get reviewed:

```shell
$ jj log
@  q Will Richardson HEAD@git a
│  Fix how the bugs are created
◉  u Will Richardson 9
│  Implement a huge feature
~
$ jj rebase -s @ -d @--
@  q Will Richardson 0c
│  Fix how the bugs are created
│ ◉  u Will Richardson u
├─╯  Implement a huge feature
~
```

That little rebase trick takes the current change and moves it to be a sibling of its parent. I've used the `hg` equivalent of this for years to get code merged that I had written in the opposite order I should have.

---

I've got some aliases to make it easier to quickly get going with a JJ repo. I've only been using colocated JJ/git repos, which means there's both a `.git` as well as a `.jj` directory, so any git tool or command also works with no modification. In my `~/.gitconfig` I have:

```toml
[alias]
jj = "!jj git init --git-repo=."
setup = "!git init && git jj"
```

This allows me to run `git jj` in an existing repo, or `git setup` to get from no version control immediately to good version control, with no intermediate steps.

In my `~/.jjconfig.toml` I have a bunch of aliases, I'm not fully settled on these but here they are anyway:

```toml
[aliases]
# Old init alias, before I added the aliases in git
ig = ['git', 'init', '--git-repo=.']

# If I want to just push directly to main
# This just sets it to be the second-latest commit
setmain = ["branch", "set", "main", "-r", "@-"]
# Sync everything, mentioned above
sync = ['git', 'fetch', '--all-remotes']
# Put stuff back on top of main
evolve = ['rebase', '--skip-empty', '-d', 'main']

# Do a full log, rather than just the interesting stuff
# Basically the same behaviour as the default git log
xl = ['log', '-r', 'all()']
# Progression log? Shows how the current change has evolved
# A bit more on this later
pl = ['obslog', '-p']

# Pushing changes and auto-creating branches
cl = ['git', 'push', '-c', '@-']
push = ['git', 'push', '-b', 'glob:willhbr/push-*']
upload = ['git', 'push', '--all']

# This might be useful, opens an editor to set per-repo settings.
configure = ['config', 'edit', '--repo']
```

Ok, about that `jj pl` alias. `jj opslog` will show the progression of a commit, so you can view or revert back to an intermediate state without having to actually make intermediate commits. So if you do a bunch of work, and get stuff working, and then decide to make everything better but actually make a huge mess of it, you can get back to the middle state even if you forgot to commit at that point. Here's the progression for my website while I've been working on this post:

```shell
$ jj obslog
@  z Will Richardson 13 seconds ago a
│  (no description set)
◉  z hidden Will Richardson 1 hour ago a6f
│  (no description set)
◉  z hidden Will Richardson 3 hours ago b2a3
│  (no description set)
◉  z hidden Will Richardson 3 hours ago 80f
│  (no description set)
◉  z hidden Will Richardson 3 hours ago 2e
   (empty) (no description set)
```

The `-p` option shows the patch diff between each version, so I can quickly see what I had changed.

The big caveat is that this only works at points in time where you ran a `jj` command. If you haven't run `jj status` or `jj log` or whatever, it won't have picked up your changes.[^watcher]

[^watcher]: It does have some filesystem watcher, which I assume will keep this fully up-to-date, but I assume you're not running that.

This is a side-effect of the working-copy-as-commit model, so every time you modify a file and run a JJ command, it amends the changes into the working copy commit. However this just creates a _new_ commit (that's how git works), so you're leaving a trail of commits as you work. `jj opslog` just exposes that trail to you. I don't think I'd rely on this—I'd rather create a bunch of commits then squash them later—but having this as a backup just gives me more confidence that I can find something I've lost in a pinch.

Most of my learning was done reading the JJ docs on [working with GitHub and GitLab](https://martinvonz.github.io/jj/v0.17.1/github/), and perusing the [CLI Reference](https://martinvonz.github.io/jj/v0.17.1/cli-reference/). I also read [`jj init`](https://v5.chriskrycho.com/essays/jj-init/) by Chris Krycho the other day and enjoyed his detailed look at things.
