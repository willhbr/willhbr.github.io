---
title: "Glory Is an Indeterminate Amount of Bandwidth Away"
tags: opinion
---

On Mastodon I saw [this toot][toot] showing a tangle of interconnected AWS services used to host a Wordpress site. I don't speak AWS so it looks confusing.[^wordpress] One of the replies linked to [this post][the-post], which I'd come across last week. Seeing it twice was clearly a sign to share my thoughts.

[^wordpress]: I did just setup a website on [Wordpress.com](https://wordpress.com) and that seemed to work pretty well.
[toot]: https://ruby.social/@nikitonsky@mastodon.online/112296945482015483
[the-post]: https://thmsmlr.com/cheap-infra

Overall I agree with the message—you can get a really long way with very little computing power. In university I ran a Rails application that collected entries for sports events, and it was hosted on a $5/month VPS that barely broke a sweat. However the post glosses over some aspects of web hosting that I think are worth considering.

The base assumption is that to be solidly in the top 1000 websites, you'll need to be serving about 30TB of compressed HTML per month, which averages out to 11MB/s. That's a lot but not an unfathomable amount. It's only 88Mb/s which is much less than my home internet download speed. Although sadly it is much greater than my meagre 20Mb/s upload speed—so we can't host this on a server in my apartment.

The assumption baked into the 11MB/s number is that all your visitors will come and look at your website in a perfectly uniform distribution throughout the day and throughout the month. There can be no variation due to timezones, days of the week, or days of the month. This is almost certainly not the case for this hypothetical website. If it's an English-first website then the traffic will grow as the US, UK, and Canada are awake, and then drop off as they go to sleep. If you do the maths on a cosine wave, you can see that it's easy to hit a peak of 22MB/s.

Fluctuations between weekdays and weekends will vary much more based on the type of website you're running, but we can pretty safely say that you want to be able to exceed that 22MB/s number.

Of course you could be a victim of your own success—you want to be able to handle traffic spikes. Whether it's a global news event or just a part of people's daily routine, your traffic is driven by your visitors. Is there something that could cause all your visitors for one day to come in the space of an hour? That's almost 300MB/s of traffic you'd have to handle.

We're also making the assumption that visitors will come to the website, download their content promptly, and leave. There are all sorts of things that [can go wrong when downloading a file][download], which might affect the performance of your website. Will a bunch of clients downloading really slowly impact your memory usage? Are there some users with so much data that your database gets locked up executing a huge query when they're around?

[download]: https://fasterthanli.me/articles/downloads-gone-wrong

SQLite is amazing. I think the main reason why I wouldn't pick it for a web server is not performance, but strictness. It does have a [strict mode](https://sqlite.org/stricttables.html) but I'm not sure how much that encompasses. Way back in the day I used to use MySQL for everything (it's what my dad did) and happily learnt how to write MySQL-flavoured queries. For some reason (maybe an internship?) I started using Postgres and got really confused that my queries were failing. They had been working fine in MySQL.

The reason is that Postgres is much more strict than MySQL[^maybe-not], and it would just throw out my nonsense queries. If we have this query:

[^maybe-not]: Well, it was in the configuration that I was using over ten years ago. Maybe I could have set different options, or maybe the defaults are different now. I don't know, I haven't used either in like seven years.

```sql
SELECT first_name, AVG(age), last_name
FROM people
GROUP BY first_name
```

Postgres will fail because you can't select the column `last_name` that's not aggregated or not part of the `GROUP BY`. MySQL will just give you one of the last names in the group.

SQLite takes this to a whole new level, you don't have to specify the types of columns, you can basically coerce any type into any other type. This makes it great for doing weird messed up things with mostly-structured data[^squish], but I wouldn't recommend it for running on a server where it's not too much additional effort to run Postgres alongside your web server.

[^squish]: I got like halfway through making a MacOS app that lets you use a spreadsheet like an SQLite database and made heavy use of the weakly-typed data to deal with arbitrary input.

The post also argues against using "the edge"[^the-edge], basically stating that the added complexity of getting content to the edge isn't worth it for the reduced latency. Obviously this again depends on the type of website you're building, if it's mostly static then keeping an edge cache up-to-date isn't too hard, if it's changing constantly then it's a huge pain.

[^the-edge]: It's all all-time great heading. You know the one.

It's definitely worth squeezing as much out of your monolith before you decide to split it up, even if that means migrating to a faster language (like the author's preferred [Elixir](https://elixir-lang.org)). You might even be able to make some interesting product decisions where you defer some work that could be real-time but is cheaper to do in a batch off-peak.

A quick aside about English-speaking countries, the post says:

> Plop [a server] in Virginia and you can get the English speaking world in under 100ms of latency.

I know we've got different accents down here in the south, but we do mostly speak English in Australia. And we're not within 100ms of network latency from the US east coast, although I understand the generalisation of it being the centre of the English-speaking world.

If you're not sharding your application around the world for latency, you might want to shard it for maintainability. You don't want your 11MB/s of traffic to be dropped on the floor because of a failed OS update on your server. Turning your application into a distributed system increases the complexity dramatically, but also adds so many more ways to operate on it while it's still running. Things like having two redundant servers so that you can slowly move traffic between them when running a deployment, or take one offline to do maintenance or an upgrade. There are plenty of benefits outside of the increased compute capacity of adding more hardware.

One final thing, I know I'm a huge [container nerd][podman] but there are plenty of reasons to containerise your application other than horizontal scaling. I keep everything in containers because I like being able to blow away my entire dev setup and start again from scratch. It's probably easier and to deploy your containerised application on a new server than if you have to go in and manually install the right version of Ruby and all your dependencies. If you've got a bug that only appears in production it's really convenient to be able to run "production" on your local machine, and containers are a great way to do that.

[podman]: /tags/#podman

I think it's important to consider your decisions based on the problem you're trying to solve. You can prematurely optimise your infrastructure just like you can prematurely optimise your code. You can also choose the wrong architecture that makes scaling impossible, just like you can choose the wrong algorithm that is impossible to optimise. The difficult bit is knowing when it's the right time for optimisation or rearchitecture.
