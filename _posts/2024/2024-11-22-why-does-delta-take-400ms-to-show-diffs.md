---
title: "Why Does Delta Take 400ms to Show Diffs?"
tags: debugging
---

The other day I saw a link to [`delta`](https://github.com/dandavison/delta), which is a tool that integrates with git to add both add better diff highlighting (similar to what you'd see in the GitHub/GitLab web UI) and syntax highlighting. I decided to give it a try. There's even a note in the [JJ docs](https://martinvonz.github.io/jj/latest/config/#processing-contents-to-be-paged) on how to set it up (since obviously I'm [not going to be using git](/2024/04/01/its-not-me-its-git/)):

```toml
[ui]
pager = "delta"
diff.format = "git"
```

I tried it and the diff looks nice. However I also noticed that it was _really_ slow. On my [dotfiles repo](https://github.com/willhbr/dotfiles) it took just over 400ms to diff a commit. That's not a big repo in any measure: it doesn't have many files, the files are small, and there aren't many commits. Showing the diff without `delta` took less than 100ms. Even more puzzling was that setting `ui.pager = "delta"` also made `jj log` take a similar amount of time—it jumped from ~80ms to ~430ms. The output of `jj log` doesn't even show any diffs (by default), so what's my computer doing for those 400 milliseconds?

Initially I was a bit puzzled as to why `log` was also slowing down, but a look at the code reveals that JJ will [always call out to the pager program][log.rs], it's just that `less` will check the screen height and do a transparent pass-through if the output is smaller than the height of the screen.

[log.rs]: https://github.com/martinvonz/jj/blob/ffe5519fd0f2c63a378239fb81b5cbffab06f3e4/cli/src/commands/log.rs#L175

In order to get a few more data points, I tried `jj log | delta`, which should result in the same amount of work and thus take the same amount of time. This was not the case—piping the log output into `delta` didn't slow things down at all, it was about the same speed as using `less`.

At this point I was suitably puzzled. I knew there _could_ be some difference in how the data is passed between processes with a shell pipe versus a subprocess, but I didn't know enough to really dig any further. Also the intended use of `delta` is to be called as a pager by a version control system, so it would be very odd if this way of using it was much slower than other non-standard uses. Instead I asked the resident performance expert and flame graph enthusiast [Mark](https://www.markhansen.co.nz), who is always easy to nerd-snipe into solving a problem.

His first suggestion was to see if we could spot something in `strace`, but then neither of us wanted to wade through the thousands of lines of output that it produced. The next suggestion was to use [`samply`](https://github.com/mstange/samply). A quick `cargo install` later and I was able to grab a trace just by running:

```
$ samply record jj log
@  r Will Richardson 1 hour ago b
│  (no description set)
◆  k Will Richardson 1 month ago main@origin 9
│  Add shortcut to copy last command output
~
Local server listening at http://127.0.0.1:3000
Press Ctrl+C to stop.
```

`samply` grabs the trace and then starts a local webserver to either download it or open it in the [Firefox profiler](https://profiler.firefox.com). It's mildly inconvenient that it runs the server on `127.0.0.1` instead of listening on all interfaces, so I had to setup a port forward as I develop on a remote machine. Thankfully this [has been fixed](https://github.com/mstange/samply/pull/234) with the addition of a `--address` flag.

The trace showed the `jj` and `delta` processes, as well as a thread in the `delta` process called "find_calling_pr"—which did about 400ms of work while the main `delta` thread did nothing. A quick search of the `delta` code [reveals this][find_calling_process]:

[find_calling_process]: https://github.com/dandavison/delta/blob/959471392d5aa0289f979c8898260e0f133d9ae7/src/utils/process.rs#L50

```rust
pub fn start_determining_calling_process_in_thread() {
    // The handle is neither kept nor returned nor joined but dropped, so the main
    // thread can exit early if it does not need to know its parent process.
    std::thread::Builder::new()
        .name("find_calling_process".into())
        .spawn(move || {
            let calling_process = determine_calling_process();

            let (caller_mutex, determine_done) = &**CALLER;

            let mut caller = caller_mutex.lock().unwrap();
            *caller = calling_process;
            determine_done.notify_all();
        })
        .unwrap();
}
```

Ok so we're trying to find something about the parent process. A look back at the trace shows we're then calling into [`retrieve_all_new_process_info`](https://docs.rs/sysinfo/0.29.11/src/sysinfo/linux/process.rs.html#363) in the `sysinfo` crate. Why are we spending so much time getting process information?

I read a bit of the `determine_calling_process` function that is being called, and the gist is that it tries to find the parent process in order to work out if `delta` has been invoked by `git`, `rg`, `ack`, `sift`, or some other tool. It doesn't just look at one process though, it uses some heuristics to try and find the calling process. If I'm reading the code right, this can end up fetching information for every running process[^process-count]. Since I was running `delta` via JJ it would never find a process name it recognised, so I would hit the worst case every time.

[^process-count]: On my machine while I was testing this, `ps -ef | cl -l` showed that I had about 1500 processes running.

At this point I went to look at what this process information is actually used for. Eventually a `CallingProcess` enum is created that contains information about either a git subcommand, or one of the various grep-like tools. The only place I can see this information being used is [`paths_in_input_are_relative_to_cwd()`][paths_in_input_are_relative_to_cwd], which does exactly what it says: determines if the paths are relative to the current working directory.

[paths_in_input_are_relative_to_cwd]: https://github.com/dandavison/delta/blob/959471392d5aa0289f979c8898260e0f133d9ae7/src/utils/process.rs#L25

```rust
impl CallingProcess {
    pub fn paths_in_input_are_relative_to_cwd(&self) -> bool {
        match self {
            CallingProcess::GitDiff(cmd) if cmd.long_options.contains("--relative") => true,
            CallingProcess::GitShow(cmd, _) if cmd.long_options.contains("--relative") => true,
            CallingProcess::GitLog(cmd) if cmd.long_options.contains("--relative") => true,
            CallingProcess::GitBlame(_)
            | CallingProcess::GitGrep(_)
            | CallingProcess::OtherGrep => true,
            _ => false,
        }
    }
}
```

So if it's called by a grep-like tool, the paths are relative. If the git command received the `--relative` flag, then it's relative. If it's something else, then it's absolute.

The solution to my slow `delta` invocation seems to be that it needs to know about processes named `jj`, so it doesn't waste time scanning for a `git` process that doesn't exist. I did however try this again on a different computer with much less work going on (~300 processes) and `delta` was only ~100ms slower than using `less`, which is just fast enough that it's not too noticeable.
