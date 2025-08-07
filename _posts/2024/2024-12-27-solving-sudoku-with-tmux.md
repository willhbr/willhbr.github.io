---
title: "Solving Sudoku with tmux"
tags: tmux projects
---

The question that everyone has been asking me since I [compiled Python to run on tmux][tmux-compiler] is: "can you actually do anything useful with this?". I'm happy to report back that the answer is still no, but I can now use tmux to solve sudoku, and I can do it using a different and trickier approach than the one I used with the compiler.

[tmux-compiler]: /2024/03/15/making-a-compiler-to-prove-tmux-is-turing-complete/

With projects like this, seeing is believing, so I made a [quick video showing what it looks like][tmux-video]:

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
<iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
  width="650" height="400" src="https://www.youtube.com/embed/Tz74vs_nH7M"
  title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>

[tmux-video]: https://youtu.be/Tz74vs_nH7M

If you want to just check out the code for yourself, you can see the code [on Codeberg][sudoku-codeberg] but the real joy is understanding in great detail how this works.

[sudoku-codeberg]: https://codeberg.org/willhbr/tmux-sudoku

I got the idea for this project after seeing [_konsti_ write a sudoku solver using Python dependency resolution][sudoku-pip]. This seemed like an interesting area to apply my (very weird) expertise. It's also much more useful than the `is_prime` function that I ran on tmux before.

[sudoku-pip]: https://github.com/konstin/sudoku-in-python-packaging

My Python-tmux (and Brainfuck-tmux) compiler worked using [tmux hooks][hooks]. You can activate a hook when a client navigates to a particular window, and that hook can then run any tmux action, like create a new window or split the window into separate panes. You can run multiple actions on one hook, and by having the last action navigate to the next window, you can treat tmux windows and their hooks as instructions in a program. Control flow is implemented by jumping forwards or backwards over multiple windows, depending on the value of a variable.

[hooks]: https://www.man7.org/linux/man-pages/man1/tmux.1.html#HOOKS

Since I'd made the compiler, I knew it was _possible_ to solve a sudoku, but my compiler doesn't support arrays, strings, or scoped/non-global variables, so it would either be incredibly painful, require changes to the compiler, or both.

Instead, I wanted to think of a different approach. After a lot of deep thinking and head-scratching, I have created a short tmux program that can solve a sudoku using just two `bind-key` statements.

The sudoku is represented as up to 81 tmux user-defined options—prefixed with an `@`:

```conf
set -g @x2y0 '4'
set -g @x4y0 '5'
set -g @x0y1 '9'
set -g @x3y1 '7'
set -g @x4y1 '3'
set -g @x5y1 '4'
set -g @x6y1 '6'
...
```

Since this is a bit tedious to write out by hand, I wrote a script that turns a more human-editable grid into the `set` commands. You could implement this in tmux itself, it would just be a bit of a faff, and we're here for sudoku solving, not string processing.

The second part of this pre-processing step is to make an "array" containing the indices of the blank squares in the sudoku.

```conf
set -g @blanks '0010305060708011217181021232620333538304243444'
```

Every two characters is an xy coordinate of where there is a blank cell that needs to be filled in. Like loading the human-readable sudoku into the coordinate-based variables, this could be done in tmux but for simplicity my script outputs this as well.

The key part of my sudoku solver is the ability to quickly check whether the sudoku is solved. Since we're brute-forcing the solution, we'll have to check _a lot_ of possible solutions, so we want this to be fast. An advantage of writing the tmux config file manually (as opposed to compiling "Python"), is that we can basically write a single "instruction" to do this check in one go. That way we're spending much less computation time in the cursed tmux "VM".

We can use variable expansion to build a string with the contents of each row, column, and 3x3 cell. For example to get the first row:

```
#{@x0y0}#{x1y0}#{x2y0}#{x3y0}#{x4y0}#{x5y0}#{x6y0}#{x7y0}#{x8y0}
```

This gives us a string like `879254316`. You can then use string matching to check that it contains every number from 1 to 9. You can't do this with one string match, you have to do it nine separate times. A single check looks like this:

```
#{m:*1*,#{@x0y0}#{x1y0}#{x2y0}#{x3y0}#{x4y0}#{x5y0}#{x6y0}#{x7y0}#{x8y0}}
```

tmux will expand this to `1` if the first row contains a 1, and `0` if it does not. You then just have to do this for every other number:

```
#{m:*1*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*2*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*3*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*4*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*5*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*6*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*7*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*8*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
#{m:*9*,#{@x0y0}#{@x1y0}#{@x2y0}#{@x3y0}#{@x4y0}#{@x5y0}#{@x6y0}#{@x7y0}#{@x8y0}}
```

I've split this into multiple lines to give it some semblance of readability, but in the actual program this whole check is part of one _huge_ line. It's that snippet repeated eight more times for the rest of the rows, then nine more times for every column, and _then_ nine more times for the 3x3 grids. It's a _really_ big string expansion.

Once expanded, this gives us a string of 243 ones and zeros. The resulting string will be entirely ones if the sudoku is solved. If there's even a single zero, then we've got a number out of place. You just use another string match to check for any zeroes, and that tells you if the sudoku is solved.

The `if` (alias for `if-shell`) command in tmux will by default run the program in a sub shell and do the action depending on the exit status. However with the `-F` flag it'll instead expand variables in the argument and treat it as truthy if it's `1` or a non-empty string, and falsy if it's `0` or empty. With this you can have branching control flow without the need to jump between windows like I'd done with the compiler.

```conf
if -F '#{window_zoomed_flag}' {
  display "The window is zoomed"
} {
  display "The window is not zoomed"
}
```

That's how you might use `if` in a tmux config file. It even supports braces (same as any other tmux command) and can be given an `else` block.

If you've [actually written a sudoku solver][sigh-solver] you might think of all the optimisations you could make so that it can find the solution to a "hard" sudoku in a reasonable amount of time. This project is not about doing things reasonably, so I chose to just enumerate every possible solution, and check if it was solved every time.

[sigh-solver]: https://github.com/sigh/Interactive-Sudoku-Solver

My first approach was to use sessions as a call stack and use a recursive-style algorithm. The first session would check if the sudoku was solved, if not then it would increment the number in the first blank cell and create a new session to check the all combinations of the next blank cell. That second session would do the same and the recursion would continue for every blank cell until there were none left. If that didn't solve it, then the sessions would all exit back to the start and you'd try again with the next number.

I poked around with this approach for a while, but struggled with how to create sessions on-the-fly that were setup with the necessary hooks to do computation, and how to indicate a return from one session to another. While tinkering with this, I realised that I didn't actually need an arbitrarily large number of sessions, just one for every blank cell (i.e: at most 81 sessions), so I could just create them all upfront and swap between them instead of creating and exiting them constantly.

This made me also realise that I could just use windows instead of sessions, and move backwards and forwards as I recursed in and out. The session-local state would just be stored in window-specific options.

Before I had even started working out how to implement that, I had another realisation: I don't have to move windows at all, I can use the [recursive `send-keys` trick I'd come up with after writing the compiler][send-keys].

[send-keys]: /2024/03/16/further-adventures-in-tmux-code-evaluation/

Go and read that [whole post][send-keys] if you want to understand the nuance, but basically what you do is create a tmux session with two windows. The first window is just a shell, but the second window is _also_ tmux and is attached[^nested] to the same session that it's running in. Any keyboard input sent with `send-keys` into the second window will get sent back into tmux, and can trigger key bindings. If you want to jump from one block of code to another, you just `send-keys` the right letter(s) into the second window, and that block of code will be executed. As long as each block ends by sending a new key, the program will continue to run.

[^nested]: sessions should be nested with care, unset `$TMUX` to force.

Doing this is a little precarious, since if you accidentally navigate to the second window, tmux will start to infinitely recurse and try to redraw the current window inside itself forever. This trick should only be attempted by trained professionals on a closed course.

All I needed to do now was to match the algorithm into separate steps, create keybindings for those steps, and use `send-keys` to trigger them automatically.

This was simple in hindsight, but it took some head-scratching to write out the algorithm in such a way that it could be mapped into keybindings. The algorithm looks something like this:

```c
start:
  if (is_solved()) {
    display("Done!");
  } else {
    goto compute_next;
  }

compute_next:
  values[s] += 1;
  if (values[s] > 9) {
    values[s] = 1;
    s += 1;
    if (is_last_empty()) {
      fail();
    } else {
      goto compute_next;
    }
  } else {
    s = 0;
    goto start;
  }
```

There are a few variables in play here:

- `values` represents the grid, and we can subscript it by an index of a blank space. We know which spaces are blank because that's precomputed for us. This actually takes multiple steps, but we can think of it as a single operation here.
- `s` is the index of the blank space that we're looking at.
- The `is_solved()` function represents our huge variable expansion that tells us whether the sudoku is in a solved state.
- The `is_last_empty()` function is an error case where the sudoku might not be solvable, so the algorithm continues off into a blank space that doesn't exist.

Before I drew this out as a transition diagram, I was thinking that I'd need to define far more keybindings—more like one per instruction—but in reality it's just one keybinding for each point that control flow could jump back to. So I needed one keybinding for the code after `start:` and another for the code after `compute_next:`.

With that in mind, let's look at the final tmux program, broken down into sections.

```conf
source-file sudoku-data.conf

new-session
new-window -d 'TMUX= tmux attach -t "\$0"'
```

Here we load the data which sets all the variables to store the grid. While this program includes template expansions for brevity and to avoid errors, you only need to expand the program once. After that it can solve any sudoku defined in the `sudoku-data.conf` file.

The config file actually creates the session for you (you can do that!) so you just `attach` to it immediately, instead of running `tmux new`. This allows me to create the second window and attach back to our session by running `tmux attach` in that second window.

```conf
bind -n n {
  if -F '<%= grid_ok %>' {
    display 'Solved!'
    run "tmux set-buffer '<%= show_state %>'"
    show-buffer
  } {
    send-keys -t :1 G
  }
}
```

This keybinding is for the code in `start:`. The conditional checks whether the sudoku is solved yet. The `<%= grid_ok %>` expansion is equivalent to the `is_solved()` function from above. This template function generates the huge variable expansion that I explained above.

The `set-buffer`/`show-buffer` steps are there to print the output in a nicely-formatted way once we've found the solution.

In the else block of the conditional is the interesting bit: it uses `send-keys` to type `G` into the second window (with an index of 1), which kicks off the rest of the program to get the board into the next possible state.

```conf
bind -n G {
  rename-window '@x<%= x_sub "@blanks", "#S" %>y<%= y_sub "@blanks", "#S" %>'
  run "tmux set '#W' '#{e|+:1,#{E:##{#W#}}}'"
  ...
}
```

This is where things go off the rails. What we're actually doing here is looking into the `@blanks` "array" to find the next blank cell that we need to increment. We have to do some serious shenanigans to extract the two numbers out of the "array".

I wrote two helper functions to do this, they are replaced with a nasty variable expansion, here's the result of `<%= x_sub "@blanks", "#S" %>`:

```
#{=1:#{=-#{e|-:#{n:@blanks},#{e|*:2,#S}}:@blanks}}
```

`#{n:@blanks}` gives us the length of the "array", `#{=1:` and `#{=-` truncates the string to a set number of  from the start or end, and `#{e|-:` and `#{e|*:` do arithmetic. Put this all together _very_ carefully, and you get a single number from the `@blanks` array. This took a lot of trial and error to build up, and being able to break it into multiple lines in the Ruby script was really helpful. It's really annoying when you miss a single closing brace and your triply-nested expansion does something completely unexpected.

`y_sub` is basically the same, except it offsets by one to get the second character from the pair. I use the session name as the index of which blank cell I'm looking at as it's a convenient place to store a single number—I did the same thing with the Brainfuck compiler.

These few lines could be done all in one, but things were being a bit weird so I decided to split it up and use the window name as a scratch storage space. I first store the variable name of the cell position (like `@x6y3`), then increment that variable by one. `#{E:##{#W#}}` does a double-expansion, so it expands `#W` (the window name) into the variable name, then expands _that_ into the value of the variable.

```conf
  if -F '#{e|>:#{E:##{#W#}},9}' {
    run "tmux set '#W' '1'"
    rename-session '#{e|+:1,#S}'
    if -F '<%= more_array? "@blanks", "#S" %>' {
      send-keys -t :1 G
    } {
      display 'FAILED! oh no!'
    }
  } {
    ...
  }
}
```

The conditional here checks if the value we just incremented is greater than nine. If it is, we need to overflow to the next blank cell. We reset the current blank cell back to `1`, increment the session name—so that when we jump back we'll be incrementing the next blank cell. Before we jump we check that there is another number in the `@blanks` "array", the `more_array?` function generates this expansion:

```
#{e|<:#{e|*:2,#S},#{n:@blanks}}
```

Which checks that there are enough pairs of characters in `@blanks` for the newly-incremented session name `#S`.

If there are, then we `send-keys` a `G` and processing jumps back to the top of `compute_next:`, incrementing the next blank cell and overflowing if necessary. If we don't have another cell to increment, then we must have an unsolvable sudoku—since we've tried every combination at this point—so we just show an error message and give up.

```conf
  if -F '#{e|>:#{E:##{#W#}},9}' {
    ...
  } {
    rename-session '0'
    send-keys -t :1 n
  }
```

If we don't need to overflow, we've set the sudoku grid into the next state so we can jump back to `start:` and check if we've got the solution. We set the session name back to `0` since we need to increment from the first blank cell again if this isn't the solution.

I knew in the back of my mind when I wrote the Python-tmux compiler that what I was doing was horribly inefficient, but to have the sudoku solver boil down to just two key bindings really shows just how much of a brute-force solution the compiler was. You could probably make a much more efficient and useful tmux compiler by only jumping to a new window/key binding/etc when the code needs to jump as part of a loop or function call, instead of for every instruction. But that's a project for another time.

Now, how fast is it?

I made a few decorative modifications to the program, allowing it to be quit more easily, visualise the progress, write the solution to a file, and exit on completion (have a look at [the repo][sudoku-codeberg] for the final program). This made it easier to run it with `time` without me having to sit there waiting for it to complete.

I started with a solved sudoku and progressively deleted more numbers from it. With 4 numbers missing, it solved it in 41 seconds. With 5 missing, it took 6:40.[^on-nuc]

[^on-nuc]: This is running on an Intel NUC with an i5-10210U processor.

While trying to solve a sudoku with 6 numbers missing, I worked out from the status line display of the current grid state that the third missing number was incrementing once every 700ms. That means the grid is being updated 81 times in 700ms, so 8.6ms per potential solution.

After extensive research with [Good Sudoku](https://www.playgoodsudoku.com) I found that a typical "easy" had about 35 pre-placed numbers, so 46 missing numbers. That's 9<sup>46</sup> solutions that my incredibly dumb solver would have to try.

9<sup>46</sup> is 78x10<sup>43</sup>. Multiply that by 8.6ms and you get 6.8x10<sup>41</sup> seconds. This is a very, very long time. If you've done a sudoku before then you can probably solve it faster.[^samply]

[^samply]: I did take a quick trace using [Samply](https://github.com/mstange/samply) and tmux is obviously spending most of its time expanding format strings and getting options to put in format strings.
