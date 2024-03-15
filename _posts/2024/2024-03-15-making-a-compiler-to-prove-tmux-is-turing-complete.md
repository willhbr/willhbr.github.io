---
title: "Making a Compiler to Prove tmux Is Turing Complete"
image: /images/2024/tmux-hello-world.gif
---

You can use features of tmux to implement a Turing-complete instruction set, allowing you to compile code that runs in tmux by moving windows.

I feel like I really have to emphasise this: I'm not running a command-line program in tmux, or using tmux to launch a program. I can get tmux to run real code by switching between windows.

<iframe src="https://www.youtube.com/embed/6V3KnjiBuhU" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

[tmux-video]: https://youtu.be/6V3KnjiBuhU

This whole mess started when I [solved an issue I had with a helper script](https://github.com/willhbr/dotfiles/commit/967856270409b77814694c3963f0183ad79b377f) using the tmux `wait-for` command. I thought to myself "wow tmux has a lot of weird features, it seems like you could run a program in it" which I [joked about on Mastodon](https://ruby.social/@willhbr/112048862227851022). This idea completely took over my brain and I couldn't think of anything else. I had to know if it was possible.

I spent a week [writing a compiler][tmux-compiler] that turns Python(ish) code into a tmux config file, which when you load makes tmux swap between windows super fast and run that code.

[tmux-compiler]: https://github.com/willhbr/tmux-compiler

If you just want to run your own code in tmux, you can grab the compiler [from GitHub][tmux-compiler] or see it in action in [this video][tmux-video].

---

I'm not really a byte-code kinda guy. I've tinkered around with [plenty](https://github.com/willhbr/slang) [of](https://github.com/willhbr/slang-vm) [interpreters](https://github.com/willhbr/lisp.js) [before](https://github.com/willhbr/SwiftLisp), but those were tree-walk interpreters, or they compiled to another high-level language. I haven't spent much time thinking about byte code instructions and how VMs actually get implemented since my second year of university where we had to implement a simple language that compiled to the JVM. I do own a physical copy of the delightful [_Crafting Interpreters_](https://craftinginterpreters.com) by [Robert Nystrom](https://journal.stuffwithstuff.com), which I assume counts for _something_.

One thing I'm pretty sure I need is a stack. The easiest way to evaluate an arbitrarily-nested expression is to have each operation take the top N items from the stack, process them, and put the result on the top of the stack. The next operation takes another N items, and so on.

At every stage of this project I could think of a solid handful of different tmux features that could be used (or abused) to implement the functionality. For the stack the easiest option was to use buffers.

Buffers are supposed to be used for things like copy-pasting, but the buffer commands have some neat side-effects. If you call `set-buffer 'some value'` with no buffer name, you get a buffer named `bufferN` with "some value" in it. Every time you call `set-buffer` it gets added to the top of the list of buffers. Every time you call `delete-buffer` (without specifying a buffer name) it'll delete the topmost buffer from the list.

And just to make this even more convenient, there's a string expansion `#{buffer_sample}` that will give you the contents of the topmost buffer. We've got the perfect feature for implementing a stack.

Ok, string expansions. Most tmux commands allow for expanding variables so you can inject information about the current pane, window, session, etc into your command. For example to rename a window to the path of the current working directory, you can do:

```conf
rename-window '#{pane_current_path}'
```

These expansions are documented in the ["formats" section of the tmux manual](https://www.man7.org/linux/man-pages/man1/tmux.1.html#FORMATS). The most obvious use of these is to define the format of your status line. For example the left hand side of my status line looks like:

```conf
set -g status-left '#[bold] #{session_name} #[nobold]│ #{host} │ %H:%M '
```

`#{session_name}` and `#{host}` are replaced with the name of the current session, and the hostname of the machine that tmux is currently running on.

If you read the manual in a little more detail, you'll notice that you can actually do a little more than just inserting the value of a variable. There is a conditional operator, which can check that value of a variable and output one of two different options. I use this to show a "+" next to windows that are zoomed:

```conf
set window-status-format ' #I#{?#{window_zoomed_flag},+, }│ #W '
```

`#{window_zoomed_flag}` is `1` if the current window is zoomed, so the window gets a `+` next to the index. If the window is not zoomed, then it gets an empty space next to the index.

There are also operators for arithmetic operations, so `#{e|*:7,6}` will expand to `42`, and `#{e|<:1,5}` expands to `1` (tmux uses `1` and `0` for true/false).

Now of course you could just make a huge variable expansion and use that to make a computation, but that is quite limited. You can't make a loop or have any action that has a side-effect.

The feature that really gets things going is [_hooks_](https://www.man7.org/linux/man-pages/man1/tmux.1.html#HOOKS). You can run a tmux command whenever a certain event happens. For example, if you want to split your window every time the window got renamed:

```conf
set-hook window-renamed split-window
```

Now whenever you rename a window, it gains a split! Splendid. I never really found a legitimate use for hooks, otherwise I'd give you a less contrived example.

I did of course find a completely _illegitimate_ use for hooks. There's a hook called `pane-focus-in` that is triggered whenever a client switches to that pane. This is the key feature that makes the compiler work. You can set the hook to run multiple commands, so we can say "when you focus on this window, do X, then look at the next window". Something like:

```conf
set-hook pane-focus-in {
  set-buffer 'some value'
  next-window
}
```

Now this doesn't actually work for what I want, as tmux is too smart and won't trigger the `pane-focus-in` event on the next window, since it wants to avoid accidentally creating cycles in window navigation. This is annoying if you are trying to intentionally create cycles in your window navigation.

However, if you instead wrap the commands in a shell call, that check gets skipped:

```conf
set-hook pane-focus-in {
  run "tmux set-buffer 'some value'"
  run 'tmux next-window'
}
```

Some might say that this is cheating, but the shell is just being used to forward the command back to tmux—I'm not using any features of the shell here.

Wrapping everything in a call to `run` gives us another feature: global variable expansion. Only certain arguments to tmux commands have variable expansion on them, but the whole string passed to `run` is expanded, which means we can use variables anywhere in any tmux command. For example:

This will add a buffer containing the literal string `'#{session_name}'`:

```conf
set-buffer '#{session_name}'
```

But this will add a buffer containing whatever the current session name is:

```conf
run "set-buffer '#{session_name}'"
```

The last ingredient we need is some way to store variables. I had considered storing these as window names, but setting and retrieving these would have been a huge pain, even if it was technically possible. I ended up going with the low-effort solution. You can set custom options in tmux as long as they're prefixed with `@`. This has the limitation that you've got a single set of global variables[^not-global], but it'll do.

[^not-global]: Technically it's a set of variables per function if you pass the `-s` flag to set the option only on the current session, but not per function _call_. So if you have a function `f` that sets variable `a` and then calls itself, `a` will contain the value set from the previous function.

```conf
set @some-option "some value"
display "option is: #{@some-option}"
```

So what does it look like to actually do something? When we run the expression `1 + 2`, the result should be stored in the top of the stack.

First we add our two operands to the stack using `set-buffer`. We could inline them, but I'm going for brute-force predictability here, with absolutely no regard for optimisation.

```conf
new-window
set-hook pane-focus-in {
  run "tmux set-buffer '1'"
  run 'tmux next-window'
}

new-window
set-hook pane-focus-in {
  run "tmux set-buffer '2'"
  run 'tmux next-window'
}
```

The next bit is a little tricky, we need to have access to two values from the stack to do the addition operation, but we can only access the top using `#{buffer_sample}`. We can work around this by using the window name as a temporary storage space. We're not using the window name for anything else, and it only needs to stay there for two instructions.

We rename the _next_ window to be the top of the stack, and delete the top item from the stack. We need to keep track of window indexes for this trick (`:=4` targets window number 4), which will also be needed when we implement conditionals and goto.

```conf
new-window
set-hook pane-focus-in {
  run 'tmux rename-window -t :=4 "#{buffer_sample}"'
  run 'tmux delete-buffer'
  run 'tmux next-window'
}
```

We've got our two values accessible now—one in `buffer_sample` and one in `window_name` so now we can finally add them together:

```conf
new-window
set-hook pane-focus-in {
  run 'tmux rename-window -t :=4 "#{e|+:#{buffer_sample},#{window_name}}"'
  run 'tmux delete-buffer'
  run 'tmux set-buffer "#{window_name}"'
  run 'tmux next-window'
}
```

We rename the current window to be `#{e|+:#{buffer_sample},#{window_name}}`, which adds the two numbers together, replacing our window name scratch space. Next we delete the top of the stack (the topmost buffer) since we've consumed that value now, and put the result of the operation onto the top of the stack. Finally we advance to the next instruction.

This is the basis of all the operations needed to implement a simple Python-like language. To implement conditionals we just use a conditional expansion to determine which window to change to, instead of always using `next-window`:

```conf
new-window
set-hook pane-focus-in {
    run 'tmux select-window -t "#{?#{buffer_sample},:=6,:=9}"'
    run 'tmux delete-buffer'
}
```

If `buffer_sample` is `1` (or any other non-empty and non-zero value) we go to window 6, if it's `0` or empty, then we go to window 9. Loops are implemented in a similar way, just with an unconditional jump to a window before the current one.

The biggest challenge when I implemented the [compiler for Shortcuts][cub-shortcuts] was the fact that Shortcuts doesn't really have support for functions. I could have just dumped all the functions into a single tmux session, and jumped around to different window indices when calling different functions. But that seemed too easy.

[cub-shortcuts]: /2018/12/26/compiling-for-shortcuts/

Instead I made each function its own session, and used `switch-client` to swap the current client over to the other session. This gets difficult when you want to return back to the calling function.

I don't know how real byte code does this (see disclaimer above) but I figured that I could just put the return point on the stack before calling a function, and then the function just has to do a little swap of the items on the stack and call `switch-client` again.

I needed to use both the session name _and_ the window name as scratch storage to get this to work, but the return instruction ends up like this:

```conf
new-window
set-hook pane-focus-in {
  # the value to return
  run 'tmux rename-session -- "#{buffer_sample}"'
  run 'tmux delete-buffer'
  # the location to return to
  run 'tmux rename-window -- "#{buffer_sample}"'
  run 'tmux delete-buffer'
  # put return value back on stack
  run 'tmux set-buffer "#S"'
  # restore session name
  run 'tmux rename-session -- "func"'
  run 'tmux switch-client -t "#{window_name}"'
}
```

The function call instruction is much simpler, you just need to add all the arguments onto the stack, and then do:

```conf
# put the return point on the stack
new-window
set-hook pane-focus-in {
  run "tmux set-buffer 'main:3'"
  run 'tmux next-window'
}

# any arguments would be added here

# switch the client to call the function
new-window
set-hook pane-focus-in {
  run 'tmux switch-client -t func:1'
}
```

I know at compile time the exact instruction to jump back to, so that `main:3` is hard-coded into the program to be the name of the current function and the index of the window after the `switch-client` call.

Since window 0 on every session is "free parking", you switch directly to window 1 which kicks off the function. The return value from a function is whatever item is on the top of the stack when the function jumps back to the caller.

So I've got a subset of Python to run on tmux that can only use numbers. Is this [Turing-complete](https://en.wikipedia.org/wiki/Turing_completeness)?

I don't know. I assume it is, or at least it's close enough that you could make some changes and end up with a Turing-complete language that compiles and runs on tmux. This was enough to satisfy my curiosity and say "yep tmux is probably Turing-complete", but I don't want to go on the internet and make that claim without completely backing it up.

So obviously I have to make a full-featured compiler for a Turing-complete language. So I also wrote a Brainfuck-to-tmux compiler.

Brainfuck is exceptionally simple; it only has eight instructions:

- `>` and `<` move the data pointer to the right and left
- `+` and `-` increment and decrement the byte at the current location
- `,` reads one byte from the input stream and places it on the data pointer
- `.` writes the current byte to the output stream
- `[` jumps to the matching `]` if the current byte is zero, otherwise continues as normal
- `]` jumps back to the previous matching `[` if the current byte is non-zero, otherwise continues as normal

Initially I thought about using an infinite sequence of windows to represent the data, but then I realised that I could just create numbered variables on the fly, which is much simpler. The session name acts as a data "pointer", the windows again act as instructions, I pull from a variable for input, and use `send-keys` to the first window as output.

The instructions look like this:

```conf
new-window
set-hook pane-focus-in {
  run 'tmux rename-session -- "#{e|-:#S,1}"'
  run 'tmux next-window'
}

new-window
set-hook pane-focus-in {
  run 'tmux rename-session -- "#{e|+:#S,1}"'
  run 'tmux next-window'
}
```

`<` and `>` (above) are super simple—they just rename the session to be one more or less than the current session name. The default tmux session name is `0` so I don't even need to set it initially.

```conf
new-window
set-hook pane-focus-in {
  run 'tmux set -s "@data-#S" "#{e|%:#{e|+:#{E:##{@data-#S#}},1},256}"'
  run 'tmux next-window'
}

new-window
set-hook pane-focus-in {
  run 'tmux set -s "@data-#S" "#{e|%:#{e|+:#{E:##{@data-#S#}},255},256}"'
  run 'tmux next-window'
}
```

These two implement `+` and `-`. They read from and store their result in the variable `@data-#S`, `#S` being the session name which I'm using as the data pointer.

`#{E:` allows for double-expanding variables, so I can expand `@data-#S` into something like `@data-0` and then expand _that_ into the value stored in that variable. If the variable doesn't exist it expands to an empty string, and when you add or subtract from an empty string it gets implicitly converted to `0`.

I have to modulo the results by 256 as Brainfuck expects an array of bytes, not arbitrarily large numbers. I didn't realise this from my extensive research of skimming the Wikipedia page, so it took a bit of head-scratching while my program was looping out of control.

```conf
new-window
set-hook pane-focus-in {
  run 'tmux select-window -t ":=#{?#{E:##{@data-#S#}},6,7}"'
}

new-window
set-hook pane-focus-in {
  run 'tmux select-window -t ":=#{?#{E:##{@data-#S#}},5,7}"'
}
```

I thought that `[` and `]` would be tricky until I realised that I could pre-compute where they jumped to (I'd only ever implemented Brainfuck as a dumb interpreter before). They use the same `select-window` logic as the conditionals in the Python compiler.

```conf
new-window
set-hook pane-focus-in {
  run 'tmux set -s "@data-#S" "#{=1:@input}"'
  run 'tmux set -s "@input" "#{=-#{e|-:#{n:@input},1}:#{?#{e|==:#{n:@input},1},0,#{@input}}}"'
  run 'tmux next-window'
}

new-window
set-hook pane-focus-in {
  run 'tmux send-keys -t ":=0" "#{a:#{e|+:0,#{E:##{@data-#S#}}}}"'
  run 'tmux next-window'
}
```

This has some serious tmux expansion going on, but the basic idea is to implement `,` by taking the first character from the `@input` option, and then truncate the first character from `@input`. This is easier said than done as it requires getting the length and calculating the substring manually.

`.` is much simpler, I just take the current value and pass it to `send-keys`, using the `#{a:` expansion filter to turn the number into an ASCII character.

A limitation of my implementation is that the input will only get interpreted as numbers—tmux doesn't have a way to convert ASCII characters to their numeric code points.

![screenshot of tmux in a terminal with "Hello world" printed in the top left](/images/2024/tmux-hello-world.gif)

This still from the [video][tmux-video] shows the output of the Brainfuck "Hello world" program from Wikipedia.
{:class="caption"}

If you look at any of the compiled example programs in the [repo][tmux-compiler] you can see that I'm not exactly generating the most optimised code. For example to run this super simple program:

```python
a = 1
print(a)
```

The compiler will:

1. Push `1` onto the stack
2. Set `@a` to the top of the stack
3. Pop the top of the stack
4. Push the value of `@a` onto the stack
5. Call `display-message` with the topmost element from the stack
6. Pop the top of the stack
7. Push `0` as a "return value" of `print` to the stack
8. Pop the top of the stack, since no one consumes it

All that _could_ be replaced with something much simpler:

1. Call `display-message` with the value `1`

But that requires much more analysis of the actual program, and I'm not going for efficiency here, so I accepted generating unnecessary instructions.

Like I mentioned earlier, there are plenty of other ways that the data could be modelled. I was considering using window names to store my variables, but you could also store data in the tmux window buffers themselves—using `send-keys` and `capture-pane` to read and write data. Or maybe you could have nested sessions, where the outermost session windows are the instructions, and the inner session windows are the data. Window splits and layouts would be another possibility for storing data. That's also not even considering the possibility of moving windows around to change how the program runs while it's running. Perhaps `update-environment` is a better variable store than custom options?

If you want to continue this project and implement an LLVM backend that targets tmux, or just want to hack around with tmux in general, you use the `-L some-socket` flag to run a separate server, so you don't mess up your actual tmux server. Instead of starting a normal shell in every window, I ran `tmux wait-for main`. That way I could run `tmux wait-for -S main` to close every single window at once—since if you try and close them one-by-one you end up running parts of your program. Alternatively, `tmux kill-server` will probably do the trick.

Overall I'm super happy at how well this ended up working, and how directly the various concepts of a normal instruction set can be mapped to tmux commands.

I ran a benchmark to see how tmux-python compares to Python 3.11.4. I didn't want to wait around for too long so I just used my `is_prime` example to check whether 269 is a prime. On my dev machine, Python runs this in 0.02 seconds, whereas my tmux version takes just over a minute.
