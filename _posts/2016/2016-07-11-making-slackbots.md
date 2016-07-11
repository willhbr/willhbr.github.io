---
title: Making Slackbots
date: 2016-7-11
layout: post
---

This semester, for my group project I made a slackbot to select people for code reviews and generally be a nuisance in our slack group. I split it out into a [gem](https://github.com/javanut13/realtime-slackbot) which could be used to integrate easily with the slack real time messaging API. All it really does is provide a wrapper around the websocket connection and calls methods according to the type of the update received (typically the only update you care about is 'message' so there will only be one method). It may just be a wrapper, but it is *my* wrapper and I'm very pleased at how easy writing and maintaining the SENG group bot is.

Fast forward a month or two, my flatmate Logan and I entered the MYOB 'try and think of a good idea we can steal later' competition. Each team has five days to build something that could improve, work with, or build on something that MYOB already offers. We quickly settled on the idea of a slackbot that would help you timesheet by reminding you regularly to tell it what you're doing - so that at the end of the day you have a reliable record of what you spent your time on that you can use to make an accurate timesheet.

Initially we were set on writing whatever we made in Swift (because of just how cool it is) but because it is a massive pain to get the correct nightly build to be able to use third party libraries, and installing it on Arch Linux is not trivial. We soon decided that we would take the more pragmatic approach and use Ruby, along with my realtime-slackbot gem (after making some changes to make it more usable by other people).

It's important to understand that there is a significant difference between a Slack app and a Slack integration - apps are distributed through Slack's marketplace and typically can be added in one or two clicks via an 'Add to Slack' button. Custon integrations are specific to a single team and are added by creating a new integration on the team config page, then using the token from there when starting the bot.

My previous bots had all been custom integrations - specifically tailored to my team and hosted on my Raspberry Pi at home. What Logan and I were setting out to do was make a proper Slack app that could be installed and used by anyone, in any team. This meant implementing the OAuth 'flow' to get a token that could be used in a certain team. The sequence of events goes something like:

1. The user clicks the Add to Slack button on your website
2. They select one of their teams to add the app to
3. Slack sends a one-time code to your server
4. You use this code to get a permenant auth token for the team
5. You send this token to the RTM.start method of the API to get a websocket URL
6. A new bot instance connects to this URL and starts interacting with the members of the team.

My gem was built to only handle the last two steps of this sequence. So we obviously had to implement a webserver that could handle the callback from slack, and host somewhere for the Add to Slack button to live. We ended up using Sinatra for this, as it is very well supported and can be used in a single file - which is great when you just want to serve two mostly static pages.

Once we could handle the web side of things, we had to actually create new bots when a new user added the app to their team. This is where the real 'fun' begins. We aimed to have the web server doing its own thing (managed by Rack) and have a separate process that would manage the bots and create new ones on demand from the web server.

There are many different ways that you could communicate between these two processes; you could have a queue that is polled by the bot manager every few minutes, stored on a file or database. A file is a bit janky and a database overkill. You could implement some UDP or TCP socket connection to communicate, probably a lot of work and prone to encoding/ decoding errors if you don't do it well. Thankfully Logan found fairly quickly that Redis can act as a message-passing system - any number of processes can subscribe to a channel, and any message on that channel will be sent to all subscribers. Perfect.

This quickly made Redis one of my favorite new toys - it was so easy to persist (or at least *kind of* persist) data as well as co-ordinating multiple processes. Our web server would simply send a message to the bot manager with a new token, the bot manager would save this token in Redis for later and start a new bot. The bot would then act just like a custom integration, as all it needs is the token and it will work out the rest.

So, quick recap: the Sinatra server responds to the authentication endpoints for slack, and the bot server subscribes to a redis channel which lets it know when to connect a new bot. Each new bot is run in a new thread by the bot server.

While I think this is a fairly decent effort for a 5-day project, especially given that the actual bot that would remind about time sheeting hadn't really been started. Nothing built this hastily is without bugs, unhandled edge cases, or any robustness that you would hope for a web service.

---

[Elixir](http://elixir-lang.org) is a programming language that runs on the BEAM VM (the home of [Erlang](http://erlang.org)). Elixir is to BEAM what [Kotlin](http://kotlinlang.org) or [Scala](http://scala-lang.org) is to the JVM - an alternative language that runs in the same environment and is interoperable with the main language for the VM. If you look a bit further into Elixir, it is actually mostly just a pile of macros that somehow create a useable language. Like Erlang, Elixir is a functional language with no mutatable data - every value is constant. The only way to change the state of the application is to run a separate process and use message passing to manipulate the state.

The ability to run many processes easily in parallel is what makes Elixir/ Erlang interesting. Each process is independent of all others, so if something breaks in one process nothing else is effected. By splitting an application into different processes (which is necessary anyway because everything is immutable) you can create a tree structure of processes. Each leaf can crash and be restarted by its parent, or the parent can choose to send the crash further up the chain by crashing itself. At some point in this process there is a supervisor that restarts the crashed processes, keeping the application alive.

Going back to my SENG slackbot, I wanted it to be able to remind everyone of the merge requests that they still had to review every day at a certain time. Initially I reworked my Ruby bot to post something to a given channel each day, however it turned out to be a bit buggy and would cause the bot to crash - mainly because of my lazy programming. However for something that I didn't really want to worry about, it was a pain.

It is probably quite obvious where this is going. I decided to rewrite the bot in Elixir, using an existing [Slack module](https://github.com/BlakeWilliams/Elixir-Slack). The [Quantum](https://github.com/c-rack/quantum-elixir) library also simplified the posting at a certain time of day by adding a cron-like job scheduler that just runs in its own process in the background. The main advantage of using Elixir here is that by making a simple supervisor to start each process in the application, any part that crashes will be automatically restarted. There was at one point a bug where any message received by the bot that didn't have a user ID (eg a deleted or edited message) would crash it. But of course this crash was inconsequential as the supervisor would just create a new process running the bot, and reconnect. I left this version running for about a week before getting round to fixing it as it wasn't really a huge problem - unlike any problems with my Ruby bot that would be very unhappy about any errors.

Another bonus of Erlang and Elixir being so oriented around processes, is that the processes don't have to be running on the same computer. Completely by magic, an application can be split up without having to re-write a whole load of code. Although this comes at a cost of writing code in the process-oriented style.

So I have a new favorite toy for writing server-side services. What really makes me enthusiastic about Elixir is that every part of the Ruby slackbot system that Logan and I made, could be implemented in a single Elixir application. The web application would no doubt use Phoenix, and pass off requests to create new bots to a bot manager process, which would create a new process for the bot. If we somehow managed to get an influx of users the bots could be split off onto a different server entirely. Redis would not be needed for communicating between the processes, and a stateful Elixir process could be used to store key/ value pairs, and easily persisted to a file using the built in Erlang serialization (which works really well because everything is just a combination of lists, tuples, and maps).

The most important thing that I've learnt from this is that while you can do almost anything in your language of choice (see: Java developers), the overhead of twisting it to fit the problem might outweigh the cost of learning a new language that is better suited. Either that or I'm too easily excited by new programming languages and a mediocre Ruby developer.