---
title: "Using Ruby in Shell Pipelines"
tags: tools
---

Like most normal people I have spent a normal amount of time learning how to use `grep`, `cut`, `sed` and friends (but not `awk`) to manipulate the output of a shell command. Usually this is something like parsing sections of an error message so I can find at all the things that are failing and go about fixing them.

At some point a few weeks ago I hit a limit. I think I wanted to get the names of classes defined in a set of files—or something like that—so I had to extract the classname from a line like `class AbstractFactoryImpl implements FactoryFactory {`. Usually I would have done this with `sed` but with all the backslashes and forward slashes it's a right pain. You can do it with `grep` but I think you need to enable extended regex support. I thought "if this was Ruby it would be so easy" and then I realised it _could_ be Ruby. I have the power to make that happen!

So I added a script called `map` to `~/.local/bin`:

```ruby
code = ARGV[0]
STDIN.each_line.each_with_index do |it, index|
  puts eval code rescue nil
end
```

Which means I can now do:[^no-cat]

[^no-cat]: Yes I know `cat |` is pointless, it's just that it reads better for this example. `map 'it.match(/class (.*?) /)[1]' < some_file` is all backwards.

```console
$ cat some_file | map 'it.match(/class (.*?) /)[1]'
AbstractFactoryImpl
```

It's such a simple idea that I'm both surprised that I haven't seen someone else do it, and that it's taken me this long to think of it myself.

I'll probably use this same approach to simplify parsing JSON instead of using `jq`. It's great for pretty-printing, but as soon as I want to do something vaguely complicated I have to refer to the manual.

You can see my more complicated version of `map` [on Codeberg](https://codeberg.org/willhbr/dotfiles/src/branch/main/bin/map).
