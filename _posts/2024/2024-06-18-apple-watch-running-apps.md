---
title: "Apple Watch Running Apps"
---

This year I'm running the Sydney Marathon, and so I've got a lot of running on the cards for the next few months. I've been using an Apple Watch to track my runs since early 2019, first a series 3 and now a series 8. Here's what I'm using to keep track of training and races.

[WorkOutDoors][workoutdoors] is a kitchen-sink-included Apple Watch activity tracker, mostly focussed on running, cycling, and hiking in areas where a map is required. Some Garmin watches have maps built in, which is super useful to make sure you take the right turns on a trail run.

[workoutdoors]: http://www.workoutdoors.net

Often I'll do trail runs with my friend Max[^website-pending], who is always organised enough that I don't need to know where we're going. I bought WorkOutDoors as a backup but then never got around to using, it until a few months ago. It's a bit intimidating, but it's super useful for trail runs where you're not sure of exactly which track you need to be on.

[^website-pending]: Website pending.

Last month I ran [UTA 22](http://uta.utmb.world) in the Blue Mountains just to the west of Sydney. I used WorkOutDoors to not just show a map, but also show the route with elevation and key points of interest (like the aid station) so I knew what to expect as I was running. Perhaps it takes some of the adventure out of the run, but it was useful to know how much of an ascent or descent was coming up. Without it, I would have been trying to guess where I was based on a patchy recollection of the elevation profile.

You need a GPX file to show the route in WorkOutDoors. Some races (like UTA) supply an official one, but if I'm doing a training run the best tool I've found to make one is the [Garmin Connect](http://connect.garmin.com) course planning tool. You don't need a Garmin watch to use it, but you do need to make an account. Once you've made a route by clicking waypoints and adjusting the path-finding, you can download the GPX file.

The "Routes" section of WorkOutDoors has an "Import" button where you can load the GPX file from the iOS Files app. You can then give it a name, send it to the watch, and tell the watch to download the surrounding map tiles. The trick that confused me initially was that you need to go into the settings for WorkOutDoors _on the watch_ and select an active route to have it appear on the map when you start an activity. If you don't do this you'll still get a map, which can be useful, but not as useful as having the real route.

If I'm just doing a run from home—where I don't need a map—I'll track the run using the standard Workouts app on the Apple Watch. It's not perfect, I'd really like the ability to increase the size of certain metrics and make better use of the screen real estate. Currently about 30% of the screen is just empty, and I can't use that space to make the existing metrics more readable, only to add more clutter. It does work reliably and I'm used to reading the tiny numbers.

I'm a bit miffed that the ability to have completely custom metric sets was removed a few years ago. You can't put any metric on any screen, some metrics are restricted to particular pre-defined screens. For example you can't have an altitude graph on the same screen as your pace. That being said, the only screen I really care about is the main one. This is configured to show time, distance, rolling pace, and average pace. The second screen I use exclusively during recovery runs to show the heart rate zone indicator.

The reason I want to see the heart rate indicator is because of another frustrating design decision. You can have pre-defined runs with a target, either time based, distance based, or "custom". I would like to be able to setup a "recovery run" with a time goal and a heart rate alert to catch me if I'm putting in too much effort. However the alerts (including both heart rate and pace) are defined globally for _all_ runs, not a particular flavour, so if I set a heart rate goal I risk forgetting about it and being spammed with alerts when I do my next run. So instead I just scroll to the second screen and glance at the heart rate zone every so often.

"Custom" runs are a welcome addition, as they make interval training much easier. You can set work and rest periods defined either by distance, time, or "open" (you double-tap the screen to advance to the next interval). They have a custom screen with some interval-specific info—but it seems like you can't customise that view at all.

Custom runs are definitely only designed for intervals, however. I wanted to setup a 5K run that included a warmup as part of the workout. This would skip having to fiddle around and swap to a new workout after the warmup, instead I could just go from my warmup straight into the main course. This didn't end up working because the "distance" selector for an interval only goes in 5 metre increments, so I would have had to scroll 1000 times to put in my 5K goal. I just put up with stopping and starting a new workout.

The iOS Fitness (previously "Activity") app is reasonable for viewing information about runs, but the last few updates have sacrificed usability in this area to put more focus on Fitness+—which I have no interest in. For example, it now only shows your latest activity on the main screen (previously it would show multiple) in order to make room for a weekly "trainer tip" video.

Instead I use [HealthFit][healthfit][^no-website], which reads the same HealthKit data, but surfaces much more information. The main view lists all activities with nice big maps. Each activity has graphs for pace, elevation, and heart rate, and a whole host of other stats. Some of this is _available_ in the Fitness app, but not easily accessible.

[^no-website]: Weirdly they don't have a website listed anywhere, only a Facebook page.
[healthfit]: https://apps.apple.com/au/app/healthfit/id1202650514

What the Fitness app doesn't have is nice graphs for keeping track of activity per week, month, or year. I'm currently using the weekly "kilometres run" graph to keep up with my marathon training. This is much more actionable than the trends shown in the Fitness app, which work on a fairly long time frame (previous 3 months compared to the last year) and offer frustratingly obtuse advice—if I start running significantly further, I get told off because my average pace is dropping.

If you're at all serious about running and use an Apple Watch to track your exercise, buying both [WorkOutDoors][workoutdoors] and [HealthFit][healthfit] (about $10 each, HealthFit has an optional subscription for minor features) dramatically improves the experience of using the watch while trail running and visualising the data afterwards.
