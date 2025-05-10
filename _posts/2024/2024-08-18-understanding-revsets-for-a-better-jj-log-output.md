---
title: "Understanding Revsets for a Better JJ Log Output"
tags: tools jj
---

In git you can do something like `HEAD~` to refer to the parent commit of `HEAD`. Mercurial has a similar feature [called revsets](https://repo.mercurial-scm.org/hg/help/revsets) which [JJ took inspiration from](https://martinvonz.github.io/jj/latest/revsets/) (including the name).

The revset language is a declarative query language—not unlike SQL—that lets you specify a set of revisions (a revset) that match certain criteria. It ends up looking more like set operations than SQL, but the idea is similar. In JJ you can use `@` to mean "the current commit", or `mine()` to mean "all the commits that I authored", or `trunk()` to mean "the base branch that code will be merged into".

That's getting a little bit ahead of ourselves. Why did I go down a rabbit hole of learning about revsets in the first place? Well, one of the [many nice things](/2024/04/01/its-not-me-its-git/) about JJ is that the default output of the `log` command is to show just the stuff you care about, not the full history. For example here's the current state of the repo for my website:

```console
$ jj log
@  t Will Richardson now e
│  Add post about revsets
◆  k Will Richardson 4 weeks ago main HEAD@git 5
│  photo post
~
```

I don't care about the contents of the other 300+ commits in the repo most of the time. Showing just the stuff that hasn't been merged into `main` is great.

However, if you run `jj log` on some other repos, things aren't quite as neat. Take the [Crystal language repo](https://github.com/crystal-lang/crystal) as an example. The output of `jj log` is over 2000 lines! That doesn't include any of the 15,000 commits that have been merged into the main branch, that's just JJ showing commits that we might want to work on.

What causes this huge output is the fact that the Crystal repo has 93 branches, with commits that haven't been merged into the main branch, including long-lived branches that have years of work that isn't in `master`[^toilet]. The default set of revisions that JJ logs is anything yet to be merged into `trunk()`—the main branch. This is a sensible default as it avoids a situation where commits become invisible to the user—they're always either in the main branch, or they're shown in `jj log`.

[^toilet]: There's a [branch named "toilet"](https://github.com/crystal-lang/crystal/compare/master...toilet) with one commit from 4 years ago adding more calls to `IO#flush` throughout the standard library.

However what I want to show is just commits that _I've_ written that haven't been merged, and ignore all these other branches. To do that we need to understand some revsets.

If you want to learn the revset language properly, you should read the [revset language documentation](https://martinvonz.github.io/jj/latest/revsets/), but I'm going to walk through how I settled on my default log output.

```toml
[revsets]
log = '@ | ancestors(trunk()..(visible_heads() & mine()), 2) | trunk()'
```

That's the config that I [ended up settling on](https://codeberg.org/willhbr/dotfiles/src/branch/main/jj/jjconfig.toml).
{:class="caption"}

I wanted the log to show all the commit branches (branches as in the sense of a tree structure, not branches as in git branches) that I had authored that weren't merged into the main branch.

`visible_heads()` gives me all the leaf nodes in the repository. In a git repo this would basically be all the feature branches that people had pushed to the remote but not yet had their pull request merged. Branches like `main` or `master` usually wouldn't be in this list as there will almost certainly be commits somewhere that build on top of it.

In the Crystal repo this gives us a huge output, let's peek at just the top:

```console
$ jj log -r 'visible_heads()' | head -n 20
@  x Will Richardson 14 minutes ago c
│  (no description set)
~

◆  nsxyl Johannes Müller 2 days ago changelog/1.13.2@origin 7214
│  Add changelog for 1.13.2
~

◆  wvqv Johannes Müller 2 days ago revert-14878-docs-generator-dont-mention-nodoc-types@origin a17af
│  Revert "Fix: Don't link to undocumented types in API docs (#14878)"
~

◆  xxkqm renovate[bot] 3 days ago renovate/gh-actions@origin d6ce
│  Update actions/checkout action to v4
~

◆  rolu Johannes Müller 3 weeks ago infra/macos-14@origin b479
│  verbose spec output
~
```

There's my working copy commit, and then a bunch of in-flight work like the [changelist for version 1.13.2](https://github.com/crystal-lang/crystal/pull/14914). Each of these heads are a single leaf commit, and JJ dutifully only prints the commit and omits their parent(s).

If we want to show a bit more context, we can use the `ancestors()` function (yeah there are functions in revsets) to get the parents of each of the heads:

```console
$ jj log -r 'ancestors(visible_heads(), 1)'
@  x Will Richardson 21 minutes ago c
│  (no description set)
○  p Will Richardson 21 minutes ago HEAD@git 6
│  Allow serving index.html from StaticFileHander
~  (elided revisions)
│ ◆  nsxyl Johannes Müller 2 days ago changelog/1.13.2@origin 7214
├─╯  Add changelog for 1.13.2
◆  okrx Quinton Miller 2 days ago fa02
│  Support LLVM OrcV2 codegen specs (#14886)
~  (elided revisions)
│ ◆  wvqv Johannes Müller 2 days ago revert-14878-docs-generator-dont-mention-nodoc-types@origin a17af
├─╯  Revert "Fix: Don't link to undocumented types in API docs (#14878)"
◆  vrny Johannes Müller 3 days ago 93ac1
│  Refactor interpreter stack code to avoid duplicate macro expansion (#14876)
~  (elided revisions)
│ ◆  xxkqm renovate[bot] 3 days ago renovate/gh-actions@origin d6ce
├─╯  Update actions/checkout action to v4
◆  tnzt Johannes Müller 3 days ago f0fe
│  [CI] Update GitHub runner to `macos-14` (#14833)
~  (elided revisions)
```

JJ shows the heads, and then the commit immediately before the head. If you look at the full log output you can see that it starts linking up commits because some of them share the same parent—and it won't print the same commit twice.

The default JJ log output uses the `ancestors()` function to show a bit more context in the log, rather than just showing the un-merged commits. This typically results in the tip of the main branch being visible in the log, which is nice as you can see where you've synced your repo to.

What we actually want is to show the commits that _we've_ made, which we can access with the `mine()` function. This uses the configured author email to filter the commits. I can log the commits that I've made to Crystal with `jj log -r 'mine()'`.

This can be pieced together now using a few of the revset operators. I can find all the commits that I've authored that aren't in the main branch by subtracting all the commits in the main branch from all my commits: `mine() ~ ::trunk()`. The `::` prefix operator gives all the ancestors up until the revision, so `::trunk()` gives me everything until the last commit on the main branch. The `~` operator subtracts the right hand side from the left hand side. I basically just think of these as set operations, which I guess they're not _quite_ but it gets me most of the way there.

That's already a pretty nice log output, we could wrap that in `ancestors()` or just append `| trunk()` to show the tip of the main branch to get that extra bit of context.

My revset is slightly different, I use `visible_heads() & mine()` to get the leaf commits that I have authored, and then get all the commits between `trunk()` and those with the `..` operator: `trunk()..(visible_heads() & mine())`. I then get the `ancestors()` of those to show additional context.

Using the union (`|`) operator with both `trunk()` and `@` ensures that the main branch and current revision are **always** visible in the log output, even if I've got myself into a serious pickle—perhaps if I've pulled someone else's un-merged branch and have checked out one of their commits.

I've had this in my config for a few months now and it seems to be working well. I have an alias that will log _everything_ `jj log -r 'all()'` so if I do mess something up, I can still find my commit there. Or I can always just remove the `revsets.log` option from my config file and go back to the standard output. If you want this output, pop this in your `.jjconfig.toml`:

```toml
[revsets]
log = '@ | ancestors(trunk()..(visible_heads() & mine()), 2) | trunk()'
```
