---
title: "Backups With Restic"
tags: homelab
---

Every year on March 31st I have a sense of minor guilt, anxiety, and sheepishness. It's [World Backup Day](https://www.worldbackupday.com/en/) and I don't have good backups. The purpose of the day is to serve as a reminder to check that your backup system is functioning, that you can restore from your backups, and that all your data is included in the backup system.

It's not like I don't have backups of my data, it's just they're not _backup_ backups, you know? I could probably find a second copy of the most important stuff, or anything I'd lose isn't that hard to reproduce. I've never had a computer fail or catastrophic accident, so I've never had to test this theory. The only significant piece of data I self-host is [my RSS subscriptions][rss-hosting], and that data is synced to the client on my phone, so I can just re-upload the OPML file.

[rss-hosting]: /2024/02/21/a-successful-experiment-in-self-hosted-rss-reading/

You see what I'm like? I'm skirting around having a real system based on somewhat vague recovery assumptions. Well that changes today. Actually that changed two months ago, but I'm only writing about it now.

I'd like to be able to say I've got a solid system and explain how it fits together, but this is much more of a work in progress. I'm hoping that by writing out all my problems it'll make it easier to see what the best solution is.

# Will's Backup History

I've written about this before when I [explained how I picked my Synology](/2023/07/03/picking-a-synology/) a few years ago, but I'll forgive you for not remembering. I didn't even remember that it was in that post.

My existing backup system was absolutely rickety. It basically revolved around everything running `rsync` to get files onto the Synology, and then [running `rsnapshot` on the Synology](/2023/03/07/installing-rsnapshot-on-synology-ds420j/) to create a daily snapshot of all those files. Some things would run `rsync` to get files onto my "main" home server, so that when _that_ synced, the files would be included.

In theory this means I can go to any of the snapshots and see the state my computer was in for that day. In reality there was no guarantee that the `rsync` command on the server had run, so the `rsnapshot` command on the Synology might be creating meaningless copies. Or the `rsync` command could have failed part way, so `rsnapshot` could instead be propagating a state that never actually existed.

The furthest these backups got was my Synology, which sits right next to my other servers. It does have 1-disk redundancy, so it's a fair bit more resilient to hardware failures, but it's still living in my apartment. If a micrometeorite crashed into my apartment and collided with that bit of shelf, I'd be out of luck.

# Restic

The tool I've decided to use is [Restic][restic]. It's a command-line tool written in Go, available in all major package managers, and available on all major platforms. This is great because it means backups on my Mac could be restored onto a Linux machine, or vice versa. If I'm dealing with catastrophic data loss, I'd rather not be worrying about finding the right type of hardware to restore onto.

[restic]: https://restic.net/

Restic chunks your data up and stores each backup run as a snapshot with a unique identifier. When a chunk of data isn't referenced by any snapshot, it can be deleted. New snapshots only have to store chunks that have changed, so the incremental data storage and transfer is only whatever has changed since the previous snapshot. Since the data is chunked, if you only alter one byte in a 10GB file you don't have to copy the whole file, just the chunk that's changed. Already a bunch of improvements over using `rsync`.

I think Restic is a great backup tool, but it's not a _complete_ backup tool. It handles taking your files and putting them in a backup. That backup can be on the local disk, somewhere over SFTP, or through a myriad of cloud storage systems via [rclone](https://rclone.org). Once you've got backups, Restic will let you inspect them, pull out single files, or restore the whole backup into the local filesystem. You can even [make a FUSE mount of a snapshot][restic-fuse]. Restic also supports managing the snapshots; removing old ones, downsampling the number that you retain as they get older. The options for removing snapshots make it easy to [declare a policy][snapshot-pruning] of how many restore points you'd like to keep.

[restic-fuse]: https://restic.readthedocs.io/en/latest/050_restore.html#restoring-using-mount
[snapshot-pruning]: https://restic.readthedocs.io/en/latest/060_forget.html#removing-snapshots-according-to-a-policy

As a brief aside, the Restic docs are exceptional. Basically every question I had about how things fit together was answered and easy to find in their documentation. It's great stuff.

A slightly more niche feature that Restic supports is the ability to copy snapshots between backup locations ("repositories"). So to have backups in a NAS and in a cloud provider, you don't have to run the backup process twice, you can backup to the NAS and then copy that backup to the cloud provider using `restic copy`.

# Scheduling

The feature that Restic doesn't have is scheduling. They've drawn a very clear line that they'll support all the other stuff, but you need to tell them when to do it.

Scheduling on servers is easy. I dump a script in `cron` and because the server is on all the time, the script runs exactly on schedule. A laptop is more difficult. Take a moment to think about all the annoying things you'll have to worry about with a laptop. It's a long list.

The main one is that my personal laptop isn't used for long uninterrupted periods on a regular basis. If I scheduled backups to run every hour, I could easily end up with no backups. If I'm not using it on the hour, the backup just won't get run. I assumed that someone would have made a MacOS app that took this kind of sporadic usage into account. The best I could find was [Restic Scheduler][restic-scheduler] which shows the backup status in the menu bar, and runs backups on a schedule, but it still just runs a fixed schedule. If your laptop isn't on at the scheduled time, you get no backup.

[restic-scheduler]: https://github.com/sergeymakinen/ResticScheduler

What I want is a rules-based system for when to run the backups. Every few minutes, check how long it's been since the last backup, and if it's more than a few hours, seize the day and make a backup. You could get more advanced by taking into account the network connectivity and battery level. You could even measure how long it takes to do a backup and alter the frequency based on how much it differs from the expected backup speed.

Naturally, nothing really ticked all the boxes I was looking for so I wrote my own scheduler. It's called Rest Up, and you can find it [on Codeberg](https://codeberg.org/willhbr/rest-up). It's designed to be run regularly—by some periodic scheduler like `cron`, `launchd`, or a systemd timer—and it keeps state on when the last backup was in order to only run a new backup after a configurable waiting period.

Writing my own tool also meant I could add some status reporting that you wouldn't get if you just ran `restic` through `cron`. Rest Up can show the backup status in the shell, tmux status line, or via [SwiftBar](https://swiftbar.app). Since I'm virtually always using tmux, I can see how long ago the last backup was, when the next one should start, and any errors.

This way I get a little tick in my Mac's menu bar and in the tmux status line saying that my computer is backed up as expected. If there's a failure, I'll see it the next time I use my computer and can fix it immediately.

# Podman

My "production" server (the one that [runs Alpine](/2025/03/09/a-slim-home-server-with-alpine-linux/) with everything in containers) has all of its data in Podman volumes. There are a few different ways I could back these up. The "easiest" would be including `~/.local/share/containers` in the snapshot and capturing absolutely all my Podman state—containers, images, volumes, etc. I don't want to back up gigabytes of images and temporary container state, I just want to back up volumes.

You can export volumes as Tar files with `podman volume export`. Restic can [backup data that's output by a command](https://restic.readthedocs.io/en/stable/040_backup.html#reading-data-from-a-command), rather than just the filesystem. You could pair these two together and dump the archive directly into the backup.

The other option, what I ended up doing, is to run Restic in a container and simply mount the volumes to that container. Restic just sees them as part of the filesystem, and they get backed up normally. This also has the advantage of keeping Restic in a container itself, so my containers-only computer can continue to just run containers.

# Replication

Initially I only set out to back up my computers to my Synology. Having an offsite copy wasn't something I was too worried about, since a lot of my important data was already stored somewhere off site (like all my code being on Codeberg, etc).

However, given that everything was in Restic, it wasn't too hard to start pushing snapshots between different locations with `restic copy`. I started by setting up Restic repositories in Google Drive with Rclone (since I have unused storage there) making sure to [copy the chunker params](https://restic.readthedocs.io/en/latest/045_working_with_repos.html#copying-snapshots-between-repositories) from the repositories on the Synology.

Setting up Rclone was fairly straightforward, I just [followed the documentation](https://rclone.org/drive/), and chose the `drive.file` permission scope (Rclone can manage files it creates, but nothing else). I tried using the default Rclone client ID, but this effectively didn't work—as the documentation warns—so I got my own keys by creating a GCP project, [again following the documentation](https://rclone.org/drive/#making-your-own-client-id).

For a while I just had a shell script run via `cron` that would `restic copy` between the repos, which was _fine_. Perfectly serviceable. I do however crave complexity, so I have written a little server that does this for me, while also exporting Prometheus metrics about my backup state. You can [find the code for that on Codeberg](https://codeberg.org/willhbr/restic-replicator) as well.

Since I've got a server managing the replication, I can use that to handle pruning too. This means each client only has to do `restic backup`. I'll probably remove the pruning logic from Rest Up.

# Future

As much as I like building little tools, what I'd really like is a combination of my replication server and the [Restic _Rest Server_](https://github.com/restic/rest-server). It provides an HTTP API that the Restic client can use, and it has an append-only mode that ensures that the client only adds new data, preventing it from deleting existing snapshots. This would let me backup from less-trusted computers (like a VPS) without giving SFTP access to my Synology. If I could then configure that server to prune itself periodically, and copy its data to an offsite repository, that would be fewer moving parts to manage.

The _Rest Server_ is slightly faster than using SFTP. I did some tests and found that SFTP would copy about 40GB per hour, whereas copying to Rest Server did about 52GB per hour—both on my home wifi copying to a device on the same network. Both were copying the same 160GB contents of my home directory on my laptop.

An extra 12GB per hour is not insignificant, but I still haven't used Restic to backup my full photo library. It's backing up my Pixelmator/Photomator documents, but not the actual library. I'm still in a bit of [a photo management rut](/2025/12/26/stuck-in-a-photo-management-factory/), so this isn't really a knock on Restic.

I've still got some work to do, Rest Up and the replicator server can be tweaked and improved. I need to automate or document my process for getting a new computer set up. Overall I'm really glad I've spent the time to set this up. I'm already just a little bit more relaxed knowing that I can just leave a file on my computer and know that it'll soon be absorbed safely into the backup vortex. If you don't have good backups, don't wait until next March, just setup Restic now.
