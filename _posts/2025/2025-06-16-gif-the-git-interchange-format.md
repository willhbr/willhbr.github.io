---
title: "GIF: The Git Interchange Format"
image: /images/2025/git-interchange.gif
tags: projects
---

We all know that it's hard to share git repositories. Sure, you could upload to a site like GitHub or Codeberg, but that requires both you and whoever you want to share with to make an account. Wouldn't it be great if you could share directly in your messaging app of choice? Just like you can share pictures and videos?

Well, the obvious solution is to encode a git repo into an image, so you can share it however you like. This is why I made GIF: The Git Interchange Format. A whole git repo—with history—can be crammed into an animated GIF. Here's the repo for the project itself, contained within a 153px square image with four frames:

![animated GIF of seemingly random noise](/images/2025/git-interchange.gif)

Apologies for the annoying looping GIF, it's a risk of the subject matter.
{:class="caption"}

It's also available in a more traditional format [on Codeberg](https://codeberg.org/willhbr/git-interchange-format). Clone the repo from there, and then extract the repo from the image:

```console
$ jj git clone https://codeberg.org/willhbr/git-interchange-format.git
$ cd git-interchange-format
$ curl -O https://willhbr.net/images/2025/git-interchange.gif
$ cargo run -- decode /tmp/git-interchange git-interchange.gif
```

## How it works

Lossless images are just 2d byte arrays, and so you can dump text or whatever into them. GIFs are a little weird in that they indirect colours through a palette, but we can basically ignore that by assuming there are 256 colours in the palette. Maybe restricting the size of the palette would allow us to compress the image a bit, but that seems like a bunch of effort.

GIF does support frames with different sizes (I think as a further compression technique, to allow partial updates when animating) but again that seemed like unnecessary complexity. I opted instead to make a each frame big enough to contain the largest file in the repo, but fill up each frame with multiple smaller files when possible.

I used [`rmp_serde`][rmp_serde] to encode my data in [MessagePack](https://msgpack.org) (my fave data serialisation format). `rmp_serde` is great because it supports more complex structures like Rust enums, so each entry in the GIF can be one of:

[rmp_serde]: https://docs.rs/rmp-serde/latest/rmp_serde/

```rust
#[derive(Debug, Serialize, Deserialize)]
enum GIFEntry {
  Commit(repo::Commit),
  Modify(String, Vec<u8>),
  Delete(String),
}
```

This means I don't have to keep track of what type of message I'm expecting, instead I just decode it and `match` on the result. What [it's actually doing][serde-enum] is wrapping the enum data in another map, with a key of the name of the enum case that the data corresponds to.

[serde-enum]: https://serde.rs/enum-representations.html

Each frame will contain one or more `GIFEntry`. I can just keep parsing entries from the frame buffer, but there will be some padding at the end that I want to ignore. I thought about prefixing each frame with the number of entries (or number of bytes) that should be read, but that would mean jumping back and forward in the serialisation, which is always a pain.

Instead I did something much more silly, I used the duration of each frame to indicate how many entries there were. It has the side benefit that a human looking at the GIF gets more time to mentally decode the messagepack from a frame with more entries in it.

I used [JJ](https://jj-vcs.github.io/jj/latest/) to read from the git repo, for the reasons I [explained before](http://brett:4000/2025/04/26/writing-in-crystal-rewriting-in-rust/). The template and revset languages make this much easier than dealing with git.

To make things simpler, I just read the entire repo into memory (the full file contents of every file in every revision), which meant I could easily work out the size of the GIF by looking at all the files. A better implementation would allow splitting files across multiple frames, and build the GIF as it traversed the repository.

Another simplification was storing the entire file contents for each commit, rather than a diff from the parent. Obviously this makes the end file much larger, but makes the implementation much simpler.

Decoding is just encoding backwards, and as is tradition you only realise you have bugs in your encoder when you try and write a decoder. Eventually I built up a list of commits, each with the contents of the changed files in that revision (or a marker that the file should be deleted).

Each commit has the list of parent commit IDs, so I just needed to do a [topographical sort](https://en.wikipedia.org/wiki/Topological_sorting) to get a list of commits in the order that they could be inserted into a new repository. Once they're in order, I can just run `jj new` with all the parent IDs and commit message, then write out the file contents which will get picked up automatically.

The original idea for this project was to make a web UI that could load git repos from images, allowing you to use any image hosting service as a git forge, with some inspiration from [other naughty usages of images to store arbitrary data](https://purplesyringa.moe/blog/webp-the-webpage-compression-format/). GIF is of course a terrible choice for this, since more often than not it's actually translated into an MP4 video for better playback, so you'd have to add some error correction or ensure your image is bit-for-bit identical.
