---
title: "Why Modernising Shells is a Sisyphean Effort"
---

Anyone that knows me is probably aware that I spend a lot of time in the terminal. One of the many things that I have wasted time learning is the various oddities of shell scripting, and so I am cursed with the knowledge of the design tradeoffs in their design. It seems to be something that most people don't appreciate. Your shell has to find a balance between getting out of your way for interactive use, and being the best way to link together multiple unrelated programs to do something useful. The Unix philosophy of having many small tools, each dedicated to one simple job means that you can more easily replace one with an alternative, or a new tool doesn't have to reinvent the wheel before it can be useful.

The problem is that to most people, the shell is completely inscrutable. Even experienced programmers who have no problem juggling many other programming languages will get into a muddle with even a simple shell script. To be honest, you can't really blame them. Shell languages are full of bizarre syntax and subtle traps.

The root of the problem is POSIX; it defines the API for most Unix (and Unix-like, e.g: Linux) operating systems. Most important is the process model. A POSIX process receives arguments as an array of strings, input as a stream of bytes, and can produce two streams of output (standard output and error). Unless you're going to redesign the whole operating system[^new-os], you've got to work within this system.

[^new-os]: Which doesn't seem to be something many people are interested in; we're pretty invested in this Linux thing at this point.

> POSIX does also define the syntax for the shell language, which is why Bash, ZSH, and other shells all work in a similar way. Fish, xonsh, nushell, and Oil are not entirely POSIX compatible, and so are free to alter their syntax.

What sets a shell apart from other languages is that external programs are first-class citizens[^not-first-class], you don't have to do anything special to launch them. If you type `git status` the shell will go off and find the `git` program, and then launch it with a single argument `status`. If you were to do this in Ruby, you'd have to do `system('git', 'status')`—more fiddly typing, and completely different from calling a function.

[^not-first-class]: Except for modifying variables and the environment of the shell process.

So if you want programs to fit in just the same as shell functions, your functions need to work like POSIX processes. This means they can't return something—just input and output streams—and their arguments must be handled as strings. This makes implementing a scripting language that can be compared to Ruby or Python basically impossible. The constraints of having all your functions act like processes hampers your ability to make useful APIs.

This makes it really difficult for your shell language to support any kind of strong typing—since everything passed to any command or function needs to be a string, you're constantly reinterpreting data and risking it being reinterpreted differently. Having everything be handled like a string is consistent with how programs run (they have to work out how to interpret the type of their arguments) it is a constant source of bugs in shell scripts.

> My favourite fun fact about shells is that some of the "syntax" is actually just a clever use of the command calling convention. For example, the square bracket in conditionals is [actually a program called `[`](/2017/01/11/conditionals-in-sh/).

[`xonsh`][xonsh] is a new shell that merges Python and traditional shell syntax, except it does it by [trying to parse the input as a Python expression][xonsh-parsing], and if that doesn't make sense it assumes it should be in shell mode. This gets scripting and interactive use tantalisingly close, except it seems to me (without having used `xonsh`) that it would end up being unpredictable, and you would have to always be aware of the fact you're straddling two different modes at all times.

[xonsh]: https://xon.sh
[xonsh-parsing]: https://xon.sh/tutorial.html#python-mode-vs-subprocess-mode

[`nushell`][nushell] attempts to solve the problem in a different direction. It requires you to either [prefix your command with an escape character][command-prefix] or [write an external command definition][externs] to have it be callable from the shell. This moves away from the typical design of shells, and relegates external programs to be second-class citizens. `nu` is really a shell in search of a new operating system—to really make the most of their structured-data-driven approach, you'd want a new process model that allowed programs to receive and emit structured data, so that all the features for handling that in the shell could be used on arbitrary programs without writing an external command definition first.

[nushell]: https://github.com/nushell/nushell
[command-prefix]: https://www.nushell.sh/book/escaping.html
[externs]: https://www.nushell.sh/book/externs.html

So if we're too snobby to resort to parser tricks or fancy wrappers, what are we left with? Well we've got some serious constraints. The input space for command arguments is every single letter, number, and symbol. Any use of a special character for syntax makes it potentially harder for people to pass that character to commands, for example if `+` and `-` were used as maths operators, you'd need to quote every flag you passed: `git add "--all"` instead of `git add --all`, since the dashes would be interpreted as different syntax.

You've probably already come across this using `curl` to download a URL with query parameters:

```shell
$ curl https://willhbr.net/archive/?foo=bar
zsh: no matches found: https://willhbr.net/archive/?foo=bar
$ curl 'https://willhbr.net/archive/?foo=bar'
# ...
```

Since `?` is treated specially in most shells to do filename matches, you have to wrap any string that uses it in quotes. Since so many people are used to dumping arbitrary strings unquoted as command-line arguments, you don't want to restrict this too much and force people to carefully quote every argument. It's easy to start an escaping landslide where you keep doubling the number of escape characters needed to get through each level of interpolation.

[`oil`][oil-shell] is the most promising next-generation shell, in my opinion. From a purist perspective, it does treat functions and commands slightly differently, as far as I can see. This does look like it's done in a very well thought out way, where certain contexts appear to take an expression instead of a command. This is best understood by reading [this post on the Oil blog](https://www.oilshell.org/blog/2020/01/simplest-explanation.html).

[oil-shell]: https://www.oilshell.org

```shell
# the condition is an expression, not a command so it can have operators
# and variables without a `$` prefix.
if (x > 0) {
  echo "$x is positive"
}
# you can still run commands inside the condition
if /usr/bin/false {
  echo 'that is false'
}
```

Once you've split the capabilities of functions and commands, you might as well add a whole set of string-processing builtin functions that make `grep`, `sed`, `cut`, `awk` and friends unnecessary. Being able to trivially run a code block on any line that matches a regex would be excellent. Or being able to use code to specify a string substitution, rather than just a regex.[^will-not-learn-awk]

[^will-not-learn-awk]: I know I can probably somehow do all this with `awk`. I know that anything is possible in `awk`. There are some lines I will not cross, and learning `awk` is one of them.

There's also a third dimension for any shell, and that's how well it works as an actual interface to type things into. The syntax of the Oil `ysh` shell is better than ZSH, but in ZSH I can customise the prompt from hundreds of existing examples, I can use Vim keybindings to edit my command, I have syntax highlighting, I have integration with tools like `fzf` to find previous commands, and I have hundreds of lines of existing shell functions that help me get things done. And to top it all off, I can install ZSH on any machine from official package sources. Right now, it's not worth it for me to switch over and lose these benefits.
