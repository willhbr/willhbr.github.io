---
title: "Ruby Scripting Utilities"
tags: tools
---

I think I'm pretty good at shell scripting: I quote my variables, I know the difference between `$@` and `$*`, I know about checking that variables are set with the `?` suffix. I've spent a lot of time messing around with shell scripts, but I always feel like the script that I write is almost always dictated by what's easy or possible to do in the shell.

The main reason I did this was for a self-inflicted concern for portability. If I only wrote shell scripts, I could have everything working on any platform, without having to install additional dependencies or build custom executables.

Last year I decided that I'd had enough, and I gave myself permission to assume that any computer I was actually using would have Ruby installed. This led me to create an easy way to [use Ruby expressions as replacements for `sed` or `awk`][ruby-shell-pipelines]. I then [replaced the script][install-rb] that installs all my Zsh, tmux, and Vim plugins with a simple Ruby script.

[install-rb]: https://codeberg.org/willhbr/dotfiles/commit/3dd076de57bf1bb29b4ab3018c70365623cebac5
[ruby-shell-pipelines]: /2025/06/08/using-ruby-in-shell-pipelines/

Ruby has been my go-to scripting language for ages, but now I'll skip straight past a shell script and go right to Ruby instead. I've been using it for one-off scripts as well as small utilities.

The biggest problem is that I constantly end up writing this function:

```ruby
def run(*args)
  unless system *args
    raise "command failed: #{args.join ' '}"
  end
end
```

If you're not fluent in Ruby, `system` runs a subprocess that inherits the IO of the Ruby process, and returns `true` or `false` depending on the exit status of the program. The way I almost always want it to work is to just stop the whole program if something goes wrong, so I always write out this little helper.

The next issue is that I'm really used to [Crystal's `Process` class][crystal-process] that makes it really easy to manage subprocesses. Paired with Crystal's event loop and `IO` module, it's easy to read and write data to the program, or just spawn it and wait for it to finish.

[crystal-process]: https://crystal-lang.org/api/latest/Process.html

You can do lots of stuff with Crystal's `Process`, but in a script all I really want to do is:

- Run a program and throw an exception if it fails
- Run a program and capture its output (also throwing an exception if it fails)

My `run` method does the first. The second can almost be done with the special backtick `` ` `` method:

```ruby
files = `ls`
```

This is great until you want to pass some arguments in, because it only supports string interpolation, not passing in separate arguments. That's _fine_ for a one-off script where I know the input, but I'd rather not worry unnecessarily about shell injection problems.

Ruby does have an alternative: `Open3.capture2e`. It's not exactly the kind of fluent API I'd like:

```ruby
require "open3"

output, status = Open3.capture2e('jj', 'commit', '-m', message)
if status.exitstatus != 0
  raise "jj command failed"
end
# => do something with output
```

So what I've done is make use of the `RUBYLIB` environment variable. It points to an additional place (or places) that Ruby will look when you `require` a file. Instead of having to bundle common code in a gem, or rely on writing out an absolute path to exactly where my common code is, I can just:[^process]

[^process]: It's probably not the best idea to call this `process`, and chucking this in the `RUBYLIB` path could definitely cause a weird problem at some point. I just didn't want to have a non-obvious name.

```ruby
require "process"

output = Process.capture 'jj', 'commit', '-m', message
```

I've added the two methods for calling external programs that I've been wanting, and then of course added a little helper library for interacting with JJ repos. You can see them in [this commit](https://codeberg.org/willhbr/dotfiles/commit/c013021466f53d000a07608f93d931f8f0311381) in [my dotfiles repo](https://codeberg.org/willhbr/dotfiles/src/branch/main/rubylib). The intention here isn't to create something to be used by other people, it's purely so I can write scripts more easily.
