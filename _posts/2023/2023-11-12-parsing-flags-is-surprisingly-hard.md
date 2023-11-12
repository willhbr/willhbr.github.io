---
title: Parsing Flags is Surprisingly Hard
---

On the topic of "thinking too much about things that you didn't really want to think about", have you considered just how hard it is to parse command-line arguments? Most tools—especially the battle-tested standard POSIX command-line tools—have this worked out pretty well, and work in a fairly predictable way. Until you start trying to implement them yourself, you might not notice just how much of a messy job it is.

First off, the abstract problem that flag-parsing has to solve is taking an array of strings and mapping them unambiguously to a set of configuration options. Of course you could make this incredibly easy, just give every option a unique name, and pass every option as `--${name}=${value}`. Except we add an obnoxious requirement that the input array of strings should be easily human writable (and readable) so any ultra-verbose and easy-to-implement solution is immediately unsuitable.

The convention for POSIX programs is something like:

Boolean options can be passed like `-v` to turn them on. They can also be passed like `--verbose`, `-verbose`, or `--verbose=true`. You might even support `-V` to turn the option off. A single flag could be split into two arguments, like `--verbose true` (the space means it's two arguments!) but since shells are unpredictable, you should also support a single argument with a space, in case it was quoted: `"--verbose true"`.

Flags might take arguments, which are often file paths. Like boolean options you could pass `--path=/dev/null` or `-path /dev/null`. If it's a common option then maybe you let users just write `-p /dev/null`—if you do that you should probably also support `-p=/dev/null`.

Some flags can accept multiple values, so maybe you should support `--search path/one second/path` as well as `--search=path/one --search=second/path`. Of course you should support `-s` and `-search` and maybe even mixing and matching all of these.

To reduce the amount of typing users have to do, often the short forms of flags can be shoved together into one flag, so instead of typing `-a -b -c` you can just do `-abc`. Hopefully there aren't so many short options that they could spell out the long form of other flags. Some programs allow using this short form and passing a value for the last flag. So if you had a program that has a boolean flag `-b` and a string flag `-s`, you could do `-bs value` instead of `-b -s value`.[^ty-postmodern]

[^ty-postmodern]: Thanks to [@postmodern on Mastodon for pointing out this omission!](https://ruby.social/@postmodern/111396482925514425).

If your program is doing a lot of different things, it probably makes sense to group functionality into _subcommands_, like `git clone` or `tmux attach`. You should then support short subcommand names like `tmux a`, but you've also got to match flags to a certain subcommand.

Some flags are going to apply in all cases—things like the log level config file location—but others will only apply to a specific subcommand. Do you require these flags to be in a certain order, or do you allow them to be mixed? If you allow them to be mixed then you'll have to defer processing any flags until you know the subcommand is—since they could behave differently depending on the subcommand.

Let's consider a program:

```shell
$ program --flag "a value" subcommand-one
$ program --flag subcommand-two
```

If `--flag` is defined as taking a string for `subcommand-one`, and being a boolean for `subcommand-two`, then you can't decide whether `subcommand-two` should be a separate argument itself, or a value for `--flag`. This leads to programs (like `podman`) having fairly strict orders for their CLI. Any global flags come directly after the command, then there's the subcommand, then any flags for the subcommand, then the image name, and finally any arguments after the image name are passed into the container.

This can be annoying as you have to remember which flags go where, and specifically with podman you can easily end up doing something like:

```shell
$ podman run alpine:latest --interactive
```

And wonder why you don't get a shell. The answer is that `--interactive` is passed into the container since it's after the image name, and not used to configure your container. `echo` has almost the inverse problem, it is used to print things but what if you want to print something that is interpreted as a flag for `echo`?

```shell
# This works just fine, since -t isn't a flag that echo uses
$ echo -t
-t
# but this will interpret it as a flag
$ echo -e

# quoting doesn't do anything
$ echo '-e'

# you need to know that '-' is special
$ echo - -e
-e
```

The additional catch is that shells don't have datatypes, everything passed to a program is a string. So there's no difference between  `-e` and `'-e'`, the program will always receive the string `"-e"`. Many people get caught up on this as if you're used to a "normal" programming language, the dash seems special and wrapping it in quotes feels like it should force it to be treated as a string.

Speaking of the dashes, they're purely a convention. There's no reason that you can't structure your flags and arguments in a completely different way—it would just be confusing. I've seen tools that use a trailing colon to write flags instead of leading dashes:

```shell
# so this:
$ program --flag value
# would be
$ program flag: value
```

It's somewhat neat—maybe easier to type—but will be unfamiliar for most people that are going to use it. This doesn't really allow you to have boolean flags that don't have an explicit value.

Something else to consider is that modern shells will provide some level of auto-completion by default, usually just for file paths. If you write flags as a single argument, using `=` to separate key from value, the shell won't as easily be able to provide autocompletion, since it will use spaces to separate units to autocomplete, and without spaces it won't know when to start:

```shell
$ program --path=|
$ program --path |
```

On the first line, the shell has to know to strip away `--path=` and autocomplete from there (a naive implementation would just look for files starting with `--path=`). On the second line, the space means `--path` and the following word are treated as separate units, and so the shell can more easily autocomplete without doing any special handling.

All of this complexity is why I pretty much always outsource this to a library. I usually use [clim](https://github.com/at-grandpa/clim) for my projects, it's pretty easy to use and offers more out-of-the-box than the built-in Crystal [`OptionParser`](https://crystal-lang.org/api/1.10.1/OptionParser.html). As soon as you try and make a general solution, you end up having to make some significant assumptions about what the format of the commands will be.
