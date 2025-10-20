---
title: "Unlocking the Full Speed of the tmux Interpreter"
tags: tmux
---

This will take a little bit of catching up. In 2024 I worked out [how to compile code to run in tmux][tmux-compiler] by swapping between windows and setting hooks to run when each window got focus. Immediately after that I realised the whole window thing was unnecessary, and you [could use key bindings and nested sessions][nested-sessions] to simplify the whole thing. Then at the end of the year I use this method to [solve a sudoku entirely within a tmux config file][sudoku-solver].[^other-projects]

[^other-projects]: And then obviously [playing video](/2025/03/17/playing-video-with-5170-tmux-windows/) and [playing snake](/2025/03/20/snakes-in-a-pane/).

All of these relied on running a shell command just to run `tmux` again in order to have variable expansion in places where you wouldn't normally get it. You can put tmux variables in the argument to `run-shell` and they'll be expanded before the command is run. I then realised that I'd [missed an option to the `run` command][run-c] where you can just directly run a `tmux` command without going to a shell at all, while still getting the same expansion.

Not having to start a new subprocess for every "clock cycle" speeds the execution up _dramatically_, so much so that tmux isn't able to keep up with all the keypresses, and they will be occasionally dropped and sent through to the shell, instead of being processed by tmux. So while it gives a 4&times; speed increase, it also makes the "program" unreliable to the point that I couldn't really run it without having to manually prod it to get it to complete.

Well I've just learnt about yet another tmux feature that fixes this exact problem!

The `send-keys` command has a `-K` flag,[^its-new] which means the input is interpreted as though it came from a client instead of being directed into a pane. Previously I needed to have tmux [attached back to itself][nested-sessions]—a session with two windows and the second window is attached to the same session looking at the first window—but this option does the same thing with none of that mess.

[^its-new]: It was added in tmux 3.4, so it was added after I wrote the compiler (I was using 3.3a), which is likely why I hadn't seen this option in my original readings of the tmux manual.

It does have a wrinkle in that the client IDs are not predictable, unlike sessions, windows, or panes. At least I don't think so. They're just identified by the pseudo-terminal that is being used (or something, I don't really understand how this works) so they look like `/dev/pts/0`. I can't predict what it'll be because other programs or tmux sessions might be using some IDs.

Thankfully this is not a problem, as we can just expand the `#{client_tty}` variable to get the current client, and use `run -C` to expand that variable in the `send-keys` command. So to send `n` we would just:

```conf
run -C "send-keys -K -c '#{client_tty}' n"
```

This doesn't have to start a subprocess, and tmux doesn't miss the key input. It's no faster than the [original `run -C` speedup][run-c], but it's completely reliable. I can solve a sudoku with 5 missing numbers in 38 seconds, down from 6:10 when using subprocesses, and just as reliable.

You can get the updated code [on Codeberg](https://codeberg.org/willhbr/tmux-sudoku) if you want to benchmark it yourself.

[tmux-compiler]: /2024/03/15/making-a-compiler-to-prove-tmux-is-turing-complete/
[nested-sessions]: /2024/03/16/further-adventures-in-tmux-code-evaluation/
[sudoku-solver]: /2024/12/27/solving-sudoku-with-tmux/
[run-c]: /2025/01/10/how-did-i-miss-run-c/
