---
title: "Writing in Crystal, Rewriting in Rust"
tags: projects languages crystal jj
---

I'm a serial tinkerer and project starter, which means I end up leaving a trail of half-finished (or half-started) projects everywhere I go. If it's not new projects, I'll drop in to some existing project and make some changes, then forget about them for months or sometimes years.

Thankfully for a long time I've kept all my projects in a consistent location: `~/Projects` so they're not hard to keep track of, but that does mean I have to actually go and look, which requires effort, and so I don't do it.

I've made a super simple tool that does this for me. It's called [Project Progress Printer][ppp] and it shows the state of all my repos:

[ppp]: https://codeberg.org/willhbr/project-progress-printer

```console
$ ppp
Clean (12)
 ✓ archer-vr1600v-login          21 weeks ago
 ✓ blender-quicksaver            4d17h4m ago
 ✓ dotfiles                      4 weeks ago
 ✓ endash                        6 weeks ago
 ✓ obsidian-publish-to-jekyll    4d17h2m ago
 ✓ photo-website                 2024-10-05
 ✓ pod                           5 weeks ago
 ✓ podman-cr                     4d17h4m ago
 ✓ ppp                           4d17h5m ago
 ✓ svg                           2024-10-07
 ✓ tmux-video                    4d17h12m ago
 ✓ willhbr.github.io             4 weeks ago

No remote (3)
 ? PhotoFixer      -  1  -       4d17h5m ago
 ? pine-swift      -  1  -       4d17h3m ago
 ? tmux-graveyard

Dirty (1)
 * backup  -  1  -               4d17h3m ago

 ✓ clean * dirty ⨯ unpushed ? no remote
```

It has colours and everything, but those are too much effort to show here.[^interesting-projects]
{:class="caption"}

[^interesting-projects]: `tmux-graveyard` is a half-baked plugin that stores exited panes and lets you re-open them later. `archer-vr1600v-login` was me trying to understand what on earth was going on with the authentication to log in to my router's admin interface.

That's the output on my laptop—which I don't do much development work on—my little server/dev machine has 58 projects on the go.

The project started as a simple Crystal program, became a bit more complicated, and then got re-written in Rust. This is the first (useful) project that I've actually completed using Rust, and I think it's interesting to compare the Crystal and Rust implementations, and what it was like for me trying to match behaviour from the Crystal version in Rust.

Before I get into that, this was the first time I'd tried to do any scripting with JJ. I've been using it for about a year and a half now (I wrote [a bit about giving up on git last year](/2024/04/01/its-not-me-its-git/)) but none of my use had needed any scripting. Initially I thought that because JJ is so much less mature, I might end up having to drop down to using git commands to get the information I needed, but in reality it was the exact opposite.

Firstly I could use revsets to grab the exact set of commits I would be interested in showing—[something I've written about before](/2024/08/18/understanding-revsets-for-a-better-jj-log-output/)—which is much easier to reason about than with `git log`. I'm sure there is a way to do this, but I find it so easy to write the revset that will give me all commits that I've authored that aren't in the main branch: `mine() ~ ::trunk()`. Because of JJ's simpler model, I don't have to worry about which commit is current "checked out", like I probably would in git.

The next delightful thing is the templating language. This is not something I'd used much before, but it's developed with the same sensibilities as the revset language. It's not based on variable expansion and substitution, it's a full-on language with functions and data types.

When you specify the output format for git (or tmux for that matter) you have limited opportunities to change the format of _nested_ data. If the commit touches multiple files, you can't specify to only show a certain aspect of each of those files. Since JJ's template language has a `map` method, anything is possible. You end up having to parse the format of the data that the tool happens to output in, rather than being able to control this completely yourself.

I didn't end up actually needing something that complicated, instead I built a template that would print a JSON description of the commit. This was trivial to parse to a data structure once I'd got the output of the `jj` command. The most basic form of the template looks something like:

```
'{"empty":' ++ empty ++ '}\n'
```

Getting the escaping correct is a pain (you've got to navigate Crystal, JJ, and the generated JSON, all with different quoting expectations) but you'll get back a line like `{"empty":false}` for each commit in the revset.

I built a little helper method that would make it easier to build these templates, so I just had to write:

```crystal
template = as_json(
  description: escaped("description.first_line()"),
  empty: :empty,
  root: :root,
  immutable: :immutable,
  bookmarks: quoted("bookmarks.join(' ')"),
  time: "commit_timestamp(self).format('%s')"
)
```

And I'd get a template string like this (split into multiple lines for readability):

```
'{"empty":' ++ empty ++
  ', "root":' ++ root ++
  ', "immutable":' ++ immutable ++
  ', "bookmarks":' ++ '"' ++ bookmarks.join(' ') ++ '"' ++
  ', "description":' ++ description.first_line().escape_json() ++
  ', "time":' ++ commit_timestamp(self).format('%s') ++ '}\n'
```

If I were interacting more with JJ, I would have written a module with a macro that automatically generated this template at compile time by looking at annotations on the attributes, allowing for something like:

```crystal
class Commit
  include JJ::Templatable
  @[JJ::Field]
  getter immutable : Bool
  @[JJ::Field(template: "description.first_line().escape_json()")]
  getter description : String
  ...
end
```

Although thankfully I managed to pull myself away before getting too into that.

Since the program is completely IO-bound—it spends almost all its time waiting for JJ subprocesses to run—it's a great candidate for lightweight concurrency. I just wrapped the `.each` call with a [`Spindle`](https://codeberg.org/willhbr/geode/src/branch/main/src/geode/spindle.cr) and then every subprocess was launched at the same time, and the spindle will wait for them all to complete before continuing.

Formatting the output is also straightforward, I tried to write directly to an `IO` wherever possible, to avoid allocating strings unnecessarily (foreshadowing). I used the `Colorize` module from the standard library to make the output more legible.

At this point I'd call the tool just about done. Maybe I'd tweak the output a bit later, I added a flag to sync all repos at once, so maybe I'd want to show how out of date my local repo was, or something like that.

It's not really clear to me what exactly compelled me to start rewriting in Rust, maybe it was some subliminal messaging injected deep into my subconscious after watching [Faster Than Lime's _The Promise of Rust_](https://fasterthanli.me/articles/the-promise-of-rust) video. Anyway, it ended up being a good project to dip my rusty toes into, since it's fairly constrained but still touches on a few more complicated things, while also being something that's useful.

This is not my first Rust rodeo, so I knew the most annoying thing was going to be wrangling async code. I found [`tokio::process::Command`][tokio-command] which has the exact same API as [`std::process::Command`][std-command] except it can be run asynchronously.

[tokio-command]: https://docs.rs/tokio/latest/tokio/process/struct.Command.html
[std-command]: https://doc.rust-lang.org/std/process/struct.Command.html

Knowing that the command could be easily run asynchronously, I knew that I wasn't setting myself up for a complete failure in the future. If I had to load each repo synchronously, one at a time, this rewrite would have been dead on arrival.

Running the subprocess exposed me to a classic Rust frustration: overly correct string types. Now, I know that I _should_ handle non-UTF-8 data, or that file paths might not be UTF-8, but since this program will only run on my own computer where I have the good taste to avoid obscure encodings, having to look up how to convert between `OsStr` and `&str` and `Path` is frustrating.

Like most of the things that I'm going to mention here, this is obviously a lack of experience. With more exposure to these APIs, I'm sure I'd get used to either quickly failing on non-UTF-8 data, or keeping data in its original type for as long as I could, avoiding the need to convert it entirely.

I needed to pass the same template to JJ so I could parse the output as JSON. I could have just written the template out as a string literal—given that it wouldn't ever change—or done what I did in Crystal and made some helper function that built the string for me. That didn't feel very Rust-y though, since building the string at runtime would require allocating a string to the heap, which was _obviously_ inappropriate. Instead I reached for my favourite hammer: writing a macro.

It's not quite as fancy as I would like (ideally I would make a custom `derive` macro that reads the attributes of a struct) but it avoids me having to look at all the triply-nested escaping.

```rust
macro_rules! make_template {
  (
    $first:ident, $first_value:literal
    $(, $name:ident, $value:literal)*
  ) => {
    concat!(
      concat!("'{\"", stringify!($first), "\":' ++ ", $first_value),
      $(
        concat!(" ++ ', \"", stringify!($name), "\":' ++ ", $value),
      )*
      " ++ '}\n'"
    )
  };
}
...

let template = make_template!(
  empty, "empty",
  description,
  "description.first_line().escape_json()",
  ...
);
```

I think splitting the first and rest identifiers is required to avoid only matching on argument lists that have trailing commas, but it has the added benefit of making it easy to avoid generating a trailing comma in the JSON.

An astute reader might be wondering at this point: now that I'm writing in Rust, why don't I just include the JJ library directly in the binary, and forgo subprocesses entirely? I did think about this originally but ultimately couldn't find a good example of reading a repo using [`jj_lib`](https://docs.rs/jj-lib/latest/jj_lib/). However, keeping JJ in a subprocess does have a bunch of advantages: I'm able to work with any JJ version—as long as they support the command-line arguments that I'm passing, so if there are changes to the config files, repo structure, supported backends, etc, I don't have to re-build my project printer.

It didn't take long before I was able to load data from every repository concurrently, so then all I had to do was print it in a nice format.

Doing this is super easy in Crystal, since you can munge together `IO` operations and string interpolation to succinctly build the output you need. Rust's `Display` trait has a bit more of a learning curve, but ends up being fairly fluid to use, at least in this case where I'm just printing one repo per line, and I'm happy to cut some corners to make the implementation a bit easier.

I looked for a library that would deal with ANSI colour codes for me, and found [`ansi_term`](https://docs.rs/ansi_term/latest/ansi_term/) as the top search result. It seemed to do what I wanted, and the API was pretty reasonable. However, it had one shortcoming: it didn't support colouring anything other than strings. The API looks like this:

```rust
use ansi_term::Colour::Blue;
println!("this is normal: {}", Blue.paint("this is blue"));
```

The `paint` function only accepts strings, and I want to print the number of outstanding commits in different colours depending on their status. What I could have done is just turned the number into a string using `format!` and then printed that:

```rust
let num = 5;
let string = format!("{}", num);
println!("this is a number: {}", Blue.paint(string));
```

But when I'm writing Rust I want to get into the traditions, and this does an unnecessary allocation: you're creating a temporary string just to print it out on the very next line. In Crystal I wouldn't think twice about this, since it's trivial syntactically to create an intermediate string, and at the end of the day this code is nowhere near performance sensitive enough for this to make a difference.

However, when in Rome...

I rolled up my sleeves and implemented a wrapper type that would allow for colouring _any_ type that implemented the standard `Display` trait. Somewhat predictably for me, this involved jumping somewhat off the deep end into generic type constraints.

This was made by simplifying the existing code in `ansi_term`, replacing all the `Cow` strings with a generic type that has a known size and implements `Display`:

```rust
#[derive(PartialEq, Debug)]
pub struct ANSIPrintable<T: Sized + Display> {
  style: Style,
  wrapped: T,
}
```

Then making a helper method to apply the colour:

```rust
#[must_use]
fn painted<T: Sized + std::fmt::Display>(style: Color, input: T) -> ANSIPrintable<T> {
  ANSIPrintable {
    wrapped: input,
    style: style.normal(),
  }
}
```

And finally implementing `Display` on the wrapper type to emit the surrounding escape codes, then delegate to the `Display` implementation on the wrapped type:

```rust
impl<T: std::fmt::Display> fmt::Display for ANSIPrintable<T> {
  fn fmt(&self, w: &mut fmt::Formatter) -> fmt::Result {
    write!(w, "{}", self.style.prefix())?;
    self.wrapped.fmt(w)?;
    write!(w, "{}", self.style.suffix())
  }
}
```

This did help me understand some of the behaviours of Rust's generics and traits, since they differ significantly to my normal mental model of interfaces coming from Java. In retrospect, I probably should have made `T` a reference, and used a lifetime specifier to indicate that the wrapper type cannot outlive the data that it is wrapping. But since this only needs to work for numbers (which are trivially copyable) this didn't matter.

After this I was ready to submit a pull request to the library, maybe they'd have a better way of doing it, but this was definitely a nice feature to have. That was when I realised the last commit to `ansi_term` was six years ago, which probably means they're not interested in pull requests. Sure enough I was not the first person to make this request, or the first person to propose a change implementing it.

Looking at the issues on the repository, a lot of people suggested the [`colored`](https://docs.rs/colored/latest/colored/) library as an alternative that's actively maintained (not that there are many new ANSI colours that you need to keep up with) and also supports suppressing the colours on terminals that don't support them. The API was slightly different but still simple enough, so I swapped my code over to use `colored`.

Then I realised that `colored` also doesn't support numbers. I could re-implement the same wrapper, but first I might as well look at the issues...

Which then led me to [`owo-colors`](https://docs.rs/owo-colors/latest/owo_colors/), _another_ ANSI colouring library. It supports numbers, so I swapped over the code one last time to the `owo-colors` API.

This is definitely the biggest difference in development experience moving from Crystal to Rust. Crystal has everything in the standard library: async runtime, async subprocess management, terminal colouring, JSON parsing, date and time handling, etc. It's rare (at least for the projects that I make) for me to pull in a third-party library. The most common thing I pull in is [`geode`](http://codeberg.org/willhbr/geode), my own set of helper functions, and even then that's mostly just to get some logging and formatting styles that I prefer.

Of course, this is due to the difference in focus between Crystal and Rust. Crystal is a batteries-included application programming language, designed to be fast _enough_ while also being easily understood by developers that are familiar with Ruby. Rust by itself is a systems programming language, that can be used to write applications that run on desktop OSes.

As much as I understand the decision to have a very small standard library, I do wish I could just add a single dependency and get a more batteries-included environment that's useful for writing non-embedded applications. Similar to how the Swift standard library is small, with much of the functionality being in the [Foundation](https://github.com/swiftlang/swift-foundation) library.

Although I'm sure with time I would just find a set of libraries that would give me the functionality I was after.

I think this rewrite was a success, the project is so simple that the process wasn't particularly daunting at any point. Re-learning how to map out data structures with lifetimes is definitely the piece that I find most challenging with Rust, and this project was easy since it didn't require any of that. I've still got a bit to learn before I can use Rust's error handling correctly, I realised during this project that it's much more manageable to treat anything you don't expect to happen as a fatal exception, and leave `Err(_)` for the cases that you'll actually recover from, which is a bit of a perspective shift when you're used to throwing and catching exceptions wherever you please.

If printing projects is a personal priority, you can procure my project progress printer [from Codeberg][ppp].
