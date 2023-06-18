---
title: "Geode: More Functions for Crystal"
---

The only language I use for personal projects is [Crystal](https://crystal-lang.org). It is as easy to write as a dynamically typed language - so I don't have to waste time telling the type system what I mean, but it has full type checking - so I also don't waste time on easily preventable mistakes.

> Crystal being the best programming language for side projects is a topic for another blog post. There's a lot to say about how perfect it is.

Naturally this means that over the last 6 or so years that I've been using Crystal, I've assembled a messy collection of utility functions and classes that I share between projects.

I've collected some of the best bits into a library: [Geode](https://github.com/willhbr/geode). Features include:

- [A generic circular buffer](https://github.com/willhbr/geode/blob/main/src/geode/circular_buffer.cr)
- [Some helpers to get build metadata](https://github.com/willhbr/geode/blob/main/src/geode/program_info.cr)
- [A more succinct `to_s` implementation for `Time::Span`](https://github.com/willhbr/geode/blob/main/src/geode/time_span.cr)
- [Structured concurrency in the form of a `Spindle`](https://github.com/willhbr/geode/blob/main/src/geode/spindle.cr) (see [this post](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/), based on [this implementation](https://gist.github.com/straight-shoota/4437971943bae7000f03fabf3d814a2f))
- [Some additions to the `Log` module](https://github.com/willhbr/geode/blob/main/src/geode/log.cr)
- [A basic worker pool to limit parallelism of tasks](https://github.com/willhbr/geode/blob/main/src/geode/worker_pool.cr)

More bits will be added as I need them.

> If for some reason you do use this, be aware that I am changing the behaviour of the stdlib, which might cause other things to break in weird and unexpected ways.
