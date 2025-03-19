---
title: "Snakes in a Pane: Building Snake Entirely Within a tmux Config File"
tags: tmux projects
image: /images/2025/snake-eyes.png
---

Honestly I'd stop if I could, but I just get carried away. After [making a compiler for tmux][tmux-compiler], then [solving sudoku][tmux-sudoku], then [playing video][tmux-video] I wasn't planning on making a game. These things just happen to you. Well maybe not to you, but they happen to me.

[tmux-compiler]: /2024/03/15/making-a-compiler-to-prove-tmux-is-turing-complete/
[tmux-sudoku]: /2024/12/27/solving-sudoku-with-tmux/
[tmux-video]: /2025/03/17/playing-video-with-5170-tmux-windows/

Unlike the [video player][tmux-video], this isn't just rendering Snake inside tmux. The entire game—input, game logic, and rendering—is done using tmux config files. You just load tmux with this config, and you'll have Snake. Check out the [code][tmux-snake-repo] or have a look at me playing it in [the video][snake-video]:

[tmux-snake-repo]: https://github.com/willhbr/tmux-snake
[snake-video]: https://youtu.be/djuRZN6ecQQ

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
<iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
  width="650" height="400" src="https://www.youtube.com/embed/djuRZN6ecQQ"
  title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>

The display works the same as [my video player][tmux-video]. It uses many tested sessions to create a stack of status lines, each with enough windows to span the width of the screen. The "display" is updated by setting the style of the window to correspond with the window name, and then changing the name to the appropriate colour. In this case I'm only using two colours, whereas in the video I was using the full range of ANSI colours.

[tmux-video]: /2025/03/17/playing-video-with-5170-tmux-windows/

There's a big difference in how I initialise the screen, with the video player I used a recursive script to start all the nested tmux sessions, and since I knew the width upfront (it has to be static as the video needs to be scaled) I just generated the right number of `new-window` calls. Since I wanted this to be _entirely_ tmux, I worked out a way of doing this without a shell script.

Instead of recursively calling a shell script to fill the height, I set the `default-command` (run whenever you create a new window) to be:

```conf
TMUX= tmux if-shell -F "#{e|>:#{window_height},1}" new-session
```

Every time a new session is created, if the height of the window in that session is more than one row, we'll create a new session. Once we've filled the height, the command will exit without creating another session.

To fill each session with windows, I added a hook for `session-created`:

```conf
set-hook -g session-created {
  run -C "set -g @width '#{e|/:#{window_width},2}'"
  run -d 1 -bC 'source-file create_windows.conf'
}
```

After a short delay, this will load `create_windows.conf`:

```conf
if -F '#{e|<:#{session_windows},#{@width}}' {
  new-window -b 'exit'
  select-window -t '{last}'
  source-file create_windows.conf
} {
  if -F '#{e|==:#{window_height},1}' {
    source-file -t '$0' init.conf
  }
}
```

This script checks if there's enough room for another window, and if so it creates one and loads itself again. Once we've filled the width, I check if this is the final window to be created, and if so I load the main game logic in `init.conf`.

Instead of recursively calling `source-file`, I could have done this with a recursive keybinding, but the end result is about the same. It might be faster to use keybindings, but you'd have to worry about the keys getting sent to the right session which isn't something I have to do here.


Unlike displaying the video, I would only need to change 1-2 pixels per update, instead of a whole frame worth. The only things that move are the head and tail of the snake and the location of the apple. Keeping track of this was a bit more challenging for the game logic, but for the display it just meant a few `rename-window -t Y:=X` commands.

One addition here is the ability to give the snake eyes, both because it's cute, as well as differentiating the head and tail:

![image of cute tmux snake](/images/2025/snake-eyes.png)
{:loading="lazy"}

Isn't it adorable?
{:class="caption"}

This could have been done just by changing the `window-status-format` of the window where the head was located, but I wanted to do this in a more tmux-y, declarative way. I ended up using the "marked pane" feature to do this. As the snake moved I would select the window that contained the head as the marked pane, and updated the format of each window to show eyes only if they were the marked window:

```conf
set -g window-status-format '#[fg=colour0,bg=colour#{window_name}]#{?#{window_marked_flag},#{@eyes},  }'
```

Before I implemented this I thought I was going to need a complicated conditional to check the direction and swap between different eyes, but I realised that since the eyes will only change if the user gives input, I just need to set `@eyes` whenever the user presses a key that changes the direction.

Reading user input is something I knew would be easy, but even then I made it overly complicated. I used `bind-key -n` to add bindings that didn't require the prefix first, and set those up for `Up`, `Down`, `Left`, and `Right`. Originally I had these setting a variable for the direction we needed to face, which I'd then read during the update and change the position. This would have required a conditional for each direction which is messy. Thankfully I realised the much easier thing to do: the arrow keys set `@x_change` and `@y_change` to 1, 0, or -1 depending on the direction. Then every update I just add the change to the position.

This also made it easier to validate the input—you don't want to allow changing directly from left to right without first moving up or down. That's as simple as ensuring `@x_change` or `@y_change` is zero before setting it:

```conf
bind -n Left {
  if -F '#{@x_change}' { } {
    set -g @new_eyes ' :'
    set -g @x_change -1
    set -g @y_change 0
  }
}
```

The final part is implementing the game logic. Just so we're super clear: the game logic is also just more tmux config. There's no little program working out where the snake should go, it's all done by tmux itself.

I used the same approach I did for the [sudoku solver][sudoku-solver]: running `send-keys` to trigger keybindings back within tmux itself. In the end I only needed a single keybinding, which steps the game forward one iteration and schedules the next frame using `run -d`:

[sudoku-solver]: /2024/12/27/solving-sudoku-with-tmux/

```conf
bind G {
  # game logic goes here!

  run -C "run -d '#{@speed}' -bC 'send-keys -t $0 C-b G'"
}
```

By setting the delay on `run` with a variable, I could easily increase the speed of the game as more apples were eaten. In theory any tmux session could handle the key binding—they're all on the same server—but I decided to play it safe and always target the outermost session.

Once we've got a function that'll be called on each update, all we need to do is move the head of the snake in the right direction, move the end of the snake, and check whether we've eaten an apple.

```conf
set -Fg @head_x '#{e|%:#{e|+:#{@head_x},#{@x_change}},#{@width}}'
set -Fg @head_y '#{e|%:#{e|+:#{@head_y},#{@y_change}},#{@height}}'

if -F '#{e|<:#{@head_x},0}' {
  set -Fg @head_x "#{e|+:#{@head_x},#{@width}}"
}
if -F '#{e|<:#{@head_y},0}' {
  set -Fg @head_y "#{e|+:#{@head_y},#{@height}}"
}
```

This first section moves the head, stored as a separate variable to the rest of the body so it's easier to keep track of and handle collisions. As I mentioned before the key inputs just set `@x_change` and `@y_change` so all I had to do here is add them to the head position. To allow wrapping around the screen I modulo them, which requires a second step as the modulo operator will leave negative numbers.

In order to support collisions (where the snake eats itself) I needed to keep track of the body positions. It's difficult to get the name of a particular window, so I keep track of this separately to the actual display.

What I really need is an array, but tmux doesn't have those. Instead, each segment is stored as a fixed-length string with known delimiters, so `.12 :=5  .` would correspond to row 12 and column 5.

```conf
set -F @len "#{e|*:#{@length},10}"
set -Fg @body '#{E:##{=#{@len}:@body#}}'
# later we prepend the head position onto the body
set -Fg @body '.#{p3:@head_y}:=#{p3:@head_x}.#{@body}'
```

To remove the last segment, I use the string length-limit operator and double-expand it to allow using a variable as the length. I store the number of segments in `@length`, and since the string for each segment is fixed length, I just need to multiply this by 10.

The delimiters are added on either side to make it easier to do a substring match without running into false positives. I build a string out of the `@head_x` and `@head_y`, and if that's found in the `@body` then the snake has eaten itself, and the game is over.

```conf
if -F '#{m:*.#{p3:@head_y}:=#{p3:@head_x}.*,#{@body}}' {
  display-menu -x C -y C -c /dev/pts/0 \
    -T ' Game over! score: #{e|-:#{@length},3} ' \
    'quit' q {
      kill-server
    }
}
```

`@body` is convenient for collisions, but not for moving the tail of the snake. For that I—very wastefully—set a new variable that tells me which window needs to be reverted back to the default colour at which step. By keeping track of the length of the snake and how many iterations there have been, I just lookup what the position was N steps ago, and swap that square back.

```conf
set -Fg @step "#{e|+:#{@step},1}"
run -C "set -g '@body_#{@step}' '#{@head_y}:=#{@head_x}'"
```

These variables are formatted as a window selector—with the `:=` in the middle—so they can be passed to `rename-window` with a double expansion to do the indirection:

```conf
run -C 'set @var "@body_#{e|-:#{@step},#{@length}}"'
run -C 'rename-window -t "#{E:##{#{@var}#}}" ""'
```

During the update we need to toggle the colour for the head. This only needs to be done once as it'll remain the same colour until we toggle it back. For the eyes to show on the head, I set the same window as the marked pane. Only one pane can be marked at a time so I don't have to un-set this.

```conf
run -C "rename-window -t #{@head_y}:=#{@head_x} 2"
run -C "select-pane -t #{@head_y}:=#{@head_x} -m"
```

Here's the important bit: checking whether we've eaten an apple. A simple string match on the x/y-coordinates enough. Then increase the speed and length.

I couldn't think of a proper random number generator within tmux, but thankfully there are plenty of variables in the _FORMATS_ section that'll give us some random-enough numbers, especially if we combine them with the current step number. I ended up going with `client_written` which I assume will increase somewhat regularly as escape sequences and whatnot are written to the terminal. From my play-testing this was good enough.

```conf
if -F '#{&&:#{==:#{@apple_y},#{@head_y}},#{==:#{@apple_x},#{@head_x}}}' {
  set -Fg @speed "#{e|*|f|2:#{@speed},0.8}"
  set -Fg @length "#{e|+:#{@length},1}"

  set -F @seed "#{e|+:#{client_written},#{@step}}"
  set -F @var "#{e|%:#{@seed},#{@width}}"
  set -Fg @apple_x '#{@var}'
  set -F @var "#{e|%:#{@seed},#{@height}}"
  set -Fg @apple_y '#{@var}'
}
```

The last job of the update function is to schedule the next update—if we haven't ended the game—and then it all happens again. Unlike playing video, where you want as many updates per second as possible, tmux is able to keep up with this reasonably well.

- conclusion
	- it's actually shorter than my tmux config (150 lines vs 190)
	- you could probably do Tetris and suchlike

Believe it or not, the entire implementation is written by hand, and is fewer lines than my actual real-world tmux config—140 versus 192. All you need to play it is tmux, around version 3.4 or so. Grab the [code from here][tmux-snake-repo] and give it a go!
