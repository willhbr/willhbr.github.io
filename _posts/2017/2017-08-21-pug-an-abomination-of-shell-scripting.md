---
title: "Pug: An Abomination of Shell Scripting"
tags: tools projects
---

Pug started out a few months ago as a slightly silly idea of writing my own plugin manager for Vim and ZSH plugins. There is no shortage of ways of managing Vim plugins - [Pathogen](https://github.com/tpope/vim-pathogen) or [Vundle](https://github.com/VundleVim/Vundle.vim) seem to be the most common. For ZSH everyone swears by [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) which includes every bell and whistle you could imagine.

However each of these only work for the one tool. What if (for some reason) I wanted a tmux plugin? I'd have to install some tmux package manager - if there is one. Pug is the one tool to rule all my package managing needs.

Pug can be used to manage packages for any utility - out of the box it has installers for Vim and ZSH, but other installers can be added by writing a simple shell script. I'll probably write some more builtin ones myself.

To [get started with Pug](https://codeberg.org/willhbr/pug/src/branch/master/README.md), head over to the [Pug repo](https://codeberg.org/willhbr/pug). My favourite ZSH plugins - syntax highlighting and auto suggestions - can be installed with Pug:

Install Pug:

```shell
curl https://codeberg.org/willhbr/pug/raw/branch/master/install.sh | bash
```

Create a `deps.pug` file somewhere:

```shell
vim deps.pug
```

Add the dependencies (zsh-autosuggestions and zsh-syntax-highlighting) to `deps.pug`:

```shell
#!/usr/local/bin/pug load

zsh github: zsh-users/zsh-autosuggestions
zsh github: zsh-users/zsh-syntax-highlighting
```

Load the dependencies:

```shell
pug load deps.pug
```

You'll be prompted to add this to your `.zshrc` file:

```shell
source "$HOME/.pug/source/zsh/pug"
```

Done. [No more submodules.](https://codeberg.org/willhbr/dotfiles/commit/32117b215bde38ea70c4818a2ab3764c67a5fe6d)
