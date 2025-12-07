---
title: "Using JJ for the Version Control Operation Audit"
tags: tools jj
---

So I [just wrote about](/2024/06/07/the-version-control-operation-audit/) the version control operations that I use day-to-day. My new favourite thing is [JJ](https://github.com/jj-vcs/jj)—a git-compatible version control system that I've also [written about before](/2024/04/01/its-not-me-its-git/)—so I thought I would explain how each of these operations are done with JJ.

# View what's about to be committed

So we're already at a "well, actually" moment, because all changes in JJ are automatically committed, but basically `jj diff` will do what you want.

# Making a commit

You do `jj new` to start a new commit, `jj describe` to set the commit message, or `jj commit` to set the commit message and start a new commit in one go.

# Uploading a change to be reviewed

This depends on your workflow, but `jj git push --all` will upload every branch to your remote. I also use `jj git push -c @-` to create a new auto-named branch, and `jj git push -b 'glob:willhbr/push-*'` to upload every auto-named branch. These all sit behind convenient aliases [that I've mentioned before](/2024/05/26/some-hot-jj-tips/).

If you're submitting a change to someone else's repo via your own fork, it works really well to set the `upstream` remote to be theirs, and `origin` to be yours, then edit the repo config to pull from `upstream` and push to `origin`:

```toml
[git]
push = "origin"
fetch = "upstream"
```

# Altering a change based on code review feedback

You can do this a few ways:

`jj edit $change` to swap your working copy to point to the change you want to alter, but this makes it a little trickier to see what your alterations are since you're editing the change directly (`jj diff` will show the diff for the whole change). There are ways around this using `jj obslog` but that's more work.

`jj new $change` will create a new change on top of the target you want to alter. You can make changes, view the diff compared to the target (the parent) with `jj diff`, and then do `jj amend` to move the changes into the target.

Of course you could just do `jj new` _anywhere_, make your edits, and then do `jj squash --into $change` to move the changes. This works from anywhere to anywhere[^citation-needed]. This does run an increased risk of creating conflicts, but you should live dangerously every once in a while.

[^citation-needed]: I'm pretty sure? I haven't checked though.

# Revert a file back to the original state

Either `jj restore --from=$change <paths>`, or `jj diffedit` (I haven't used that one).

Alternatively I just do `jj split` and then `jj abandon` on the commit that has the changes I don't want.

# Splitting a change in two

It's just `jj split`. No tricks.

# Merging two changes into one

I'd like to be able to do this with a murcurial-style `histedit`-and-fold, but [JJ doesn't have `histedit` yet](https://github.com/jj-vcs/jj/issues/1531) so the next best thing is `jj squash --from $a --into $b`, and then `jj abandon` the empty commit.

# Writing dependent changes

The depends on the review system you're using, but in the common branch-based ones (GitHub/GitLab) you just use `jj git push -c $change` to create a branch that can be uploaded for review. This won't move as you add more commits, so you don't have to remember to branch before you continue working.

# Reordering dependent changes

JJ doesn't have a mercurial `histedit` command ([yet](https://github.com/jj-vcs/jj/issues/1531)), so I'd do this with multiple `rebase -s X -d Y` invocations. This is less than ideal, but gets the job done.

# Make a dependent change independent

`jj rebase -r @ -d main` will pop the working copy change off its parent and put it on top of `main`.

# Context switch between changes

Either `jj edit` or `jj new`, depending if you want to be editing the change directly, or a new change on top of it. Since your working copy is always recorded in a commit, there's no need to have any `stash` mechanism.

# Jump back to main

`jj new main`, and you can do this at any point because you don't have to worry about stashing.

# Test someone else's change

This is another one that depends on your workflow. If the changes have been pushed to a remote you've already got setup, you just need to `jj git fetch --all-remotes` and then `jj new $branchname`. If the change is in someone else's fork, you'll need to jump through a couple of hoops to add the remote first, fetch from it, then start a new change on top of their branch.

# Build off someone else's change

This looks just the same as testing someone's change, you just start writing some code. You might need to fetch and rebase if they update their code.

# Rolling back a change

`jj backout -r $change` will create a new commit that reverses everything done in `$change`. This may have some conflicts, depending on how old `$change` is.

# Update your work based on newly-merged code

`jj git fetch --all-remotes` is my go-to, I have this aliased as `jj sync`. It only fetches though, it doesn't actually alter any of your pending changes. I then run `jj rebase --skip-empty -d 'trunk()'` (aliased to `jj evolve`) to put my current changes back on top of `main`. If I was working on top of someone else's change, I would have to replace `trunk()` with their branch name.

# Show what changes are pending

I think the default `jj log` query shows too much stuff, so I've got a custom query that will typically show less than half a screen of output:

```toml
[revsets]
log =  '@ | ancestors(trunk()..(visible_heads() & mine()), 2) | trunk()'
```

How I worked this out is a topic for another day, but this basically just shows my changes that haven't been submitted yet, and ignores other people's unmerged branches.

I'm not using JJ for my day-to-day work, just for my personal projects (like this website!) and so I'm not actually doing most of these operations that often.
