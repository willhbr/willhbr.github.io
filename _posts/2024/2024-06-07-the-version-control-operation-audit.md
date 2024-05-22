---
title: "The Version Control Operation Audit"
tags: tools
---

Often I see people dismiss complaints about a particular version control system's usability[^its-git] because you "just need to learn like six commands"[^not-six], and so it doesn't matter that some things are complicated, because you won't use them day-to-day. If you do use them, it'll be infrequent enough that looking up an example is not a big deal.

[^its-git]: It's git, obviously.
[^not-six]: Replace six with your favourite number that the average person would consider "small".

So with that in mind, here's all the operations—not commands—that I use a version control system for. I'd say these are things I'd do with enough regularity that it's not at all noteworthy that I did them.

# View what's about to be committed

Before I commit I always want to do a quick check to make sure I'm committing what I expect. This gives me an opportunity to undo any changes I've made just for debugging, or spot any issues that I need to resolve before sending the change off for review.

Similarly, I will fairly often want to check the contents of an existing commit in a diff format compared to its parent.

# Making a commit

Making a commit is obviously table stakes, but something I'll do is commit only some of my changes—either just certain files, or certain chunks in certain files.

# Uploading a change to be reviewed

Initially I forgot this one because it's basically a reflex, but it should definitely be on the list!

# Altering a change based on code review feedback

So you fix a bug or implement feature or whatever, commit those changes, and upload them to be reviewed[^code-review]. Your reviewer leaves some comments and you need to make some changes. Assuming that you want a clean change history, you should be able to easily make the alterations the reviewer suggested, alter your commit, and re-upload that back to be reviewed again. This is almost certainly the thing I do the most often.

The optimal granularity of changes is a well-discussed topic, which I won't go into here, but in general I would prefer to not have "fix test" and "oops wrong value" in the commit history if I could avoid it. My ideal is that the project should compile and the tests should pass at every commit in the main branch.

[^code-review]: You are doing code review, right?

# Revert a file back to the original state

You make some changes, then you realise that they were rubbish, or maybe you added a bunch of debugging code to a file that you don't need any more. Whatever the case is, it should be easy to blast away any changes to a file and get it back to the latest version on the main branch.

This includes both discarding uncommitted changes from your working copy, as well as dropping the changes in a file from a commit. Just today I was working on a change and added a bunch of debugging code to a particular file. When it came time to send the change for review, I needed to get rid of all the changes in that file.[^printf]

[^printf]: Reading this back I realise just how many of my examples are about separating debugging code from real code. This is probably because I'm a serial `printf` debugger. If you're a real debugger person, I guess you never have to do this?

# Splitting a change in two

Often I'll make a variety of changes across the codebase and then realise that what I've done is actually better thought of as two separate changes—it just happens that I did them at the same time.

You should be able to take your change—committed or uncommitted—and turn it into two changes that can be reviewed independently.

This is useful to get feedback from different people (without having to explain the unrelated changes they should ignore), to keep the history logical, or to make it easier to roll back one of the changes if it breaks something.

# Merging two changes into one

Sometimes you thought a change could be made in parts, but for whatever reason you're going to need to land everything at once. Maybe you thought you could adjust an API and the migrate call sites over later, but it turned out to be impossible. Whatever the case is, your two changes need to become one.

# Writing dependent changes

You make one amazing feature, and send the code to review, but then have an idea for a second amazing feature that builds on top of the first feature. You should be able to continue building on top of your existing work while you wait for a review on the first feature.

A bit of a git-gotcha—at least for branch-based review tools—is that it's easy to just continue committing on the same branch, push it, and then have the commits for the second feature be included in the review for the first. You'd then have to manually point the branch back to the right commit. You have to remember to proactively create a new branch when you start working on what will be a new change.

# Reordering dependent changes

A bit of a less common operation, but if you've made a series of changes in a dependent chain and they're not _actually_ dependent on one another, it is really convenient to be able to re-order them to get something submitted before the others.

The most obvious example is a refactor that has to touch every call site for a method. You don't want to send it all as one change, you don't want to swap back to main and lose track of which call sites you've updated, and it doesn't matter which part of the refactor is submitted first.

# Make a dependent change independent

Instead of rearranging the order of changes, I'll instead just move a change to be in a separate series of changes before sending it for review. If my log looked like this:

```
@  q Will Richardson 1 second ago
│  Some useful bug fix
◉  u Will Richardson 3 hours ago
│  A second, equally useful feature (also huge)
◉  u Will Richardson 5 hours ago
│  Implement a huge feature
~
```

Then I would move that top commit to be separate from the feature work:

```
◉  u Will Richardson 3 hours ago
│  A second, equally useful feature (also huge)
◉  m Will Richardson 5 hours ago
│  Implement a huge feature
│ @  q Will Richardson 25 seconds ago 0b
├─╯  Some useful bug fix
◉  z root() 00
```

Then I can continue working on the useful features, and send the bug fix for review.

# Context switch between changes

Chances are you've got multiple changes on the go at any given time, and so you want it to be super easy to swap from working on one change to another. Usually what happens is you send something for review, get started with a new task, and then when the review comes back you need to swap back to editing the first change to make some fix-ups and get the code submitted.

Part of this is being able to switch while you've got some uncommitted changes in your working copy. You need to be able to record these somewhere, swap to the other change, and not lose them when you need to swap back.

# Jump back to main

Similar to the previous one, but something that I find I'll do while working on a single change, as I'll want to verify some behaviour without my in-progress changes, and then jump back to whatever I was doing.

This means being able to store your working copy changes, so your working copy is empty when you move back to main.

# Test someone else's change

Sometimes you just need to run someone else's code locally, either to check out the feature they've implemented, or to do some debugging into a problem that they're having.

It should be easy to get the version of the code that they've sent for review, and start making changes.

# Build off someone else's change

Similarly, you might need to start working on a change that requires an API or fix that someone else hasn't merged into the main branch yet. Once you've got their change locally, you need to be able to commit your own changes, and re-update them based on any alterations they make after you started.

# Rolling back a change

It doesn't take long doing operations work to appreciate a simple rollback. Having a way to say "make a change that reverses everything done in that change" is invaluable. Of course you might have to resolve some conflicts if there have been other changes in the interim, or maybe make some manual changes if you don't want a 100% pure rollback.

# Update your work based on newly-merged code

An active codebase is a moving target, and you're going to need to keep your code up-to-date with the latest code in the repo. This makes the review simpler, the submission faster, and reduces the chance of you making a change that interacts poorly with someone else's work.

# Show what changes are pending

I don't want to lose track of work that I've made locally, so having some way of listing all the changes that exist on my machine that haven't yet made it into the main branch is very useful. Usually this is necessary when I've swapped between tasks and need a reminder to upload a change and get it reviewed.

---

I'm fairly sure that's the lot. I'll leave it as an exercise for the reader which commands those actions would map to in your favourite version control system. If you're one of these mythical 6-command people, what do you think of my operations? Do they fit in your memorised commands, or are these just things that you never need to do? Do you use a graphical interface for your favourite VCS that abstracts these things away? [Send me a toot]({{ site.urls.mastodon }}), I'd be fascinated to know!

What I haven't included here is operations that involve reading the whole history of a project. My main interaction with version control for _making_ changes is via command-line interfaces, and CLIs are not very good for _reading_ changes. Instead I'll do these through a browser-based code review and code browsing tool (eg the GitHub/GitLab UI). For what it's worth, the things I view in that UI are:

- Change history for a file
- State of a file at a particular point in time
- Blame for a file
- Blame for a file at a particular point in time
- Diff for a particular already-submitted change
- Cross-references, interface implementations, and other non-VCS information
