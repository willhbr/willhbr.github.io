---
title: "The Curse of Knowledge"
tags: opinion design
---

The [curse of knowledge][curse-of-knowledge] is the idea that as you become more of an expert in an area, it becomes harder to explain basic concepts in that area, because your assumed based level of knowledge is much greater than the typical level of understanding. Basically you might try and explain at an undergraduate level, but in reality you need to start from a high school level and build up from there. You forget the difficulty of grasping the key concepts of the topic.

[curse-of-knowledge]: https://en.wikipedia.org/wiki/Curse_of_knowledge

A similar phenomenon happens when you try and make a "simple" version of something, which requires you to become an expert in the thing you're attempting to simplify. Once you've become an expert, you understand the edge cases, tradeoffs, and other complexities in the system, and often you're able to use the complex thing without needing it to be simplified, and appreciate why it is not simple in the first place. You're then left to explain the subtleties of this complex system to people that have yet to make the leap in understanding—and experience the difficulty of explaining something it in basic terms.

I went through this whole process with tmux. Before I was a [certified tmux nerd][tmux-popup], I wanted a simpler way of configuring and controlling my tmux panes. The binding and manipulation controls seemed too limited, I wanted to be able to send commands to different tabs and split the output of commands to different panes. I managed to do some of this by hacking small scripts together, but I wanted a solution that would unify it all into one system.

[tmux-popup]: /2023/02/07/dismissable-popup-shell-in-tmux/

> There are a few projects that do similar things (like [`tmuxinator`](https://github.com/tmuxinator/tmuxinator)), but they are mostly focussed on automatic pane/window creation, rather than adding scripting to your interaction with tmux.

So I spent _months_ learning the ins and outs of tmux's command-line interface, and the functionality available in [control mode][tmux-control]. Eventually I had a program that ran alongside tmux and provided an object-oriented scripting interface to basically the entirety of tmux. You could do something like:

[tmux-control]: https://github.com/tmux/tmux/wiki/Control-Mode

```ruby
server.on_new_session do |session|
  session.on_new_window do |window|
    window.panes.first.split :vertical
  end
end
```

Under many layers of abstraction, this would listen for events in tmux, run the associated Ruby code, and send any commands back to tmux if the model had changed. It was a wonderful hack, and I'm still very happy with how it all fit together.

However, in doing so I learnt _a lot_ about the tmux CLI, and started to get a fairly in-depth understanding of how it had been designed.

Ok I need to share just how neat the tmux API is. It's all really well documented on the [man page](https://www.man7.org/linux/man-pages/man1/tmux.1.html). [Control mode][tmux-control] outputs tmux events to stdout, so if you read from that process you can receive what's happening with every tmux session on a server—input, output, layout changes, new windows, etc. You can also write commands into stdin of the control mode process, and their output will be returned as a control mode message.

Most tmux commands print some kind of output, by default it's somewhat human-readable, intended to display in a terminal. Take `tmux list-sessions` as an example:

```console
$ tmux list-sessions
flight-tracker: 2 windows (created Fri Jul 28 10:41:53 2023)
pixelfed-piper: 1 windows (created Fri Jul 28 11:14:18 2023)
pod: 3 windows (created Sat Jul 29 03:17:47 2023)
willhbr-github-io: 2 windows (created Fri Jul 28 11:13:50 2023) (attached)
```

It would be really annoying to write a script to parse that into a useful data structure (especially for every single command!), and thankfully we don't have to! Every tmux command that prints output also supports a format string to specify what to print and how to print it:

```console
$ tmux list-sessions -F '#{session_id}||#{session_name}||#{session_created}'
$1||flight-tracker||1690540913
$3||pixelfed-piper||1690542858
$4||pod||1690600667
$2||willhbr-github-io||1690542830
```

The only logical thing for me to do was write an RPC-like abstraction over the top of this, with macros to map fields in the generated format string to attributes on the objects that should be returned. This allowed me to build a fairly robust abstraction on top of tmux.

After that I started learning about all the features that tmux supports. Almost every option can be applied to a single pane (most normal people would apply them globally, but if you want they can be applied to a just one session, window, or pane)—so if you want one window with a background that's unique, you can totally do that. You can also [define hooks](https://www.man7.org/linux/man-pages/man1/tmux.1.html#HOOKS) that run when certain events happen. You can remap keys (not just after the prefix, any key at all) and have arbitrary key "tables" that contain different key remappings. Windows can be linked for some reason—I still don't know what this would be used for—and you can pipe the output of a pane into a command. Exactly how all these features should be used together is left as an exercise for the user, but they're all there ready to be used.

With this much deeper understanding of how to use the tmux API, I no longer _really_ needed a scripting abstraction, I was able to pull together the existing shell-based API and do the handful of things that I'd be aiming to accomplish (like [my popup shell][tmux-popup]). I'd basically cursed myself with the knowledge of tmux, and now a simple interface wasn't necessary. So I abandoned the project.

One of my software development _Hot Takes™_ is that git has an absolutely awful command-line interface.[^not-that-hot] The commands are bizarrely named, it provides no guidance on the "right" or "recommended" way of using it,[^no-right-feature] and because of this it is _trivial_ to get yourself in a situation that you don't know how to recover from. Most git "apologists" will just say that you should either use a GUI, or just alias a bunch of commands and never deviate from those. The end result being that developers don't have access to the incredibly powerful version control system that they're using, and constantly have to bend their workflow to suit the "safe" part of its API.

[^not-that-hot]: Is it a hot take when you're right? I guess not.
[^no-right-feature]: This would probably be considered a feature to many people, which I suppose is fair enough.

The easiest example of something that I would like to be able to do in git is a partial commit—take some chunks from my working copy and commit them, leaving the rest unstaged. The interface for staging and unstaging files is already fairly obtuse, and then if you want to commit only some of the changes to a file, you're in for a whole different flavour of frustration.

- `git add` stages a file (either tracked or untracked)
- `git restore --staged` removes a file from being staged
- `git restore` discards changes to an unstaged file

Why we haven't settled on a `foo`/`unfoo` naming convention completely baffles me. `stage`/`unstage` and `track`/`untrack` tell you what they're doing. `restore --staged` _especially_ doesn't match what it does—the manual for `git-restore` starts out saying it will "restore specified paths in the working tree with some contents from a restore source", but it's also used to remove files from the pre-commit staging area? That doesn't involve restoring the contents of a file _at all_. Just read the excellent [git koans][git-koans] by Steve Losh to understand how I feel trying to understand the git interface.[^old-git]

[git-koans]: https://stevelosh.com/blog/2013/04/git-koans/
[^old-git]: To be honest, much of this is probably because I forged my git habits back around 2012, and since then a lot of commands have been renamed to make more sense. I'm still doing `git checkout -- .` to revert unstaged files and it makes absolutely no sense—isn't `checkout` for changing branches?

What I really want is an opinionated wrapper around git that will make a clear "correct" path for me to follow, with terminology that matches the actions that I want to take. Of course the only correct opinionated wrapper would be _my_ opinionated wrapper, which means I need to make it. And of course for me to make it, I need to have a really good understanding of how git works—so that I can make an appropriate abstraction on top of it.

So this is where I've ended up, I want to make an abstraction over git, which would require me to learn a lot about git. If I learn enough about git to do this, I will become the thing that I've sworn to destroy—someone who counters every complaint about git with "you just have to think of the graph operation you're trying to achieve".
