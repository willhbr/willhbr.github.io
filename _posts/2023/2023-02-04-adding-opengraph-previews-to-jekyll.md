---
title: "Adding OpenGraph previews to Jekyll"
image: /images/2023/opengraph-message.jpeg
---

I'm on a tear adding support for open web standards to my website(s) - if I've missed one, [let me know]({{ site.urls.mastodon }}). I've just added [RSS meta tags](https://www.petefreitag.com/item/384.cfm) which allow for feed reading plugins to suggest the RSS feed - rather than people having to find the RSS link (it's at the bottom of the page) and paste that into their feed reader. There must be _dozens_ of people who haven't been reading my amazing content because it was too hard to add my site into their feed reader.

The other standard is [OpenGraph](https://ogp.me) which tells other services how to build a rich preview of your site. The obvious examples are links from social media sites (like Facebook, the author of the standard), or messaging apps:

![a screenshot of an message showing a link to one of my blog posts, with a title and preview image](/images/2023/opengraph-message.jpeg)

This is fairly simple to do, you just need to add some `<meta>` tags to the `<head>` of your site, for example my [Jekyll](http://jekyllrb.com) template:

```html
{% raw %}
<meta property="og:url" content="{{ page.url | absolute_url }}">
<meta property="og:type" content="{% if page.type != null %}{{ page.type }}{% elsif page.layout == "post" %}article{% else %}website{% endif %}">
<meta property="og:title" content="{{ page.title }}">
<meta property="og:description" content="{{ site.description }}">
<meta property="og:image" content="{% if page.image != null %}{{ page.image }}{% else %}/images/me.jpg{% endif %}">
{% endraw %}
```

This will populate the correct URL (the absolute URL for the current page), guess the type either from a field on the page or whether it's a `post`, and show a default image of me or a custom one specified by the page. This lets me customise posts with frontmatter:

```markdown
---
title: "A custom OpenGraph post"
type: article
layout: post
image: /images/some-image.jpeg
---
# ... content of the post
```

I then checked using [opengraph.xyz](http://opengraph.xyz) that my formatting was correct. As with most standards, different implementations with have varying quirks and may display things differently. Since I'm just adding a preview image, I'm not too fussed about 100% correctness.

This has also been done to my [photos website](https://pics.willhbr.net) so if a particular post is shared from there, it will get the preview thumbnail.
