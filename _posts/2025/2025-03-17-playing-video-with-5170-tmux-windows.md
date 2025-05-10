---
title: "Playing Video With 5,170 tmux Windows"
tags: tmux projects
image: /images/2025/apollo-13.webp
---

You know how there's [that scene in Apollo 13][apollo-13] where they need to work out how to fit the different CO<sub>2</sub> filter using only the equipment available on the spacecraft? Well imagine if you needed to send a video to someone but the only software they had to play it back was tmux. This hasn't happened to me yet, but thankfully I've prepared in advance. Just in case.

[apollo-13]: https://www.youtube.com/watch?v=ry55--J4_VQ

The most basic building block here is a tmux window. We're not going to use the actual terminal bit—I'm just interested in the status line, the bar at the bottom of the screen. You see, you can change the style of how the windows appear in the status line, I do this to differentiate the current window from the rest:

![tmux status line with different window styles](/images/2024/tmux-status-line.gif){:loading="lazy"}

The active window is grey and white, inactive ones are dark grey, and windows with activity or a bell are purple.

In that image you might see four windows, but what I see is four pixels. If I add more windows, I get more horizontal pixels.

Showing multiple rows of pixels is a little trickier, but not impossible. It's not recommended—tmux will insist that it's a bad idea—but you can run one tmux session inside another. If you do it looks like this with two status lines:

![two tmux status lines stacked on top of one another](/images/2025/tmux-double-status.webp){:loading="lazy"}

Since you can have one tmux inside another, what's to say you can't have three tmux sessions nested one inside the other inside the other? Who's going to stop you from repeating the nesting 55 times? That way we have 55 status lines, each with their own windows.

If we just rename each window to `"  "` so that the window indicator appears as a square, we've made ourselves a 94&times;55 pixel display. All out of tmux windows.

It turns out that a single tmux server process is only able to open just over 2,000 windows (on my machine) before being limited by what I think is the maximum number of file descriptors a process can have open. Pesky limitations like this will not get in my way, however.

Since we don't care about whether the window actually has a shell in it or not, what we want is to open shell-less processes. That way we could scale our display up to whatever size we wanted. Of course, tmux has a feature for this exact purpose.[^purpose-unsure]

[^purpose-unsure]: Ok I'm not 100% sure if opening thousands of windows in order to play back video in a stack of status lines was the original goal.

There is an option called `remain-on-exit`, and when it's set to `on` your windows will remain open and visible even after the process they contain has exited. I can just enable it and whenever I create a new window I run it with a custom shell command: `exit`. The shell in the window immediately exits, leaving a process-less window and skirting around the file descriptor limit.

Now that we can open as many windows as we want, we then take advantage of window styles to control how each window appears:

```conf
set -g window-status-format '#[bg=colour#{window_name}]  '
set -g window-status-current-format '#[bg=colour#{window_name}]  '
```

This tells tmux to set the background colour of the window indicator to the ANSI colour corresponding to the window name. If we rename the window to "183" it'll turn a lovely lavender colour.[^lavender] If we set it to "2" it'll be green.

[^lavender]: A very similar colour to the dark mode of my website!

Now we just read an image, go over each pixel, and turn it into a tmux command that renames the appropriate window to the corresponding ANSI colour. I used [Pillow](https://pypi.org/project/pillow/) to do this, since it's the image-manipulation library I'm most familiar with:

```py
image = (Image.open(path)
  .resize((width, height))
  .convert('RGB')
  .transpose(Image.FLIP_TOP_BOTTOM))

for y in range(height):
  for x in range(width):
    col = to_ansi(image.getpixel((x, y)))
    output.write(f'rename-window -t {y}:={x} {col}\n')
```

That `-t {y}:={x}` syntax is a simple tmux window-selector syntax. The script will generate something like `-t 5:=12` which will target the window at index 12 in the session named "5". Since our sessions are automatically named starting at 0, this gives us a y-coordinate starting from the bottom of the screen. That's why we `.transpose(Image.FLIP_TOP_BOTTOM)` the image first.

Converting from RGB colours to ANSI is a bit tricky but thankfully [this Stackoverflow answer](https://stackoverflow.com/questions/15682537) was easy to translate from JavaScript to Python, and seems to translate the colours correctly.

We just need to add a keybinding to load the generated config file with all the `rename-window` commands in it:

```conf
bind -n a {
  source-file "generated/frame.gen.conf"
}
```

Once loaded it'll rename all the windows and show an image entirely made up of windows in tmux status lines:

![a very pixellated still frame from Apollo 13 inside tmux](/images/2025/apollo-13.webp){:loading="lazy"}

Now, video is a bunch of images. We just need to grab a video from somewhere, use `ffmpeg` to convert the video to images, run that through my script to convert the images into a series of tmux config files, and then have the last statement in the config file schedule loading the next file:

```conf
...
rename-window -t 54:=79 146
rename-window -t 54:=80 109
run -d 0.5 -bC "source-file 'generated/frame-18.gen.conf'"
```

The `run` command allows delaying the execution, which I use to set the playback frame rate. Anything more than 2-3 FPS results in artefacts as tmux isn't able to re-draw all the status lines fast enough.

I was able to make this marginally more efficient by only renaming the windows that had changed from the previous frame, significantly reducing the number of `rename-window` commands in each config file, since most frames are pretty similar to their predecessor.

And so once we've compiled the video into config files, we're able to play it entirely within tmux:

<div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;">
<iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
  width="650" height="400" src="https://www.youtube.com/embed/LbzVmDITCoo"
  title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>

Have a look at the [complete code here](https://codeberg.org/willhbr/tmux-video), or read about the time I [solved a sudoku in tmux](/2024/12/27/solving-sudoku-with-tmux/) or [compiled Python to tmux configs](/2024/03/15/making-a-compiler-to-prove-tmux-is-turing-complete/).
