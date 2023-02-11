---
title: "Dismissable Popup Shell in tmux"
date: 2023-02-07
layout: post
image: /images/2023/tmux-popup-screen-recording.gif
---

Ok so this is mostly a solution in search of a problem. Or a solution to the problem of "Will read the tmux man page too many times and wants to use all the features". However there's like a 5% chance this is actually useful, and it's something that I've wanted to get working in tmux for a while. It turned out to be much simpler than I thought.

What I want is a persistent shell that I can quickly activate or dismiss to run simple commands - like checking the git status, making a commit, or finding a path to a file. What I usually do is open a split, run the command, and immediately close the split - I must open hundreds of new tmux panes each day. Gnome people might use [Guake](http://guake.org) which does this inside the window manager.

So here's the same thing working in tmux:

![a screencast showing tmux with two panes, then an overlay window appears on top and a command is run before the overlay is dismissed](/images/2023/tmux-popup-screen-recording.gif){:loading="lazy"}

Anywhere in tmux I can press `M-A` (meta/alt-shift-a) and get a terminal window over the top of whatever I was doing. If I press `M-A` again, it will disappear - but any commands running in it will persist and can be brought back with the same keystroke.

This is based on the (somewhat recent) tmux `display-popup` feature, which runs a command in a window that floats over the top of your existing windows and panes. This is useful for utilities like `fzf` which can [show the search pane inside a popup](https://dev.to/joshmedeski/popup-history-with-tmux-and-fzf-5de5) instead of in the shell itself. The popups have a limitation though - they are not treated like a tmux pane, the popup will only disappear when the command within it exits. So this makes my plan for a persistent shell in a dismissible popup seem difficult.

And it would be, if I wasn't a **massive** tmux nerd.

How this works is that when you open the popup, it will create a super secret background tmux session. This session has the status bar hidden and all the keyboard shortcuts disabled, so it appears like it's just a normal terminal. The popup then attaches to the background session using a new client (yep, that's tmux within tmux). This gives you persistence between popups.

The background session actually has one key binding - `M-A` will detach from the session, exiting the client, and closing the popup.

The implementation turned out to be a lot simpler than I expected when I started:

```shell
# in tmux.conf
bind -n M-A display-popup -E show-tmux-popup.sh
bind -T popup M-A detach
# This lets us do scrollback and search within the popup
bind -T popup C-[ copy-mode

# in show-tmux-popup.sh, somewhere in $PATH
#!/bin/bash

session="_popup_$(tmux display -p '#S')"

if ! tmux has -t "$session" 2> /dev/null; then
  session_id="$(tmux new-session -dP -s "$session" -F '#{session_id}')"
  tmux set-option -s -t "$session_id" key-table popup
  tmux set-option -s -t "$session_id" status off
  tmux set-option -s -t "$session_id" prefix None
  session="$session_id"
fi

exec tmux attach -t "$session" > /dev/null
```

> The `key-table popup` is what turns off all the keyboard shortcuts. It's not actually turning anything off, it's just enabling a collection of key bindings that doesn't have any of the standard shortcuts in it - just the two we've added ourselves: one to detach and one for copy-mode.

You may be thinking "Will, won't you end up with a bunch of weird secret sessions littered all over the place?" - if you were you'd be absolutely right. This is less than ideal, but where tmux closes a pane it opens a window. Or something. We can use the filter (`-f`) option to hide these secret sessions from anywhere that we see them, for example in `choose-tree` or `list-sessions`:

```shell
# in tmux.conf
bind -n M-s choose-tree -Zs -f '#{?#{m:_popup_*,#{session_name}},0,1}'
```

This will hide any sessions beginning with `_popup_`. The `#{?` starts a conditional, the `#{m:_popup_.*,#{session_name}}` does a match on the session name, and rows where the result is `0` are hidden. You get the idea.

The next step is to have some way of promoting a popup shell into a window in the parent session - in a similar way to how `break-pane` moves a pane into its own window. <del>That's a challenge for another day.</del> UPDATE: I did this almost immediately, it was not very hard.

Have a look at my [dotfiles repo](https://github.com/willhbr/dotfiles) on GitHub to see this config in context: [`tmux.conf`](https://github.com/willhbr/dotfiles/blob/d2d129628cfba248f44e5705f4e0e153193130ca/tmux/tmux.conf#L112) and [`show-tmux-popup.sh`](https://github.com/willhbr/dotfiles/blob/d2d129628cfba248f44e5705f4e0e153193130ca/bin/show-tmux-popup.sh).
