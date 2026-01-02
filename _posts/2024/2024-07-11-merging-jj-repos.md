---
title: "Merging JJ Repos"
tags: tools jujutsu
---

So here's a weird thought: can you merge two repositories in [JJ](https://github.com/jj-vcs/jj)? I have just ended up in a weird state (for unimportant reasons) where I had a remote repo and a local repo that diverged entirely due to me rewriting the commit history. I was going to delete the local copy and re-clone (since the remote was now the source of truth) but I thought "what happens if I add the remote and fetch from it?", and thought I might as well satisfy my curiosity first.

I added the remote and fetched it, and sure enough it worked without any issues. Since there were no commits in common, I was left with two diverging chains starting at the root commit (an empty commit present at the base of all JJ repos). I could then delete the unwanted chain of commits and get to the state I'd be in if I'd just done a fresh clone.

Or I could do one `jj rebase` and move all the commits in one chain atop the commits in the other, effectively rebasing one repo on another. This led me to the cursed realisation that I could take two completely unrelated repos and just splice them together, resulting in a repo with the contents and commit histories of both. Of course this will almost certainly result in horrible merge conflicts, but you can _do_ it.
