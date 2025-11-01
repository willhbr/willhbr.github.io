---
title: "Warp Terminal"
tags: opinion tools
---

Yesterday I came across [Warp Terminal][warp] via their advertisement on [Daring Fireball][df-ad].[^good-ad] Immediately I was fascinated to know what their backwards-compatibility story was, and how their features were implemented. This is in a similar vein to the difficulties of modernising shells, that I [wrote about in more detail last month][modern-shells].

[warp]: https://www.warp.dev
[df-ad]: https://daringfireball.net/feeds/sponsors/2023/07/warp_your_terminal_reimagined
[^good-ad]: Who needs ad personalisation when you can just go directly to your target market?
[modern-shells]: /2023/07/06/why-modernising-shells-is-a-sisyphean-effort/

> If you're not sure of the difference between a terminal and a shell, [_The TTY demystified_](http://www.linusakesson.net/programming/tty/) is a really good read to understand the history and responsibilities of both. Basically the terminal emulator pretends to be a [computer from 1978](https://en.wikipedia.org/wiki/VT100), and the shell runs inside of that.

I only spent about half an hour playing around with Warp, so my impressions are not particularly well-informed, it's still in beta so many of these issues could be on a roadmap to fix. I didn't look at any of the AI or collaboration features, I'm only interested in the terminal emulation and shell integration.

What sets Warp apart from other terminal emulators is that it hooks into the shell and provides a graphical text editor for the prompt, rather than using the TTY. For normal humans that are used to the standard OS keyboard shortcuts, and being able to select and copy text in a predictable way this is an excellent feature. The output from each command you run lives in a block, which stack up and scroll off the screen. In the prompt editor, autocomplete and other suggestions are native UI, not part of the TTY. They can be clicked, support non-monospaced fonts, and many other UI innovations from the last 40 years.

In their blog post "[How Warp Works](https://www.warp.dev/blog/how-warp-works)" there is a brief explanation of how they integrate with the shell.[^skip-rust] Basically they use callbacks within popular shells (Zsh, Bash, and Fish) to know when the command is started. If my interpretation of this is correct, they do away with the shell prompt entirely, and instead use their non-shell editor to allow the user to write their command, then they pass the whole finished command to the shell, and use hooks in the shell to know when to cut off the output and create a new block.

[^skip-rust]: If you skip over all the bits about how they render Rust on the GPU and stuff.

What this means is that Warp has some significant limitations on what it can "warpify". Only the input to the shell prompt gets the magic editor experience, if you run another interactive program (like `irb`) then you're back to inputting text like it's the '70s. You can [tell Warp to inject some code](https://docs.warp.dev/features/subshells#how-to-warpify-the-subshell) into certain commands, but this will only work in the aforementioned shells. If the command doesn't understand POSIX shell syntax with the functions that Warp expects, it won't work.

So by default, if you start your login shell and then run `bash` to start a sub-shell, that sub-shell will miss out on the Warp features. I'm aware that this argument is entirely a ["perfect solution" fallacy](https://en.wikipedia.org/wiki/Nirvana_fallacy) but hey, someone's got to advocate for a perfect solution.

What is nice is that if you run a command that uses the "full screen" TTY, it will just work—the block takes up the whole screen while the command is running. You can still run `vim` and `tmux`, so if this takes over I'll still be able to get things done.

The prompt editor is definitely good if you're not used to working with a traditional shell, but since I'm used to having [Vim mode in Zsh](https://koenwoortman.com/zsh-vim-mode/), going back to a normal editor feels broken. Also since the editor is split out from the shell, autocompletions are in a separate system. I have a few [custom autocompletes setup](https://codeberg.org/willhbr/dotfiles/src/branch/main/zsh/completions.zsh) in Zsh, and not being able to access those in the editor was frustrating. I'd type `gcd <TAB>`, expecting to see a list of my projects, but instead just get a list of the files in the current directory. I assume there's some way of piping this information into Warp, but it's a shame they don't (yet?) have integration to pull this straight from Zsh.

The autocompletes that I did get were mostly good—files or arguments from my shell history—but I did get a few weird suggestions. I tried `ssh` and was suggested a bunch of hosts with names that were some base64-encoded junk. None of these appeared in my shell history of SSH config files.

> I said I wasn't going to look at any of the AI features, but then I connected to my server to see how the `dialog` command worked. The answer was that it wasn't installed. Warp then said "✨ Insert suggested command: `dig 13:02:20`". I don't know how it made the leap in logic from "command not found" to "do a DNS lookup", or why it wanted to suggest passing the current time to the DNS lookup—it was 1:02PM UTC when that suggestion popped up.

Warp is [another example](/2023/07/06/why-modernising-shells-is-a-sisyphean-effort/) of how hard it is modernise things that directly interact with the underlying OS concepts. Perhaps Warp can partner with the [`nushell`](https://github.com/nushell/nushell) developers and reinvent the shell and terminal at the same time.

In the end I'm obviously not going to move away from using [iTerm](https://iterm2.com). Warp is solving a bunch of problems that I don't have, and adding a whole suite of AI features that I have no interest in. If you are a fairly light terminal user, and get frustrated at editing commands in the traditional shell prompt, then maybe Warp is for you. [Use my referral code](https://app.warp.dev/referral/8GY984) so I can get a free t-shirt.

> You get like 80% of the benefit of using Warp's fancy editor by knowing that in the MacOS terminal, option-click will move the cursor around by sending the appropriate arrow keys to the shell.
