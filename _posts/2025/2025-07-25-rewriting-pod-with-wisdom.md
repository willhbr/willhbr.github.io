---
title: "Rewriting Pod With Two Years of Wisdom"
tags: podman projects
---

In 2023 I got into running things in containers after a getting over my [fear of them][scary-containers]. I quickly realised that running podman commands manually was tedious, and after a few different approaches I made [pod][pod], a poorly-named wrapper around the podman CLI that lets you define how to build an image and run a container in a config file, then run containers with `pod run` instead of some long `podman` command.

[scary-containers]: /2023/06/08/overcoming-a-fear-of-containerisation/

Since then I’ve used it in basically every project I’ve written, and I’ve been super happy with it. There wasn't really any good reason to rewrite it, other than the fact I want to learn more Rust and this is a great excuse, and I'd been meaning to do a substantial refactor and what better way to refactor than to use a different language?

The refactor is necessary as I didn’t really design pod, I just built things that seemed useful at the time. My initial goal was for all my development to be able to happen within containers. This ended up being more hassle than it was worth, and meant that I added a bunch of features that I ended up not using.

There are `pod repl` and `script` that used system-wide container configs to run interactive shells and scripts without writing a whole `pods.yaml` config file. I used this a bit but it ended up just being easier to keep some stuff installed on the host system anyway—especially if I wanted things like editor integration for auto-formatting with `crystal tool format`.[^containers]

[^containers]: The balance that I have struck which seems to work is that I have stuff installed for editor integration, scripting, and to work on libraries. If a project is going to run as a server or needs extra dependencies, I'll put it in a container with Pod.

`pod enter` was another feature to be able to start project-specific shells inside containers, with a separate config section. After implementing this I realised that the only thing I actually wanted was a way to start a regular shell in one of the containers already defined in the config file, all the other options were just a hassle to configure.

So much of the Crystal implementation was like this. The initial version of the code to handle updates was hacked in from some code from other project. It just made the changes without telling you in advance, and I realised I wanted to see what it was going to change first so I wrote some code that would print the difference between the two containers. That was separate from the code that did the updating, which didn’t make sense so eventually I restructured it so that the update would just enact what the diff had already worked out, but it wasn’t particularly neat.

Later on I realised it would be useful to check if a container started up correctly by waiting to make sure it continued running a few seconds after starting it, which made the update code more complicated. Then I wanted to show the logs from failed containers so I knew what I’d messed up, so there’s another layer of complexity added on top.

By far the largest hinderance to me getting the rewrite off the ground was the fact that despite the mess, the existing implementation worked pretty well. I tried multiple times to build up enough momentum so it made more sense to work on the new implementation instead of adding stuff to the old one, but since the Crystal implementation worked and I was using it regularly, I'd just go in and make little tweaks here and there. This would further demoralise me from the rewrite, since every little fix and quality of life improvement was more work I would have to repeat.

Eventually I got it over the line where I could replace the `pod` binary with the Rust implementation that could handle `build` and `run`, but delegate `diff` and `update` back to the Crystal implementation (by running a subprocess). This motivated me to make sure those commands worked and find any bugs by actually using it.

The biggest improvement in the rewrite was that in addition to refactoring, I now know a _lot_ more about podman today than I did in 2023. Back then I was reasonably comfortable building images, running containers, and the common flags involved there, but I didn't know much about the commands to get information out of podman.

Initially the way I would check whether the arguments passed to a container had changed was using a custom label to store the hash of the create command, and comparing that to the hash of the command I _would_ run based on the config file. It wasn't until like halfway through the implementation of the update logic that I found out about `podman container inspect` which would give me the exact command used to create the container, allowing me to actually just compare two lists of arguments.

The original `update` implementation was originally written to compare and update a single container at a time, which I basically just ran concurrently for all containers. Instead, I now gather all the information I need then build a series of diffs that will be used to update. For example, back in 2023 I didn't realise that I could pull multiple images in one command, so I would run multiple `podman pull` commands at once, but podman doesn't really like having too many concurrent operations and would fail in weird ways. I had to limit the concurrency here to only pull 4 at a time. Now I just run one command that pulls everything I need, then a second command to get all the container information.

Since async is a pain in Rust, I ended up just doing everything synchronously to start with and running a different thread for each remote host I was connecting to (this is usually 1-3, a perfectly reasonable number of threads). There are still a few places that I could optimise by running two podman commands concurrently which would speed things while working on slow remote servers, but funnily enough the actual update speed as about as good across the two versions—at least in some rudimentary testing—just by being smarter about what commands I run.

I think once I'm happy with the output format and general code structure, I'll do some analysis on how much time is spent waiting for podman commands and whether running two in parallel will speed things up significantly to make the complexity worth it.

Another feature I didn't know about in 2023[^podman-version] was `podman image scp`, which allows you to directly copy an image from one machine to another without running a registry. When I wanted to run something on another machine, I would have to push the image to a local registry, then pull it from the other machine. Now that I know about `image scp`, I can stop running a registry and get rid of all the code for pushing images.

[^podman-version]: I don't know if some of these things are due to the old podman version I was running back then.

Something that I've managed to do much better by just understanding how podman works is image metadata. This was previously an afterthought, I was intending to just match the image ID to the tag, but it never worked well since I didn't realise I needed to look at `RepoTags` as well as `NamesHistory` (the fields are inconsistent between `image ls` and `image inspect`). I now make a list of all the image names and IDs that are involved in the update, call `image inspect` to get all the information, then search through that looking at all the names to always be able to show the right image tag and build time in the diff.

My biggest problem with Rust was loading the config. If you look at basically any of my projects, whether it's [endash](https://codeberg.org/willhbr/endash) or [my website](https://github.com/willhbr/willhbr.github.io) you'll see the pod config is a YAML file. [Dunking on YAML][dunk-yaml] is a popular pastime for infrastructure-minded folk, and for good reason: it does a lot of things poorly.

[dunk-yaml]: https://www.arp242.net/yaml-config.html

However, I could write a whole separate blog post on why YAML is actually great, and the other contenders—JSON and TOML—have enough shortcomings of their own that make me just want to use YAML. However, the actual problem with YAML is that there isn't a good Rust library for it. [`serde_yaml`](https://docs.rs/serde_yaml/latest/serde_yaml/) is no longer maintained, and although I'm happy with using deprecated libraries, it doesn't support features like [anchors and references](https://blog.daemonl.com/2016/02/yaml.html) from my quick testing, which negates a big reason why I like YAML in the first place.

Eventually I decided to sidestep the whole problem by making pod be able to load a config file in any format by first running an external program that would translate the config into a standard JSON format. I then made [`rfmt`](https://codeberg.org/willhbr/rfmt) which uses the Crystal YAML parser to translate files from YAML to JSON.

This does mean that you can take any config language ([RCL](http://rcl-lang.org), [PKL](https://pkl-lang.org/), [HCL](https://hcl.readthedocs.io/en/latest/) or even [Python](https://www.python.org) or [Starlark](https://bazel.build/rules/language)) and define in your config how to run a program that turns it into JSON.

The disadvantage of this approach is that the translation program doesn't know the structure of the config file it needs to output, and so the validation happens on the intermediate JSON, making error reporting much worse. I could export a JSON schema or some other structure that a tool could use to validate its input before passing it back to pod, but I'd really just like to be able to write a YAML file and parse it natively.

I've got to the stage with Rust that I'm not banging my head against the wall constantly, and I'm reasonably productive. This is still helped by a liberal application of `.clone()` whenever resolving some ownership complaint gets tedious.

The challenges are similar to [last time][ppp]. I don't have an intuition for when I should have `&Vec<T>` versus `Vec<&T>`, and then things have got even more confusing after learning about `&[T]`. Running `cargo clippy` was really useful to point out some mistakes here, as well as the compiler error messages recommending sprinkling `.as_ref()` and `.as_deref()` around the place to fix problems. I do sometimes wish for a `--yolo` mode that would just make the suggested edits directly into my code.

[impl-trait]: https://doc.rust-lang.org/book/ch10-02-traits.html#returning-types-that-implement-traits

New in this project was having to actually think about error handling. In Crystal I just made an `Exception` type that would optionally include some extra information to make the message a bit nice (the full command that failed or container logs) and threw it whenever anything didn't work. In the main method I caught that error and printed it. In Rust I could have just made every failure `panic!`, but that just feels dirty. I wanted to actually have the option of printing a nice error message or recovering certain failures.

I got some [good pointers][errors-1] [on mastodon][errors-2] on how to handle `Error` types without making a complete mess. [This article][errors-sushi] is excellent, and I think you could really boil it down to using [`thiserror`](https://lib.rs/crates/thiserror) (or doing it manually) where you might care about recovering the error, and [`anyhow`](https://crates.io/crates/anyhow) everywhere else.

[errors-1]: https://mastodon.decentralised.social/@wezm/114823527975681863
[errors-2]: https://fosstodon.org/@ololduck/114823257250632119
[errors-sushi]: https://burntsushi.net/rust-error-handling/

What this actually meant was that in the common code that was used by `diff` and `update`—where one part might fail but I'll want to report it and continue with the rest—I created my own errors types. Everywhere else I used `anyhow` and reported the failure back to the user basically unchanged. The error handling is still in-progress, with a fair few edge-cases still just `panic!`-ing instead of doing something sensible.

I'm still in two minds about handling errors as values, if you want to do it "right" then there's a lot of boilerplate to translate or wrap each error that is return into your own type (`thiserror` helps by generating most of this). On the other hand, if you actually want to handle exceptions raised in other languages, the `try`/`catch` boilerplate is even more verbose. Exceptions are convenient for the reality of most software[^clis] where an unexpected state just means stopping the whole program.

[^clis]: Well, at least command-line tools like this.

The error handling syntax in Swift is probably still my favourite, with the `try`, `try?` and `try!` keywords giving some shorthands for how a failure should be handled. Maybe there's an alternate syntax that simplifies the handling of errors as values with some transformation?

```swift
let result = try getResult() catch { error in
  throw translateErrorValue(error)
}
```

This can basically be done with `match` already:

```rust
let result = match get_result() {
  Ok(r) => r,
  Err(error) => {
    return Err(translateErrorValue(error));
  }
};
```

It's also not too dissimilar to tacking `map_err` onto the end, but I like having _some_ syntax that will visually break up the code to make it clear that _this_ bit might fail and _that_ bit is the code for handling it, which is [something I've written a bit about before in the context of Go and Java](/2023/07/09/limited-languages-foster-obtuse-apis/).

The flip side of this is that it didn't take long to get a handle on the syntax (although I constantly put the lifetime specifier in the wrong place in `impl` blocks), even if the "use `match` for everything" approach is very wordy, and has more terse alternatives, it gets the job done.

I've really enjoyed learning and writing Rust for pod and [PPP][ppp]. Using a more grown-up language has its perks (`cargo clippy` is awesome!) and defining more precise types with lifetimes is a nice change of pace. The downsides remain the same for me, having to rely on third-party crates for what I consider simple functionality (parsing some YAML, finding the path of the home folder) is frustrating, and the complexity of `async`/`await` will probably push me back towards Crystal for web servers and projects that I know will be IO-heavy.

[ppp]: /2025/04/26/writing-in-crystal-rewriting-in-rust/

Pod is available [on Codeberg][pod], I'm using it for my development and updating my homelab, but it's definitely got sharp edges.

[pod]: https://codeberg.org/willhbr/pod
