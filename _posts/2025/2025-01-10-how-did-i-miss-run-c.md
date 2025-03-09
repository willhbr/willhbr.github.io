---
title: "How Did I Miss run -C?"
tags: tmux
---

It's important to remember that there's always something new to learn. While I wrote my [tmux compiler](/2024/03/15/making-a-compiler-to-prove-tmux-is-turing-complete/) and [tmux sudoku solver](/2024/12/27/solving-sudoku-with-tmux/) as well as during a bunch of other projects, I have spent a lot of time reading the tmux man page. Yet I missed a critical detail in the `run-shell` section.

A significant caveat to both the compiler and tmux solver is that I needed to start a sub-shell to call back into tmux allow me to expand variables anywhere in the command:

> Only certain arguments to tmux commands have variable expansion on them, but the whole string passed to run is expanded, which means we can use variables anywhere in any tmux command. For example:
>
> This will add a buffer containing the literal string '#{session_name}':
>
> ```conf
> set-buffer '#{session_name}'
> ```
>
> But this will add a buffer containing whatever the current session name is:
> ```conf
> run "set-buffer '#{session_name}'"
> ```

And sitting right under my nose this whole time was `run -C`.

`run -C "..."` is equivalent to `run 'tmux "..."'`. Instead of spawning a shell and running the `tmux` binary, the argument is expanded and directly interpreted by tmux as a tmux command. It's exactly what I wanted to do.

Not only does this mean I can remove the caveat of "I'm shelling out but it's only to call tmux again", since it doesn't have to waste time spawning a new process, it's also much faster.

The time taken to solve a sudoku with four numbers missing went from 41 seconds down to about 11 seconds. The interval between number increments seems to be about 3.7ms, down from 8.6ms.

However, this comes at a cost. It seems that tmux can only process keybindings so fast, and this is now fast enough that a key press gets sent to the second window and instead of getting processed as a key binding, it gets passed through to the shell. The program relies on these being processed to continue running, so the sudoku solver stops here and the user has to press `n` to have the program continue.

So there you go, you probably learnt two things today:

1. tmux has a command for running tmux commands
1. tmux keybindings become unreliable if you're pressing around 270 keys per second
