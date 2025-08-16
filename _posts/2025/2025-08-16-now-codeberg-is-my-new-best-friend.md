---
title: "Now Codeberg Is My New Best Friend"
tags: tools
---

Most of my projects are now consolidated [on Codeberg][my-codeberg]. Previously my projects were split between GitHub and GitLab, but I've finally put in the effort to get everything (or at least most of everything) together in one place.

[my-codeberg]: https://codeberg.org/willhbr.

I started using GitLab because at the time GitHub didn't offer private repositories for free accounts, whereas GitLab did. So I'd have all the work I wanted to share on GitHub, and then all my non-shared work and in-progress work on GitLab.

GitLab was also enticing because of their [open-source community edition][gitlab-community] which my university used for student projects, so I appreciated the consistency there. [GitLab CI][gitlab-ci] was also a huge improvement instead of using Jenkins for coursework.

[gitlab-community]: https://about.gitlab.com/install/
[gitlab-ci]: /2016/02/12/testing-gitlab-ci/

What would happen is that I'd work on something in private on GitLab, then when I felt it was worthwhile publishing I'd add a new remote to the repo and push to a public repo on GitHub, and continue working there. This left stale repos hanging around on GitLab and left me confused about where I was pushing changes. I could have just decided to go all-in on GitHub, but since I had to move at least half my repos anyway, I figured I might as well consider all the options.

There are a bunch of reasons one might want to move away from GitHub. Something as simple as [not wanting to have software development and distribution controlled by one entity][only-option]. To be honest, I'm just sick of how [slow the GitHub web UI][slow-github] is. It's not pleasant to use—at least here in Australia, since I know a lot of these things can depend on the speed of light. Even on high-end devices that should be more than capable of smooth scrolling of a page, viewing code on GitHub is often jittery and unpleasant.

[only-option]: https://blog.edwardloveall.com/lets-make-sure-github-doesnt-become-the-only-option
[slow-github]: https://yoyo-code.com/why-is-github-ui-getting-so-much-slower/

Of course I can move my own projects, but I'll still end up looking at code on GitHub because that's where everyone else's code is. But you've got to be the change you want to see in the world.

And what change is that?

I thought about a few different ways I could consolidate my projects:

The easiest would be to move everything to either GitHub or GitLab, since they both support unlimited public and private repos. The split that I've had is no longer necessary, and I kept doing it because of momentum. This doesn't solve the slow UI issue though.

Next easiest is moving to a smaller host, the top contenders being [Codeberg][codeberg] or [sourcehut][sourcehut]. Both have much lighter-weight interfaces. A concern with both of these is they're periodically [down because of DDoS attacks][ddos] or other traffic influxes that are harder to deal with for an independent organisation.

[ddos]: https://www.macchaffee.com/blog/2024/ddos-attacks/
[sourcehut]: https://sourcehut.org
[codeberg]: https://codeberg.org

The most involved option would be self-hosting. This could come in two flavours, either having it publicly accessible, or keeping it private and publishing to a second public host as a mirror. The biggest advantage here is that the speed of light—whether it's to a datacenter in Sydney or to the cupboard in my apartment—is very fast. I mused on Mastodon about hosting publicly and [got a note][mad-scientist] from the author of [Iocaine][iocaine] that eventually my VPS would get overrun with scrapers requesting every single accessible URL.

[iocaine]: https://iocaine.madhouse-project.org
[mad-scientist]: https://come-from.mad-scientist.club/@algernon/statuses/01JR0BE45PAWC7TETH2HHY3TMT

Scrapers sending [endless requests to self-hosted git forges][anubis-origin] is why you've probably seen an [anime girl pop up][anubis] before you're able to visit some sites.

[anubis]: https://anubis.techaro.lol
[anubis-origin]: https://xeiaso.net/notes/2025/amazon-crawler/

Of these three options, I've obviously settled on the second. [Forgejo](https://forgejo.org)—the software behind Codeberg—is easy to self-host and I trust that if I choose to do this in the future, it won't be hard for me to migrate my repositories from Codeberg to my own Forgejo instance.

Working out what to do was the fun bit, actually doing it was boring. Before migrating I had around 90 repos on GitLab and 60 on GitHub. Many of these overlapped, but since the names were not all consistent the only way to be sure was look at them and try to remember the names I'd given projects almost 10 years ago.

What I ended up doing was using a script that automatically migrated all my GitHub repos over to Codeberg, then made a spreadsheet of all the repos I had on GitLab and cross-checked them manually to see which were out of date or maybe included some commits that hadn't been pushed to GitLab. This was a pretty tedious process, but it was over a decade of mess that I had to clean up.

After getting all my repos in one place, I had to update any inter-linked dependencies referring back to the repos on GitHub, mainly `shard.yml` dependencies and links on my website.

Given the history of DDoS attacks targeting Codeberg, I was a little concerned about availability. I wrote a little program that will clone or fetch all my repos from GitHub, GitLab, and Codeberg periodically. I probably should have had an actual backup system for GitHub and GitLab—it's a bad idea to only have one copy of things—but I didn't, so I used this as the impetus to make one. This way I know that I've got a local copy of everything available if there are any problems with the remote. It's not quite finished yet (it inexplicably fails to build an archive of everything at the end) so I need to do a bit more work. I'm just including this here to shame myself into cleaning it up to a point I can publish it.

Overall I'm happy that I've got everything in one place, and it's a nice feeling to know I can make a private repo and then just clink a button in the same place and have it be public with no extra effort.

A big quality of life improvement for me was finding the "Forgejo dark" theme in the "Appearance" settings. I wasn't a fan of the very-blue default Codeberg UI, the grey/orange Forgejo UI is much more to my liking.

For now the projects that remain on GitHub are those that rely on [GitHub Pages](https://pages.github.com). This is mostly to save me from myself, since if I were given the option to build websites with something other than the limited Jekyll setup, I wouldn't know when to stop.

Another project I'm interested in is [Forgefed](http://forgefed.org), a federation protocol for software forges to allow issues and pull requests to be authored by users registered on different forges. In theory this would mean a self-hosted Forgejo instance could open a pull request on a Codeberg-hosted repo. It's basically a modernised version of the [git email workflow][git-email], replacing email with [ActivityPub][activitypub].

[activitypub]: https://activitypub.rocks
[git-email]: https://git-scm.com/book/en/v2/Appendix-C%3A-Git-Commands-Email

If you do want to send a patch, issue, or feedback to [one of my repos][my-codeberg], you can always just [send me an email](mailto:{{ site.email }}) if you don't want to register with Codeberg. You could even [encode your patch in a GIF][git-gif] and [toot it to me on Mastodon]({{ site.urls.mastodon }}).

[git-gif]: /2025/06/16/gif-the-git-interchange-format/

If you choose to migrate to Codeberg, remember to [donate](https://donate.codeberg.org/) a bit if you can.
