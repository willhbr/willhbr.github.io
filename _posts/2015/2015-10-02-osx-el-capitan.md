---
title: "OS X El Capitan"
image: /images/2015/el-cap.jpg
---

![El Capitan default wallpaper](/images/2015/el-cap.jpg)

On Thursday I bit the bullet and trashed my home data cap by upgrading to El Capitan. The 6 GB download crawled down at a snails pace overnight, but when I got up in the morning my MacBook was waiting for me with a new version of OS X.

At first look, El Capitan appears no different to Yosemite - it has the same window styles, menu bar, and login screen. For me, the most notable change is the new Mission Control layout. Instead of showing the bar of desktops along the top with a thumbnail, there is just a thin list of labels. When you move your mouse close to the top of the screen this will expand into a set of thumbnails. Once it has been expanded it will remain so until you exit Mission Control. Much like the dock, I find it to always appear when I want it to, and as a spaces 'Power User' I have not been frustrated by this at all.

Along with the new Mission Control there is of course split view. This only works on applications that can be freely resized - MailBox will not split, but editors, terminals and browsers all split just fine. Windows can either by split by dragging the window into an already full screen application in Mission Control, or by clicking and holding on the green fullscreen button before dragging the window to either the right or the left - once that window is split you can select the window that will occupy the other half of the screen.

The whole splitting process seems a bit janky - press and hold doesn't feel quite right on a trackpad (My guess is that it's designed to be Force Touched) and once two windows are split together, you can't substitute one with another application without exiting the split and then re-adding the new app. Neither Apple's nor Microsoft's can be said to be _better_, it entirely depends on how the user 'maps' its functions in their mind as to which will be more useful for them.

When I set out to do some work, I was glad to see that Ruby and related gems, Python, Brew, Java, MySQL and Postgres all made the transition without any immediately visible issues. This is usually the factor that makes me wait before upgrading. My development setup wasn't completely untouched though - it appears that the way fonts (or at least monospaced fonts) are rendered has changed, so that the text appears to be thinner in most cases. In IntelliJ it looks like someone turned of LCD font smoothing off (it is still turned on in Preferences). In both TextMate and the Terminal it is better looking. I'm yet to find out if this is a system-wide change that effects all fonts or just my editor font of choice [Anonymous Pro](https://www.marksimonson.com/fonts/view/anonymous-pro) behaving badly.

Rummaging through the preferences, I only found one notable change - it is now possible to auto-hide the menu bar (General -> Automatically show and hide the Menu Bar). After turning it on for two seconds, I am of the opinion that this is an awful feature that no one should use.

El Capitan is definitely worth the upgrade for the sake of being up-to-date and brings some nice features to make the download worth the wait.

If you want a more Siracusian review, [Ars Technica](https://arstechnica.com/apple/2015/09/os-x-10-11-el-capitan-the-ars-technica-review/) has picked up John's baton to prove a more in-depth look at the latest iteration of OS X.
