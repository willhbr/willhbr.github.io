---
layout: post
title: "Create a Mastodon alias using GitHub Pages"
date: 2023-01-24
---

If (like me) you've moved to [Mastodon](https://joinmastodon.org) recently and are looking for a good way to show off some nerd cred, this is a great way to do it.

Mastodon (and the rest of the ActivityPub fediverse) use [WebFinger](http://webfinger.net) to discover user accounts on other servers and across different services. It's used as the way to get the user's ActivityPub endpoint (which can potentially be on a different domain or non-standard path). We're going to make use of the "different domain" feature here.

The idea is to plop your WebFinger information on your GitHub Pages-powered site, so that Mastodon can dereference something like `@willhbr@willhbr.net` to an actual Mastodon instance (in my case, [ruby.social]({{ site.mastodon_url }})). There are some [plugins](https://github.com/philnash/jekyll-mastodon_webfinger) to do this, but they don't work with GitHub's "no plugins unless you build the site yourself and upload the result" policy. So we're going pluginless.

Firstly, get the WebFinger info for your Mastodon account:

```shell
$ curl 'https://$MASTODON_INSTANCE/.well-known/webfinger?resource=$USERNAME@$MASTODON_INSTANCE'
```

It should look something like:

```json
{
  "subject": "acct:willhbr@ruby.social",
  "aliases\"": [
    "https://ruby.social/@willhbr",
    "https://ruby.social/users/willhbr"
  ],
  "links": [
    {
      "rel": "http://webfinger.net/rel/profile-page",
      "type": "text/html",
      "href": "https://ruby.social/@willhbr"
    },
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://ruby.social/users/willhbr"
    },
    {
      "rel": "http://ostatus.org/schema/1.0/subscribe",
      "template": "https://ruby.social/authorize_interaction?uri={uri}"
    }
  ]
}
```

Save that into `/.well-known/webfinger` in the root of your Jekyll site, and tell Jekyll to include the hidden directory when it builds:

```yaml
# in _config.yml
include:
  - .well-known
```

Then just commit and push your site to GitHub. Once it's deployed, you should be able to search for yourself: `@anyrandomusername@$MY_WEBSITE_URL`.

> Since the server is static, it can't change the response based on the `resource` query parameter, but since (I assume) you're doing this for yourself on your personal website, that shouldn't matter too much.

## Needless Polishing

That's cool, but we can do better. Replace the `.well-known/webfinger` file with a template:

```
---
---
{{ site.webfinger | jsonify }}
```

Then you can keep the WebFinger info in `_config.yml` so it's more accessible (not in a hidden directory) and have it checked for syntax errors when your site builds. I've translated mine to YAML:

```yaml
# in _config.yml
include:
  - .well-known

webfinger:
  subject: "acct:willhbr@ruby.social"
  aliases": ["https://ruby.social/@willhbr", "https://ruby.social/users/willhbr"]
  links:
    - rel: "http://webfinger.net/rel/profile-page"
      type: "text/html"
      href: "https://ruby.social/@willhbr"
    - rel: "self"
      type: "application/activity+json"
      href: "https://ruby.social/users/willhbr"
    - rel: "http://ostatus.org/schema/1.0/subscribe"
      template: "https://ruby.social/authorize_interaction?uri={uri}"
```

Nerd cred achieved, without a plugin. [Toot me]({{ site.mastodon_url }}).
