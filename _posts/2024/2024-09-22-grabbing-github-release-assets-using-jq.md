---
title: "Grabbing GitHub Release Assets Using JQ"
tags: tools
---

`JJ` has become enough of a must-have tool that I wanted to have my dotfiles install it automatically. In [`install.sh`][install.sh] I install a handful of utilities via `apt`, but JJ does not have a Debian/Ubuntu package so I have improvised something. It's a little bit of a hack.

[install.sh]: https://codeberg.org/willhbr/dotfiles/src/branch/main/install.sh

You can download prebuilt JJ binaries for most distributions/architectures from the GitHub releases page, which is how I'd typically install it. I used the GitHub API and [`jq`](https://github.com/jqlang/jq) to parse the list of releases and get the download URL for the right architecture, then download, untar, and install the binary.

The API endpoint is:

```
https://api.github.com/repos/jj-vcs/jj/releases
```

The important part of the response looks like this:

```json
{
  "assets": [
    {
      "url": "https://api.github.com/repos/jj-vcs/jj/releases/assets/190411619",
      "id": 190411619,
      "node_id": "RA_kwDOEzi53M4LWXNj",
      "name": "jj-v0.21.0-aarch64-apple-darwin.tar.gz",
      "label": "",
      "uploader": { ... },
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 8907534,
      "download_count": 42,
      "created_at": "2024-09-04T17:23:32Z",
      "updated_at": "2024-09-04T17:23:32Z",
      "browser_download_url": "https://github.com/jj-vcs/jj/releases/download/v0.21.0/jj-v0.21.0-aarch64-apple-darwin.tar.gz"
    },
    ...
  ],
  ...
}
```

I just need to grab the latest release, and from the release get the asset that matches the architecture of the current OS. After some `jq` trial and error, I ended up with:

```
.[0].assets
| .[]
| select(.name | contains("$arch"))
| select(.name | contains("$os"))
| .browser_download_url
```

Just set `$arch` and `$os` to the right values ("x64_64" and "linux" will probably do the trick) and you've got a script that can download the latest release on demand. I [popped this into my install script](https://codeberg.org/willhbr/dotfiles/src/commit/8602f53addbb51e77a27897fef1eba074a826f08/install.sh#L15-L33) so I can keep my install up-to-date and setup new machines quickly.
