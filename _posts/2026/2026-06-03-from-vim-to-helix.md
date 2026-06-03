---
title: "From Vim to Helix"
image: /images/2026/helix.webp
tags: tools
---

The last year seems to have been the biggest change in developer tools ever. If you're reading _the discourse_ you can't go more than 5 minutes without seeing someone talking about their new development environment, new ways of editing code, and the huge productivity gains the tools they use are affording them.

A recurring theme of these posts is that anyone who doesn't pick up the very latest tools will be outpaced by those that have adopted them.

Up until this point my go-to editor has been whatever version of Vim was installed on my system. I'd been doing this for about 9 years, and it was comfortable. For the last three months I've been using [Helix](https://helix-editor.com/), and it's been working quite well.

The quick overview of Helix is that it's a modern implementation of a modal editor. It is heavily inspired by Vim, but isn't aiming to be backwards compatible (unlike [Neovim](https://neovim.io)). It has LSP (language server protocol) support built-in (like Neovim) which makes it easy to get IDE-like features for a variety of languages (unlike Vim).

![screenshot of Helix in split view showing Rust code for Pod](/images/2026/helix.webp)

Helix with [Pod](https://codeberg.org/willhbr/pod) open in split view, showing an LSP hover action.
{:class="caption"}

# Install and Setup

You can probably install Helix from your favourite package manager, which is nice. Something I missed is that you need to download and install the language grammars to get syntax highlighting and stuff:

```shell
$ hx --grammar fetch
$ hx --grammar build
```

You may also need to copy the runtime files (extracted from the repo or [downloaded alongside the binary](https://docs.helix-editor.com/install.html)) to `~/.config/helix/runtime`. I'm only mentioning this here since I got caught out by it.

My configuration is fairly minimal, mostly just some convenience key bindings, but you can find it [on Codeberg](https://codeberg.org/willhbr/dotfiles/src/branch/main/helix/config.toml) if you want inspiration. I used an LLM to translate my favourite Vim theme, [Dogrun](https://github.com/wadackel/vim-dogrun)[^dogrun] into a [simple ANSI-only Helix version](https://codeberg.org/willhbr/dotfiles/src/branch/main/helix/themes/dogrun.toml). Is this an indicator that I'm stuck in my ways? Probably.

[^dogrun]: My slightly modified version from 3 years ago.

# Keymap

Helix's keymap is different to Vim's, which is a right pain because I've got years of Vim muscle memory. Thankfully it's heavily inspired by Vim, and so a lot of my instincts still work, or work with slight alterations.

In Vim the action precedes the subject. To delete a word you first press `d` (the action), then `w` (the subject). If you want to delete a paragraph you press `d` and then `ip` (inner paragraph). Helix inverts this, so you first select what you want to operate on, and then do an operation. This has the advantage that you see what you're going to affect before you do anything. If the paragraph break isn't where you expected it to be, you don't just delete the wrong thing, you see that your selection is wrong before anything is changed.

In Vim I would heavily use visual mode (with `v`) to work this way anyway, so this is honestly a welcome change.

It did still take me a few days to get familiar with the keymap, and then a week or two before I broke the stickiest of habits. I didn't realise that I used `x` to delete single characters as often as I do, but that's how you select a whole line in Helix. I would also use `V` in Vim to begin a visual line selection, which doesn't have an equivalent in Helix as far as I can see.

You could add custom key bindings for these things, but I wanted to learn to use Helix, rather than an unholy custom mix of Vim and Helix key bindings with no real logic to them.

That being said, there are a few operations that I think are too verbose in Helix that I rebound. I found the default bindings for `goto_next_paragraph` and `goto_prev_paragraph` to be really fiddly: `]p` and `[p` rely on your pinky finger, and can't be easily pressed repeatedly to jump up or down by multiple paragraphs. I rebound these to `}` and `{`.

I made a few other minor customisations (that you can find in [my Helix config](https://codeberg.org/willhbr/dotfiles/src/branch/main/helix/config.toml)):

- `H` and `L` to jump to the start and end of the line (instead of `gh` and `gl`)
- `D` to jump to the definition using LSP (instead of `gd`)
- `K` for hover (usually to show the type information and documentation) instead of `<space>k`
- `C-n` and `C-p` for next and previous buffer (instead of `gn` and `gp`)
- `jk`, `jK`, `Jk`, and `JK` for exiting insert mode (instead of pressing `esc` like an animal)

The problem is now that I'm used to using Helix, but I still use Vim key bindings in Zsh. This means I'll go from editing a file to editing a shell command and start stumbling over the difference in bindings. I tried the Zsh integrations ([listed in the Helix docs](https://docs.helix-editor.com/master/other-software.html)) but they weren't reliable enough for my day-to-day use. I'm now mostly used to the difference and making a few mistakes isn't the end of the world.

# Some Random Nice Stuff

I really like `R` which pastes and replaces the current selection. Since in Vim (and Helix) deleted text goes in the paste register, the natural pattern here would be to paste before or after what you wanted to replace, then delete the original. The alternative is to delete it and then paste from a numbered register, but I find that much fiddlier. Pasting directly over some content is convenient.

In Helix `*` doesn't search for the identifier under the cursor, it just moves the current selection into the search register. On the surface this seems more cumbersome, as you first have to select the word with `miw`, put it in the register with `*`, then jump to the next occurrence with `n`. However, it gives more flexibility, as you can much more easily search for something that's not a single identifier. For example, if I want to find usages of a particularly hairy generic type, I can just select the generic (with `vwwww` or something), then `*`, and finally `n` and I'm searching. In Vim I would probably just not do this, or work around it by selecting the text in my terminal emulator[^no-mouse-mode] and pasting that into Vim's search mode.

[^no-mouse-mode]: I don't use mouse mode in any terminal programs, so no mouse actions get passed to them. This gives me the freedom to select text from anywhere in the terminal UI without changing its state.

Helix has features built-in that you'd otherwise need plugins for in Vim. Surrounding the selection with brackets or changing the types of brackets can be done with `ms(` or `mr(`. In Vim this would require [`vim-surround`](https://github.com/tpope/vim-surround).

# Multiple Cursors

Back in the day, using multiple cursors in TextMate used to be my text-manipulation party trick. I think I migrated a whole application from Rails 2 to Rails 3 just by putting cursors in the right places.[^multi-cursors]

[^multi-cursors]: Ok, maybe that's a slight exaggeration.

In Vim this was basically replaced with macros. If I wanted to do some rote mutation across a bunch of lines or call sites, I would craft a macro that would do the mutation then search for the next occurrence, and that would do the trick.

You can do the same thing with Helix, but you can also create multiple cursors and be applying the same edit in multiple places with immediate visual feedback. I haven't needed to use this that much, and I'm still getting my head around the various ways that you can place your cursors, but so far it's been a nice change.

The simplest thing you can do is press `C` to create a cursor on the line below in the same column. I'd use this the same way I'd use visual-block mode in Vim to add something to the start or end of a line. When you're done, you press `,` to merge all the cursors back into one.

The other thing you can do is create cursors that match a search. I used this to make all of these fields optional:

```rust
pub struct KeepConfig {
  pub hourly: u32,
  pub daily: u32,
  pub weekly: u32,
  pub monthly: u32,
}
```

I selected the struct definition (`mip` to select the paragraph, `vjjjjj` or `xxxxxx` to brute-force it, or `v}` using my next paragraph shortcut) and then pressed `s` (`select_regex`) and entered `:` to create a new cursor on each colon character. I could then use normal navigation to jump to the `u32`, `miw` to select that, `ms<` to wrap it in angle brackets, then just `iOption` to prepend "Option" in front of them all.

# Plugins

Over the years I have accrued a fair collection of Vim plugins. They cover a variety of different functionalities:

- `ctrlp` to quickly open files
- `editorconfig-vim` to autoconfigure the editor options
- `supertab` to do word-based autocomplete
- `lightline.vim` to put some nicer info in the status line
- `lightline-bufferline` to do that with the open buffers
- `auto-pairs` to insert closing brackets
- `vim-interestingwords` to highlight words (that are interesting)
- `syntastic` for compiler errors and warnings
- `vim-tmux-navigator` to swap seamlessly between Vim and tmux splits

I then also have syntax definitions for Swift, JJ, Elixir, Caddy, Crystal, Rust, and Kotlin. Overall this is 84,814 lines of Vim script. Admittedly a lot of that is Syntastic support for languages that I don't use.

To Helix's credit, most of this is built-in functionality. I don't need a plugin to show the files that I have open along the top of the screen or search for files in the current directory. This does put a limit on what you can do with Helix though, and there are a few places where I wish I could smooth off some rough edges with a custom script.

If I'm working in [a large repository][large-repo], then opening a file picker that just shows every single available file isn't helpful. I'd much rather have a custom picker that lets me select from just the files I've edited in version control, or apply some other filtering.

[large-repo]: https://research.google/pubs/why-google-stores-billions-of-lines-of-code-in-a-single-repository/

I don't think there's a way for me to replicate [`vim-tmux-navigator`](https://github.com/christoomey/vim-tmux-navigator) with Helix. For now I've just been living without, but I do end up using the wrong key combination to swap between tabs and I'd rather just have it be consistent.

There are also some interactions that I think would be useful, and would like to experiment with via a plugin. It would be useful to have a "jump to next reference in file" shortcut. You can show all references with `gr`, but I would like to restrict that down to just the references in the current file, and jump between them like search results. This would be really great if there's a somewhat-generically-named function, and you need to make changes to a specific implementation or overload. Searching for the method name will bring up the wrong methods, but with an LSP you can get the exact right methods.

Another missing plugin is any VCS integration for [JJ](https://www.jj-vcs.dev/). It works with git-backed repos since it can just read from `.git`, but if you're using a [different JJ backend](https://www.jj-vcs.dev/latest/technical/architecture/#storage-independent-apis) then there's no support. I didn't have any support in Vim, and so this isn't something I really expect or rely on. This is an example of something where a plugin system could provide this integration without relying on the main project to build or maintain it.

Ultimately, the current Helix feature set is enough for me. It does mean that if a new tool comes out, or if I want to adapt Helix in a particular way, I'm limited in the ways that I can do it. Development on Vim could stall completely and I could still grab new plugins to add language definitions or even whole new features to Vim.

Adding new languages into Vim is typically very easy, you search for "$LANGUAGE vim plugin", find a reputable-looking repository, clone it, and shove it in the `runtimepath`. For me that just meant adding it to the list in [`install.rb`](https://codeberg.org/willhbr/dotfiles/src/commit/ab29b85e7eda9ef52fdc1e506b15171e2829e487/install.rb).

[It doesn't seem too difficult](https://ser1.net/post/adding-a-tree-sitter-to-helix/) to add a new grammar to Helix, but through laziness I haven't bothered trying yet. The only language I can think of that's missing is [Sass](https://sass-lang.com/).

# LSP

The LSP (Language Server Protocol) integration in Helix works so well it's boring. Unsurprisingly `rust-analyzer` works with no configuration or tinkering, and shows useful messages immediately. I [previously wrote](/2026/03/13/language-servers-in-containers/) about some of the work needed to proxy the LSP connection to the inside of a container for [SourceKitLSP](https://github.com/swiftlang/sourcekit-lsp).

For languages with an LSP implementation, editing them with Helix is a breeze. For languages without an LSP (or an LSP that you don't have installed) the basic editor feels a bit worse than Vim. For example, in Vim I know that if I hit tab, _supertab_ will give me an autocompletion simply based on the words in the document. In Helix, if I don't have an LSP active and there's nothing to complete, tab seems to jump the cursor down a block.

# Why Helix?

There are a couple of other modern editors that could fill the same niche: [Zed](https://zed.dev), [Neovim](https://neovim.io/), and [Kakoune](https://kakoune.org). I didn't do any comparison before trying out Helix, a friend of mine was using it and that was enough of a signal for me to know it was worth investigating.

Having used Vim for 9 years, I'm pretty sold on modal editing, and I don't think I could go back to a non-modal editor for anything serious. I'm lucky enough to have not had any wrist pains from typing, and I think modal editing helps here. Keeping your hands closer to a typing position instead of moving between typing and pressing keyboard shortcuts definitely makes my hands happier.

If you're using Vim but want LSP features, I think Helix is a great move. I've been pretty happy using it so far.
