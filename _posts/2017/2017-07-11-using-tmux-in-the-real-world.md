---
title: Using tmux in the Real World
date: 2017-07-11
layout: post
---

Every now and again I happen across a post outlining how to use [tmux](https://tmux.github.io). Since I first happened upon tmux in 2015, my use of it has grown from "occasional", to "frequent", almost to "continual". What I find frustating with these posts is that they don't describe how to actually _use_ tmux in the real world. [The post in question that prompted this post](https://hackernoon.com/a-gentle-introduction-to-tmux-8d784c404340) tells you how to start a session, create new windows, then how to switch between and resize windows.

The thing that they fail to explain is that the default tmux commands and shortcuts are terrible. Common operations require far too many fiddley keystrokes to be done quickly. Moving between panes is by default `Prefix` followed by an arrow key, so to move to the right you would enter `C-b →` - but you can't press the arrow key while you have control held down, because that will resize the window. So if you have four panes, you have to press `C-b`, release ctrl, press the arrow key, press `C-b`, release ctrl, press the arrow key, press `C-b`, release ctrl, press the arrow key once more and you're there - unless of course you pressed the arrow key before the ctrl key was released, which means you will have a slightly resized pane instead [^keybindings-note].

[^keybindings-note]: I know that if `C-h/j/k/l` were the default this would stop those keys being able to be used for other things, but I think the productivity gain is far greater than the loss of some keys (this is probably just because I don't use anything that needs those shortcuts).

This lack of usability is repeated - splits are created with `Prefix %` and `Prefix "` but which one does horizontal and which one is vertical? I have no idea, plus having keys that you have to use the shift key to get at just makes them harder to get at. The `tmux` command also leaves a lot to be desired - it's not simple to connect back to an existing session given its name.

What irks me the most is that a beginner will read one of these posts and think that they have to remember all these arcane commands and be able to enter them at lighening speed. This is far from the reality of using tmux (or most other command-line tools) - everyone that I know that uses tmux has a config that makes tmux fit to the way they think of things. Each one of them had to learn the defaults and then find out if there was a better way - which is a significant barrier for most people.

The aspect of tmux that redeems these oddities is it's extensive set of customisation options. Every command can be bound to a new shortcut, and shortcuts can be entered without needing to press the prefix key first. So what I'm going to do is build a set of reasonable defaults, so you can jump ahead and use tmux like a sane person.

---

> This post isn't a one-stop-shop for all your tmux needs, instead it's just a quick walkthough of the basic ways that I make tmux more appropriate for daily use [^other-notes]. All the snippets should be added to your tmux config file, which lines in `~/.tmux.conf` by default.  

[^other-notes]: Other things that irk me are poor window indicators in the status bar - mine has more color to show the current window. The status bar also does a poor job of showing the status info - especially the current host. I change the color of part of the status bar depending on the host I'm on (mostly for aesthetics). And the default green highlight is super gross.

The first thing that most tutorials tell you to do is remap the prefix to something other than `C-b`, because `C-b` is a bit too much of a stretch for most people. I use `C-z`, many people use `C-a`. Whatever you use is up to you. To remap the prefix, add this to your `.tmux.conf`:

```
unbind C-b
set -g prefix C-z
bind C-z send-prefix
```

This deactivates `C-b`, sets `C-z` as the prefix and makes a shortcut `C-z C-z` that will send `C-z` to the program inside tmux (so you can still use the shortcut). Replace `C-z` with another shortcut that tickles your fancy if you so desire. (I'll use `C-z` when I'm talking about the prefix in examples, just remember to use yours if it is different).

The next thing is splitting panes. This will depend on how you visualise the panes, but I think of a horizontal split as two panes with a divider that is horizontal, and a vertical split has a vertical divider. This is the opposite to how tmux thinks of it, so depending on how you think, you may want to skip this.

Since tmux 1.9, new windows and panes open in the directory that tmux started in. I prefer the old method where they would open in the same directory as the previous window or pane. I frequently run some command, and if it takes a while I will open a split and continue working in the same location while waiting for the command to complete. I find this behaviour useful, and I think you will too. So:

```
# Open new windows with the same path (C-z c)
bind c new-window -c "#{pane_current_path}"
# Create a 'vertical' split (divide vertically) using C-z v
bind v split-window -h -c "#{pane_current_path}"
# And a horizontal split (divide horizontally) using C-z h
bind h split-window -v -c  "#{pane_current_path}"
```

Ok so on to the main event, the thing that makes tmux actually usable - faster pane switching. I use vim so I'm used to using h/j/k/l for left/down/up/right movement, you may prefer the arrow keys. Up to you. The key is to make these shortcuts not require the prefix before them, so you can smush some buttons repeatedly instead of repeating an exact sequence.

```
# For h/j/k/l movement
bind -n C-h select-pane -L
bind -n C-j select-pane -D
bind -n C-k select-pane -U
bind -n C-l select-pane -R
# For arrow key movement
bind -n C-Left select-pane -L
bind -n C-Down select-pane -D
bind -n C-Up select-pane -U
bind -n C-Right select-pane -R
```

These lowers the barrier to moving between your panes, which should hopefully encourage you to get crazy and open as many panes as you can fit on your screen. Wait, what if I don't want to have everything in exact halves? Then you'll have to resize a pane!

The [post that inspired this one](https://hackernoon.com/a-gentle-introduction-to-tmux-8d784c404340) instructs you to resize panes by opening the command mode `Prefix :` and entering `resize-pane -L`, to move the split to the left. Now that is just super tedious. You can give it number of the amount you want to resize it, but that devolves into guesstimating pretty quickly. Instead I like to leverage the meta (alt/ option) key, so `M-l` (`alt + L`) will resize the pane to the left. Again you could make this `M-Left` if arrow keys are your forté.

```
# h/j/k/l
bind -n M-h resize-pane -L
bind -n M-j resize-pane -D
bind -n M-k resize-pane -U
bind -n M-l resize-pane -R
# Arrow keys
bind -n M-Left resize-pane -L
bind -n M-Down resize-pane -D
bind -n M-Up resize-pane -U
bind -n M-Right resize-pane -R
```

And boom, you can resize panes super quickly. One last shortcut that isn't quite essential, but still useful is a quick window-switching shortcut, I like `M-n` and `M-p` to replace `C-z n` and `C-z p`. Especially if you're flicking through a lot of windows.

```
bind -n M-n next-window
bind -n M-p previous-window
```

Two more useful things; set the default terminal to be 256 color so that your editor looks good, and set the starting index of windows to be 1 rather than 0 so it follows the order of the keyboard:

```
set -g base-index 1
set -g default-terminal "screen-256color"
```

So what to do about managing your sessions? Almost everyone I've talked to has made a little wrapper script that basically does this: if no arguments are given, list all the sessions. If an argument is given, connect to that session if it exists, otherwise create a session with that name. This avoids having unnamed sessions and means you don't have to remember to run `tmux ls` every time. [I've made a version of this with more bells and whistles](https://github.com/javanut13/dotfiles/blob/master/shell/autoload/mux.sh) but this is the basic idea:

```shell
mux() {
  local name="$1"
  if [ -z "$name" ]; then
    tmux ls
    return
  fi
  tmux attach -t "$name" || tmux new -s "$name"
}
```

Chuck that in your `.bash_profile`, `.zshrc` or whatever, then run `mux` to view your sessions, or `mux my-session` to create or connect to a session.

These are the changes that I have made to make tmux usable, but don't forget that there are a whole load of things that I just do the default way. This post isn't an exhaustive tutorial on using tmux, but rather an outline of how to make it more useful if you share my sensibilities.
