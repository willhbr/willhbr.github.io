---
title: Installing rsnapshot on Synology DS420j
image: /images/2023/ds420j.png
---

I've got a shiny new Synology DS420j, and I'm in the process of re-implementing the wheels of computer suffering that I call my backup system on it. Part of this is setting up `rsnapshot` to create point-in-time snapshots of my backups, so I can rewind back to an old version of my data.

![A marketing image of a Synology DS420j NAS](/images/2023/ds420j.png){: style="max-width:400px"}

There are plenty of instructions on how to setup rsnapshot using [Docker](https://www.docker.com) on the higher-end Synology models, but when you're shopping at the bottom of the barrel you don't have that option. We've got to install rsnapshot directly on the Synology - the most cursed Linux environment ever[^citation].

[^citation]: citation needed.

All the instructions I could find were quite old, and the landscape seems to have changed. Synology have changed their package format, so old packages cannot be installed on newer DSM versions (according to [this German forum post](https://www.synology-forum.de/threads/ebi-easy-bootstrap-installer.68335/post-949587)) which means anything that tells you to install pages from [cphub.net](https://www.cphub.net) probably doesn't work any more. `ipkg` is also [no longer maintained](https://www.beatificabytes.be/use-opkg-instead-of-ipkg-on-synology/) and has been replaced by [Entware](https://github.com/Entware/Entware). Once I knew that, the process was relatively straightforward.

# Preamble

You probably need to enable the `rsync` service, enable `ssh`, etc for this to work. I'm assuming that you've got a Synology already setup that you can SSH into and sync files to from your other computers. If you don't, then you should sort that out and then come back. I'll wait.

# Install Entware

Entware have [detailed installation instructions on GitHub](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS). Remember that the DS420j is `armv8`, check yours with `cat /proc/cpuinfo`.

Once you've yolo-run the various install scripts and added enough backdoors into the device that holds all your most valuable information, you just need to add the scheduled tasks to keep Entware from being removed (take note of this, we'll use this again later for rsnapshot).

# Setup `rsnapshot`

Now we can use `opkg` to install `rsnapshot`:

```shell
$ sudo opkg install rsnapshot
```

And then edit `/opt/etc/rsnapshot.conf` to taste. For example here's mine:

```conf
config_version  1.2

snapshot_root  /volume1/rsnapshot

# Commands
cmd_cp  /bin/cp
cmd_rm  /bin/rm
cmd_rsync  /usr/bin/rsync
cmd_ssh  /usr/bin/ssh
cmd_logger  /usr/bin/logger
cmd_du  /usr/bin/du
cmd_rsnapshot_diff  /opt/bin/rsnapshot-diff

# Backups
retain  daily  28
retain  weekly  26

# Opts
verbose  2
loglevel  3
logfile  /var/log/rsnapshot.log
lockfile  /var/run/rsnapshot.pid

backup  /volume1/Backups  Backups/
```

Now check that the config is valid:

```shell
$ sudo rsnapshot configtest
Syntax OK
```

# Schedule `rsnapshot`

We could use `cron` to schedule our rsnapshot job, but since Synology isn't quite normal Linux, I think it's best to use the built-in GUI rather than install more custom packages.

The task is fairly simple, just click "Create" > "Scheduled Task" > "User-defined script" and setup:

- Task: "rsnapshot daily"
- User: root
- Schedule: every day, probably sometime when you're not likely to be using the Synology. I set mine to run at 2am.
- Task Settings: "run command" should be something like `/opt/bin/rsnapshot daily` (I used the full path Just In Case™ there is `$PATH` weirdness).

Save the task and accept the dialog that tells you you've voided your warrantee.

The task will be skipped if an instance is already running, you can use the Synology UI to start it ad-hoc, and you can easily see the status in the "View Result" screen. Which is a bit more user-friendly than `cron`.

This setup has successfully run on my Synology once (so far). Whether it will continue to work after reboots and software updates remains to be seen.
