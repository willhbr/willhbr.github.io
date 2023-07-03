---
title: "Picking a Synology"
image: /images/2023/backup-system.jpeg
---

One of the key characteristics you want from a backup system is reliability. You want to minimise the number of things that can fail, and reduce the impact of each failure for when they do happen. These are not characteristics that would be used to describe my original backup system:

![a small computer sitting on a shoebox with an external HDD next to it, surrounded by a nest of cables](/images/2023/backup-system.jpeg)

The first iteration of my backup system, running on my [Scooter Computer](https://blog.codinghorror.com/the-scooter-computer/) via an external hard drive enclosure.
{:class="caption"}

This setup pictured above evolved into a Raspberry Pi (featured unused in the bottom of that photo) with two external 4T hard drives connected to it. All my devices would back themselves up to one of the drives, and then `rsnapshot` would copy the contents of one drive across to the other, giving me the ability to look back at my data from a particular day. The cherry on top was a wee program[^cross-compile] that ran an HTTP server with a status page, showing the state of my backups:

[^cross-compile]: The program was written in Crystal, and those in the know will be aware just how painful cross-compilation to ARM is!

![screenshot of a webpage with a list of backup times in a table](/images/2023/backup-status.jpeg)

My custom backup status page that told me whether I was still snapshotting my data or not.
{:class="caption"}

Naturally, this system was incredibly reliable and never broke,[^actually-didnt-break] but I decided to migrate it to a dedicated NAS device anyway. Synology is the obvious choice, they've got a wide range of devices, and a long track record of making decent reliable hardware.

[^actually-didnt-break]: It actually only broke once when one of the disks failed to mount of all my data was spewed onto the mount point on the SD card, filling up the filesystem and grinding the whole thing to a halt.

With the amount of data that I'm working with (<4T) I could absolutely have gone with a 1-bay model. However this leaves no room for redundancy in case one disk fails, no room for expansion, and I already had two disks to donate to the cause. Two bays _would_ have been a sensible choice, it would have allowed me to use both my existing disks and have redundancy if one failed. But it would have limited expansion, and once you're going two bays you might as well go four... right? If I'm buying something to use for many years, having the ability to expand up to 64T of raw storage capacity is reassuring.

At the time that I was researching, Synology had three different four-bay models that I was interested in: the DS420+, DS418, and DS420j.

The DS420+ is the highest end model that doesn't support additional drive expansion (there are some DS9xx+ models that have 4 internal bays and then allow you to expand more with eSATA). It runs an x86 chip, supports Btrfs, allows for NVMe flash cache, and can run Docker containers. It has hot-swappable drive bays and was released in 2020 (that's the -20 suffix on the model name[^future-proofing]).

[^future-proofing]: Can you really trust your backups to a company that has a naming scheme that is going to break in a mere 77 years?

The DS418 is the "value" model, it's basically just the one they made in 2018 and kept around. It also runs an x86 chip, supports Btrfs, and can run Docker containers. It uses the same basic chassis as the DS420+, so also has hot-swappable drives.

The DS420j is the low-cost entry model, running a low-end ARM chip, no Btrfs support, no Docker, and a cheaper chassis with no hot-swappable drives.

Btrfs is a copy-on-write filesystem that never overwrites partial data. Each time part of a block is written, the whole block is re-written out to an unused part of the disk. This gives it the excellent feature of near-free snapshots. You can record some metadata of which blocks were used (or even just which blocks to use for the filesystem metadata) and with that you get a view into the exact state of the disk at that point in time, without having to store a second copy of the data. Using Btrfs would replace [my existing use of `rsnapshot`][rsnapshot], moving that feature from a userspace application to the filesystem.

[rsnapshot]: /2023/03/07/installing-rsnapshot-on-synology-ds420j/

This had initially pointed me towards the DS420+ or DS418. My concern with the 418 was the fact that it was already over 4 years old. I didn't want to buy a device that was bordering on halfway though its useful lifespan (before OS updates and other software support stopped). The cost of the DS418 was only a little bit less than the DS420+, so if I was going to spend DS418 money, I might as well be getting the DS420+.

The other feature of the DS418 and DS420+ was Docker support—you can run applications (or scripts) inside containers, instead of in the cursed Synology Linux environment. I wasn't planning on running anything significant on the Synology itself, it was going to be used just for backup and archival storage. Anything that required compute power would run on my home server.

Eventually I decided that the advantages of Btrfs and Docker support were not enough to justify the ~$300 price premium when compared to the DS420j. I already knew and trusted `rsnapshot` to do the right thing, and I could put that money towards some additional storage. The DS420j is a more recent model, and gives me the most important feature, which is additional storage with minimal hassle.

I've had the DS420j for about three months now, it's been running almost constantly the entire time, and my backup system has moved over to it entirely.

The first thing I realised when setting up the DS420j is despite the OS being Linux based, it does not embrace Linux conventions. Critically it eschews the Linux permission model entirely and implements its own permissions, so every file has to be `777`—world read and writable—for the Synology bits to work. This has knock-on effects to the SSH, SFTP, and rsync features; any user that has access to these has access to the entire drive. Since I'm the user on the Synology, I'm not that bothered by this. The only reason I'd want different users is to have guarantees that different device backups couldn't overwrite each other.

The best thing by far with the Synology is how much stuff is built in or available in the software centre. Setting up Tailscale connectivity, archives from cloud storage (eg Dropbox), and storage usage analysis was trivial.

The most difficult thing about moving to the Synology was working out how to actually move my data over. Archives of various bits were scattered across external hard drives, my laptop, and my RPi backup system. Since I was using the disks from the RPi in the Synology, I had to carefully sequence moving copies of between different disks as I added drives to the Synology (since it has to wipe the drive before it can be used).

During the migration having USB 3 ports on the NAS was excellent, with the RPi I'd be forced to copy things from over the network using another computer, but now I can just plug directly in and transfer in much less time. An unexpected benefit was that I could use an SD card reader to dump video from GoPros directly onto the Synology (since I knew I wasn't going to get around to editing it). This will probably come in handy if I want to actually pull anything off the Synology.

At the moment I'm using 4.1T of storage (most of that is snapshots of my backups). According to the [SHR Calculator](https://www.synology.com/en-us/support/RAID_calculator) I can add two more 4T drives (replacing my 2T drive) to get 12T of usable space, or two 8T drives to get 16T. Since my photo library grows at about 400G per year, I think my expansion space in the DS420j will be sufficient for a long time.[^better-camera]

[^better-camera]: Until I get a Sony a7RV and the size of my raw photos almost triples.
