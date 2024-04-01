---
title: "It's Not Me, It's Git"
tags: opinion
---

tl;dr: I've been using [`jj`][jj] for version control in my personal projects and it makes me much happier than using git. Continue reading for lukewarm takes on the git CLI.

[jj]: https://github.com/martinvonz/jj

Firstly I'll just get some disclaimers out of the way: I only use git (now JJ) for personal projects, I don't use git at work. Also I work at Google, who [currently fund development][google-funded] of JJ since the [founder and main contributor](https://martinvonz.github.io) is a Google employee—read [this section of the readme][google-funded] for more info. This post (along with the rest of this website) is solely my own opinions, and my enthusiasm for JJ (and lack of enthusiasm for git) is just my personal view.

[google-funded]: https://github.com/martinvonz/jj?tab=readme-ov-file#mandatory-google-disclaimer

---

One of my pet peeves is hearing people say that git isn't hard, you just remember or alias a handful of commands and ignore the rest. While this seems to work for a lot of people, they're not able to take advantage of having their code in version control.

Imagine that you were learning to program and everything was done in C. You get confused about pointer arithmetic, manual memory management, and `void*`.  Eventually you learn a portion of the language[^good-portion] that makes sense and meticulously check your entire program after making any change. After doing this for years someone tells you about Python[^or-whatever]. You realise that all that time you spent avoiding buffer overruns and segmentation faults could have been avoided altogether.

[^good-portion]: An actual true story from when I learnt C in university was that we had a practical exam where we had to write solutions to basic programming and algorithms problems in C. Instead of learning the various functions in libc and their caveats, I just doubled down on pointer arithmetic. You don't need `memcpy` when you can just write a one-line `while` loop that does it manually. I wouldn't necessarily recommend this as a serious approach to programming C, but it worked for this one exam.

[^or-whatever]: Or Ruby or Rust or Java or JavaScript or Haskell or Crystal or Kotlin or Go or OCaml or C# or erlang or

This is how I feel about git. It's a tool that gets the job done, but doesn't empower me to use it confidently to make my work easier. The bar for "oh I'll just search for the command to do this" is so incredibly low.

The best feature of JJ is it has global undo. You commit something you didn't mean to? `jj undo`. Abandoned the wrong change? `jj undo`. There's a reason that UX people prefer undo over confirmation dialogs[^not-ux], it empowers users to move faster doing the thing they _think_ is correct instead of second-guessing and double-checking destructive operations.

[^not-ux]: I'm probably butchering this by remembering vibes without context, but you get the idea.

I had an almost magical experience with JJ: I tried to rebase some commits, I think I must've passed an incorrect option and I ended up with the completely wrong result. If this was git, I would be preparing myself to re-clone the repo or _maybe_ delving into the reflog if that wasn't possible. Instead I just did `jj undo`, re-checked the documentation, realised the option I should have used, and ran `rebase` again.

Knowing that the worst thing I can reasonably do[^break-everything] is waste some time and have to undo my changes frees me up to actually use version control for more things.

[^break-everything]: You can totally reconfigure some things in JJ to allow you to mess up the history of a repo and then force-push that to origin, but you'd have to try **really** hard.

Part of what makes my interaction with git messy is that it differentiates between untracked files, unstaged changes, and staged changes. The result of this is that you've got to remember how to move a file (or god forbid, parts of a file) between these states. A foot-gun here is that you could easily think that you're running a command to unstage a file so that it won't be added to a commit, but accidentally run a command that reverts the working copy changes for that file.

`git restore --staged` will unstage a file, but `git restore` will drop working copy changes to a file—losing your work. Of course _you_ would never make this mistake, but I as a mere mortal am susceptible to these mistakes.

JJ does away with staged/tracked/untracked files, and instead all files are automatically added to the working copy. I'm sure some people that like being able to manicure their staged files will find this as a deal-breaker, but as someone that compulsively runs `git add --all` so I don't accidentally leave a file un-committed, this is exactly what I want.

The working copy in JJ is actually just a commit. It starts out with no changes and an empty commit message, but any edits you make are added to it automatically, and you can adjust the commit message as you go.

Initially this seemed like a "ok whatever" implementation detail, but then you realise that all the operations on JJ just have to work on commits. You don't need to stage and unstage because you just move changes between commits. You don't need stash because you just leave your changes in a different commit. Basically all the operations you do boil down to the same small set of operations on a commit.

If you forgot to include a change into a commit, in git you would use `git commit --amend` but in JJ you're just squashing two commits together (the previous commit and the working copy commit). If you want to amend a commit that's not the most recent one, you just move your working copy to be that commit using `jj edit`. Now any changes you make will be added into that commit.

In git you would need to like, make a new commit, then rebase the intermediate commits to re-order it to be next to the target commit, and then squash it into the target. This is basically what JJ is doing under the hood, but to me I'm just swapping over to a commit and making some changes.

This also makes it easier to inspect the state of the repo. In git I constantly get caught out by the fact I can diff staged files, or diff unstaged files, but can't diff untracked files[^maybe-i-can]. I need to run `git diff --cached`, but what's cached? Am I diffing what's in a cache, or am I showing the cached diff? The answer is that `--cached` is actually just referring to staged files, and [you can also say `--staged` and get the same result](https://git-scm.com/docs/git-diff) but like, why is `--cached` there?

[^maybe-i-can]: I know this one doesn't really make that much sense, but it's nice to see a diff of "this is the added contents of this file" rather than just having it be omitted, and then just blindly running `git add --all`. You [can actually](https://stackoverflow.com/questions/855767/) use `git add -N` to pseudo-track a file to make it appear in the diff. This has a side-effect of stopping you from stashing, which I'm sure makes sense from an implementation perspective but as a user this just seems weird.

We're really getting into the weeds here, but to use `git diff` to show the change made in a commit, you need to do `git diff $commit~ $commit` to tell git to compare between the parent of the commit and the commit itself. From an implementation standpoint this makes sense—you can diff any two commits, so there's no point to limit the command to just showing a single commit.

I think of a commit as [being a diff](https://jvns.ca/blog/2024/01/05/do-we-think-of-git-commits-as-diffs--snapshots--or-histories/) moving the repository from the old state to the new state. If someone says "oh yeah it changed in this commit" I would expect to be able to look at the diff of that commit and see the line they were talking about highlighted in red or green. This makes the default behaviour of `jj diff` to be great: it shows the diff of the commit to its parent.

Since there's no staged/unstaged/tracked/untracked files, `jj diff` with no arguments just works on the current change—which is likely your "working copy" change—so it shows the diff of what you're planning to commit.[^already-committed]

[^already-committed]: "Well actually" it's already committed, since JJ automatically adds changes in the working copy to the current change. But you know what I mean; conceptually it's not committed until you've chucked a commit message in there and moved on to a new change.

I wrote in my [post comparing the DJI Mini 2 to the Mini 3 Pro](/2023/06/11/dji-mini-3-pro/):

> The end result is that editing the Mini 2 photos feels like trying to sculpt almost-dry clay. You can’t really make substantial changes, and if you try too hard you’ll end up breaking something. On the other end of the spectrum is raw files from the a6500, which can be edited like modelling clay.

In a similar way, working with git feels like I'm building with some incredibly fragile material that could shatter if I'm not careful. Working with JJ feels like I can mould or re-shape as much as I need.

I had a lecturer in uni that was adamant that students should work on their assignment throughout the semester instead of cramming it in a weekend. They were so paranoid that they created periodic copies of all our repos throughout the semester to check that the history in the final repo hadn't been tampered with. If you're on that level, you might be reading this thinking "oh no, if editing history is that easy, you'll just mess up your whole repo!" This is understandable, but JJ (by default) only allows [editing the history that hasn't been in `main`][immutable-commits], so you're only allowed to edit commits before you merge them into the main branch.

[immutable-commits]: https://martinvonz.github.io/jj/v0.15.1/config/#set-of-immutable-commits

It's these kinds of sensible defaults that make JJ more approachable. I like that in git it's _possible_ to edit the history—for example if you're helping students work out why it's so slow to work with their repository after committing multiple gigabytes of test data, then creating another commit deleting it. I've been using JJ co-located with git. The repository still has a `.git` folder and I can run any git command I want, but most of the operations I do through JJ.[^git-benefits]

[^git-benefits]: This is super convenient, because I can still push to GitLab or GitHub or whatever, I can still use basically any tool that relies on a git repo, my history is still just normal git history so it can be inspected or analysed by any tool that works on git repos, and I can still work with anyone that is using plain-old git.

Perhaps it's just that I'm more invested in using JJ, but after skimming the [reference](https://martinvonz.github.io/jj/prerelease/cli-reference/) and using it for a few months, I'm able to do more than I am with git. In no small part because I can just repeat the same few commands that operate on commits[^not-commit].

[^not-commit]: Oh yeah I think _technically_ they're changes or revisions, not commits.

- `edit` swaps to a different commit, allowing you to edit the contents at that commit
- `new` adds a new empty commit on top of the current commit
- `abandon` deletes the commit
- `split` allows you to turn one commit into two (or more) commits
- `rebase` lets you prune and splice commit chains
- `diff` shows the changes in a commit

Something that's amazing is that I honestly couldn't tell you if there's a way to remove changes from a commit. Since it's so easy to `split` and `abandon` changes, I just do that instead of looking for a command that can do it in one step.

I didn't think I'd really care about how [conflicts are handled](https://martinvonz.github.io/jj/v0.15.1/conflicts/), but not having your repo get "locked out" because you're in the middle of a merge or rebase is just really nice. I almost never get conflicts because my personal projects are basically always just authored by me on one machine, but the few times I've run into them it's freeing to have the option to just go off and do something else in the repo.

Many people think that the main part of software engineering is writing code, but any software engineer will correct you and point out all the talking to people that's often overlooked. However even just focussing on the time when you're writing code, a large part of that is just [reading other code to work out what to write](/2024/02/28/optimising-for-modification/). If you've spent enough time in large codebases you'll know how important it is to investigate the history of the code—looking at a single snapshot only tells a fraction of the story. Tools that make working with the history easier are incredibly valuable.

You're going to spend a lot of time using your development tools, you should make sure you're able to make them work for you.

---

Ok so I'm sure I've linked to [Git Koans by Steve Losh](https://stevelosh.com/blog/2013/04/git-koans/) before, but I have only now realised that he's also made a Twitter bot that generates and tweets vaguely-plausible git commands. It's seemingly broken or intentionally stopped by changes to Twitter—no updates in over six months—but you can still [read the code](https://github.com/sjl/magitek/blob/master/src/robots/git-commands.lisp) or look at the [old tweets](https://twitter.com/git_commands). Some good ones:

> `git delete [-x FILE] [-E]` \
> Delete and push all little-endian binary blobs to your home directory
>
> `git clone --record=<tip> [-j] -N` \
> Read 9792 bytes from /dev/random and clone them
>
> `git remove [-T] [-U] [--changeset=<changeset>]` \
> Rebase a file onto .git/objects after removing it
