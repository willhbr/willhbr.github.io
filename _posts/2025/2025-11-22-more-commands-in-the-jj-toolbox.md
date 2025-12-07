---
title: "More Commands in the JJ Toolbox"
tags: jj tools
---

It's been almost two years since I started using JJ regularly, and almost 18 months since I [wrote some tips on how to use it][jj-tips]. That post was really just the result of me reading the docs (which at the time were much sparser than they are now) and working out how to manage remotes properly.

[jj-tips]: /2024/05/26/some-hot-jj-tips/

That was a long time ago, and I've had more time to settle into a rhythm and realise what works for me and what doesn't.

Before I get too carried away, I want to get up on my high horse for a second. I found a repo that boasted "over 20 aliases for efficient workflows" and I just want to say: no. You don't need lots of aliases. Aliases that you don't know are useless. Having to remember which letter salad corresponds to the exact combination of flags you need is not saving you time.

Seriously, the oh-my-zsh git plugin [defines over 200 aliases][omz-git]. Something has gone terribly wrong.

[omz-git]: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/README.md

I have seven VCS-related shell aliases, which is the amount of letter salad that I can handle.

```shell
alias g="jj"
alias gs=" g status"
alias gd=" g diff"
alias gcm=" g commit -m"
alias gc=" g commit"
alias gl=" g log"
alias gp=" g push"
```

Anyway this post isn't supposed to just be [complaining about git][git-bad]. We're here for tips.

[git-bad]: /2024/04/01/its-not-me-its-git/

# Grab other versions of files with `restore`

The command I'm surprised by my usage of is `restore`. Since this is such a messy concept in git (are you discarding untracked, unstaged, or staged changes?) I wasn't in the habit of doing this. The only command I knew was `git checkout -- .` which would blow away any tracked changes and get you to an empty working copy. It's not a very precise operation.

I've got basically three different usages of `restore`. The first is when I've got a change but it contains some debugging code or something that I don't want to be included when I send it out for review. I'll use `jj restore -i` to show the interactive diff editor and select the bits I want to get rid of.

If I've got a commit and I'm working on top of it, sometimes I want to drop a file back to its state on the main branch. I could just rebase the commit I'm working on, but `restore` makes it easy to get a file to the state it was in on a different revision, usually `main`. I'll do this with `jj restore -f main path/to/my/file.txt` and now my working copy has the updated file.

If you think about it, `jj duplicate` is just `jj restore` with all files into an existing empty commit.

The last use is the predictable one, if I've made some change and it's just plain bad, I'll do `jj restore` with no extra arguments to simply discard my changes. This is equivalent to `jj abandon` but feels a little safer.

Of course that safety doesn't really matter, since I can `jj undo` anything anyway. This has been surprisingly handy if I get myself into a state with lots of merge conflicts, or accidentally run a command with the wrong flags. It just removes the risk associated with making a mistake, which means I don't have to be particularly confident that any one command will do exactly what I expect. If it doesn't, I'll just undo and check the docs.

# Irresponsibly juggle revisions with `rebase`

I did define an alias `onmain` that would move the working copy to be based on `trunk()` instead of wherever it is currently. It's fine, it works, but to be honest it's easier to just do `rebase -d main`.

Initially I think I got a bit confused with the `-r` flag to `rebase`, but once I realised `-s` (or `--source`) and `-d` (or `--destination`) do exactly what you want, I've had no trouble.

You can get a little fancy with `-A` and `-B` (`--insert-after` and `--insert-before`) which lets you splice a change right in-between two others, but this is a bit too much for me to remember. I'll just run `rebase` twice.

# Move changes between revisions with `squash`

Something I thought I'd miss in JJ is the lack of an equivalent to [`hg histedit`][histedit]. This opens a nice TUI that works similarly to an interactive rebase in git. You can choose for each commit whether you want to fold or edit or whatever, and then you say "go" and it does it all.

[histedit]: https://wiki.mercurial-scm.org/HisteditExtension

I'd use this to reorder commits (so one change could get submitted before another) but often all I would do was make a dummy commit, then reorder it to be on top of a commit further down in the history, then fold them together. This is just a really roundabout way of doing `squash`. So instead of all that nonsense, I'll just run `jj squash -d xyz` and the working copy changes will be moved into commit `xyz`. If I don't want to move all the files, I'll use `-i` to select them interactively. I find the interactive selection easier than passing file paths as arguments most of the time.

In Mercurial I'd use `hg absorb` for this same job, which is still present as `jj absorb`. However, neither match up the edits to the right commit every time, so using `jj squash` is more predictable.

It's worth using a little bit of your brain space to learn what the "default" arguments are to various JJ commands. For example with `squash` if you give it no arguments it takes all the changes from the current commit and moves them to the parent. If you provide a revision with `-r` then it'll move the changes from that to its parent. If you provide `-f` it'll squash from that revision into the current one, if you provide `-t` then it'll squash from the current into that. Other commands like `rebase` and `restore` have similar behaviour.

Of course it's not difficult to just always pass `-f` and `-t`, but once you get a little fancy you can throw in some revset expressions (like `xyz::` to get all descendants) and do some clever nonsense.

# Doing fancy revset expressions

Speaking of revset expressions, since I spent a bit of [time learning the syntax][revset-learning] I'll find occasions to use a revset to replace a set of tedious commands with a single command.

[revset-learning]: /2024/08/18/understanding-revsets-for-a-better-jj-log-output/

I wrote a script to make automated changes to a codebase, and it would do `jj new` before making any changes. For some files it would make no changes and I'd be left with an empty commit. There were two ways that I ended up solving this, I could get rid of all the empty commits with `jj abandon 'empty() & mutable()'`, or I could merge everything back into one commit with `jj squash -f 'mutable()' -t @` (remembering that I could totally omit that `-t @` and leave it implied).

Obviously most of the time it's easier to just write the revision ID, use a simple expression like `@-`, or a branch name like `main`, but it's nice having this in your repertoire for scripting or one-off weirdness.

In a way this is similar to Vim commands; you can get away with super basic editing and movement commands, but if you can remember a few tricks like `diw` or `ci{` you'll be able to get things done more smoothly.

# Scripting with the power of `-T`

Originally—for some reason—I thought I'd leave scripts using git. I have no idea why I thought this, scripting with JJ is so much easier. I find the documentation a little confusing, but almost every command accepts a `-T` or `--template` flag that dictates how the output is formatted. It is then easy to write a command that outputs just the fields you need in JSON that is trivial to parse in almost any language. This is what I did when I wrote (and then re-wrote) my [project progress printer][ppp].

[ppp]: /2025/04/26/writing-in-crystal-rewriting-in-rust/

The simpler model also makes scripting easier as you don't have to worry about the working copy state, or things like where you're going to `git pull` from. I just run `jj sync` (aliased to `jj git fetch --all-remotes`) and the repo is updated.

An alias that makes a lot of scripts easier is my `jj ls` alias, which lists the files touched by a particular change:

```toml
ls = ['log', '--no-graph', '-T', 'diff.files().map(|f| f.target().path()).join("\n") ++ "\n"']
```

This makes use of the template to process the list of changes files into a list of paths and then join them into a string. Embedded little languages in tools is really useful.

# The aliases I do have

I really came out swinging at the start, but I do actually have some handy aliases that make life easier:

```toml
clone = ['git', 'clone']
ig = ['git', 'init', '--git-repo=.']
sync = ['git', 'fetch', '--all-remotes']
```

I think if you're typing any `git` subcommand with any regularity, you should alias that away. The only one I use is `jj git remote`, but that's quite rare.

```toml
evolve = ['rebase', '--skip-emptied', '-d', 'trunk()']
pullup = ['evolve', '-s', 'immutable()+ ~ immutable()']
```

Both of these are to update commits to sit on top of a newly-synced main branch. `evolve` works for the currently checked out branch, but I got frustrated at having to do this multiple times if I had multiple parallel changes. For that I made `pullup` (named since it pulls the changes from below `trunk()` to be on top of `trunk()`). The revset could probably be tidier, I don't know why I didn't just use `mutable()`.

---

I know I poke fun at people that say they only use six git commands, but the more I think about it the more I realise I am slowly enlightening myself to realise that all these different JJ commands actually do the same thing. This time it's different because these six commands are good.

Anyway this ended up more of a ramble than I expected. You can see my actual [JJ config on Codeberg](https://codeberg.org/willhbr/dotfiles/src/branch/main/jj/jjconfig.toml) and maybe when you're reading this I'm using 200 aliases and have reached new heights of productivity.
