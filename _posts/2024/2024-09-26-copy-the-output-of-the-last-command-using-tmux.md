---
title: "Copy the Output of the Last Command Using tmux"
tags: tmux
---


I just came across [this post][ih-post] while doing some background reading for another project. I know people that do this kind of thing and it always seemed like a bit of a hack, but putting the non-breaking space in the prompt just pushes this over the line of being probably-robust enough for me to use it.

[ih-post]: https://ianthehenry.com/posts/tmux-copy-last-command/

The basic idea is that you put a non-breaking space (that looks just like a normal space) in your prompt, which makes it easier to automatically search back through your history to find where the previous prompt was. For someone like me with a simple prompt—just `||>`—without the non-breaking space it wouldn't be that uncommon to have those three characters appear in the output of a command.

Check out [the post][ih-post] for a full explanation, but the gist is that you use the tmux copy-mode features to search back and create a selection that starts at the previous prompt and ends at the current prompt.

The thing that caught me out that was that to put a unicode escape sequence in your prompt, you need to prefix the string with `$`:

```shell
PROMPT=$'||>\U00A0'
```

Without that you just get the literal string `||>\U00A0` as your prompt, which is not what we want.

Hopefully this will be useful in cases where I run a long-running command, and realise I want to do some transformation on the text _after_ seeing the output. Previously I'd either manually copy the output, or re-run the command and pipe the output to a file.

As one final tip, don't forget to set your `history-limit` to some large number so the command output doesn't fall off the top of the scrollback!
