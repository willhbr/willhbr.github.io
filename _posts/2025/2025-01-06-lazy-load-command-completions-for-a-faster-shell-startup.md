---
title: "Lazy Load Command Completions for a Faster Shell Startup"
tags: tools
---

It's a new year and you know what that means: time to remove unnecessary work from your shell startup.[^it-matters]

[^it-matters]: Unless your one of those people that opens one shell at the start of the day and never opens a new tab, pane, or window. Then it doesn't matter how fast your shell is, it could take a full minute to start and you'd probably barely notice. I, on the other hand, open new shells like there's no tomorrow.

Throughout the year there's always a little more bloat that creeps in. Like a frog in a pot you don't notice it until you're sitting there waiting hundreds of milliseconds for your shell to load. Well you deserve better, so take the time to remove unnecessary cruft and trim down that load time.

If you haven't done this before, [this post by Matthew Clemente](https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/) goes into much more detail on debugging startup time in Zsh.

Since I use [my own plugin system](/2017/08/21/pug-an-abomination-of-shell-scripting/) a lot of the oh-my-zsh debugging isn't relevant, and I just end up commenting out blocks of code and using this hack to get the load time:

```console
$ repeat 10 time zsh -i -c exit
zsh -i -c exit  0.09s user 0.02s system 102% cpu 0.106 total
zsh -i -c exit  0.07s user 0.03s system 102% cpu 0.102 total
zsh -i -c exit  0.08s user 0.02s system 101% cpu 0.103 total
zsh -i -c exit  0.08s user 0.03s system 101% cpu 0.103 total
zsh -i -c exit  0.08s user 0.03s system 102% cpu 0.106 total
zsh -i -c exit  0.08s user 0.03s system 102% cpu 0.103 total
zsh -i -c exit  0.07s user 0.03s system 101% cpu 0.101 total
zsh -i -c exit  0.08s user 0.03s system 101% cpu 0.107 total
zsh -i -c exit  0.07s user 0.04s system 101% cpu 0.105 total
zsh -i -c exit  0.08s user 0.03s system 101% cpu 0.109 total
```

A little over 100ms isn't too bad, but I've found something that's contributing about 50ms to that which I can cut out completely.

The culprit is the [JJ Zsh autocomplete](https://docs.jj-vcs.dev/latest/install-and-setup/#zsh):

```zsh
source <(jj util completion zsh)
```

If I remove this, the startup time drops to around 56ms. That's almost half the startup time just loading JJ autocomplete. Loading the other plugins I use ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)) only takes 10ms combined, so 50ms for one completion definition is a long time.

Disabling the autocomplete _is_ an option, but autocomplete is nice and I'd probably live through the additional 50ms if there wasn't another option. Thankfully I can get the best of both worlds by loading the JJ autocomplete only when I run `jj` for the first time. I've done this by wrapping `jj` in a shell function:

```zsh
jj() {
  if [ -z "$JJ_LOADED" ]; then
    source <(command jj util completion zsh)
    JJ_LOADED=true
  fi
  command jj "$@"
}
```

On the first run, since `$JJ_LOADED` is unset, it'll source the autocompletion code before running `jj`. On subsequent runs, it'll just delegate to `jj` immediately. This does mean that the first interaction with JJ will be ~50ms slower, but because that additional wait is in the context of running a command, it's barely noticeable. The result is a much faster startup:

```console
$ repeat 10 time zsh -i -c exit
zsh -i -c exit  0.05s user 0.02s system 99% cpu 0.065 total
zsh -i -c exit  0.04s user 0.01s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.02s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.02s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.01s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.02s system 99% cpu 0.057 total
zsh -i -c exit  0.04s user 0.02s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.02s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.01s system 99% cpu 0.056 total
zsh -i -c exit  0.04s user 0.01s system 99% cpu 0.058 total
```

You could probably use this same trick[^defer] to only load your favourite language version manager when you're actually going to use it.

[^defer]: Something like [zsh-defer](https://github.com/romkatv/zsh-defer) would also work.
