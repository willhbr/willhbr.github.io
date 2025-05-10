---
title: "Endash, a Lightweight Container Dashboard"
tags: projects homelab podman
image: /images/2025/endash.webp
---

In my [last post](/2025/03/09/a-slim-home-server-with-alpine-linux/) I mentioned my container dashboard, which I had been using as the main way to access the exposed ports of the various containers that I run on my home computers. I've just [published the source][endash] so you can run it yourself, if it's the kind of thing you're interested in.

[endash]: https://codeberg.org/willhbr/endash

The project is called [endash][endash], and is the successor to a similar but less useful project that I abandoned called emdash[^emdash]. Maybe the next version will be called "hyphen".

[^emdash]: This was before I'd [started using containers everywhere](/2023/06/08/overcoming-a-fear-of-containerisation/) and relied on my own job management thing that was really finicky. Each job would have to make an RPC call to register with the dashboard and then stream their logs back to emdash. Having everything managed by containers and using podman-remote makes this infinitely easier.

It serves two purposes: exposing a simple web interface that shows the state of each container with some metadata and links, as well as acting as a [Prometheus service discovery][prometheus-sd] endpoint to tell Prometheus to fetch metrics for containers dynamically as they start and stop.

[prometheus-sd]: https://prometheus.io/docs/prometheus/latest/http_sd/

There are plenty of projects like this, I think the most well-known one is [Portainer](https://www.portainer.io). There isn't any particular reason that I decided to write my own apart from only wanting a few features, as well as just wanting to do things myself.

I'd already written a lot of code to interact with Podman while making [pod][pod], so I had a bit of a head start. This code is now in a [shared library](https://codeberg.org/willhbr/podman-cr) for use in both projects.

[pod]: https://pod.willhbr.net

So what does endash actually do?

It's just one screen that shows a list of containers:

![screenshot of endash showing a list of containers, some metadata for each one, and a few buttons next to each](/images/2025/endash.webp){:loading="lazy"}

These containers are fetched using podman-remote and aggregated into one list. It exposes a web UI to view the containers (ok it returns the logs as plain text which your browser will render), and adds a link to visit any port exposed by the container. In the screenshot above you can see that `podman-exporter` has host port 36797 mapped to container port 9882.

Other containers—like the endash container—have podman labels defined to add custom named links instead of just showing the port numbers. This way I can get quickly to certain pages, rather than just going to the root. This integrates with [pod][pod] where it's easy to define labels with complex JSON data on your containers—check out the [repo][endash] for examples of how this is used.

I did this purposefully to integrate with my [status page library](https://codeberg.org/willhbr/status_page) for Crystal web servers. It serves a simple web UI on `/status` that shows information about the running program. By default this includes things like uptime, logs, and the program config, but I have also added interceptors to show HTTP request information.

This is really useful for checking the progress of a long-running server without having access to a terminal to run `podman logs`. A lot of this was built while I was making my ADS-B data collector to [plot the flight paths of helicopters along the Sydney beaches][helicopters]. At any point I could just open endash, click the status button, and see how it was progressing.

[helicopters]: /2023/07/29/helicopter-tracking-for-safer-drone-flights/

Even during development I'll use endash to open the web UI of my project to avoid having to remember or type in the appropriate port number. I'll run the container for whatever project, then swap to my browser and visit `http://endash` to see the newly-started container right there at the top.

Recently I decided to live dangerously[^not-the-best-idea] and add buttons to stop and restart a container—that's what the basketball emoji is. This has come in handy on a few occasions when I've realised that something isn't working right, and I'm able to give it a kick by restarting the container right from within endash.

[^not-the-best-idea]: It's not the best idea to have buttons that change the state of "production" on an unauthenticated web UI, but I'm accepting that risk for myself.

I'm aware that I could have just hosted an existing project, which would have given me more features and saved a lot of time. But endash is mine, it does everything just the way I like it, and it fits into how I want things to work. There's nothing quite like it. I'm free to pointlessly optimise the size of the HTML, tack on any weird feature I want, and ensure that it works with podman first and foremost.

Endash has been running at home since 2023, it's the status dashboard that I mentioned [while writing about my Prometheus setup](/2023/07/16/simple-home-server-monitoring-with-prometheus-in-podman/), the reason I made the [HTTP router](/2024/12/06/http-router-for-crystal/) library.

Go and make a tool for yourself, maybe it'll be useful. Or [use mine if you'd like][endash].
