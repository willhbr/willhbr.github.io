---
title: "How to: Yosemite Dark Mode Terminal"
---

After upgrading to Yosemite I found myself blinded by the whiteness of the menus, dock folders and launchpad folders. Too much white for my liking - so I switched to the new dark mode, which makes most of the components black:

+ Menu bar
+ Dock
+ Menus
+ Dock folders

But leaves these white:

+ Notifications
+ Launchpad folders
+ Other app UI

Previously my terminal was set up like this:

![Original terminal](/images/2014/dark-mode-terminal-1.png)

This is the _Pro_ theme with a slight transparency and a custom `PS1` variable - just add this to your `.bash_profile`:

```shell
export PS1="\[\033[0;36m\]\h \[\033[0;37m\](\W) "
```

## Yosemite Style

I decided that for Yosemite the background should be blurred and have the same transparency as the menu bar, so I inspected a screenshot and found it to have 70% opacity. To mimick this look I went to:

`Terminal > Preferences > Profiles > Window > Background`

Set the background to black, the transparency to 70% and the blur to 100% for 'dat Yosemite style:

![Blurred, transparent terminal](/images/2014/dark-mode-terminal-2.png)

And that's that. I think the blur on other parts of Yosemite's UI may be a wee bit more complicated, or at least 'stronger'. The guys on [ATP](https://atp.fm/episodes/88) think it's more complicated.

(Note: _Mike the MacBook_)
