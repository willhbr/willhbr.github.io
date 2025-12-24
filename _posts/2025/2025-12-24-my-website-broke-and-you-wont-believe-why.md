---
title: "My Website Broke and You Won't Believe Why"
tags: debugging web
---

When I published [my last post][signature] I did my usual quick check on the real website, just to make sure it had published, and find the obligatory mistakes that only appear once it's public. I quickly noticed that the XML code block didn't have any syntax highlighting, just a plain unstyled `<code>` section.

[signature]: /2025/12/14/add-a-signature-to-your-website/

My site uses [Rouge](https://rouge.jneen.net/) for syntax highlighting, which I think is the default for GitHub Pages sites that are built with the (now legacy) non-actions system. I've never included an XML code block so _maybe_ Rouge doesn't support it, but it supports so many languages it would be a significant omission.

It's weird that I hadn't noticed this while writing when I was running the site locally, and sure enough I hadn't noticed it because the local site was working exactly as I expected with [beautiful hand-crafted syntax highlighting][syntax-highlighting].

[syntax-highlighting]: /2024/10/03/web-gardening/#syntax-highlighting

So it works locally, but doesn't work on the live site.

I run the site locally in a container and install all the dependencies through the [`github-pages`][gh-pages-gem] gem, which should track the exact version of Jekyll and of all the available plugins, so my local version should be exactly the same as the live one.

[gh-pages-gem]: https://github.com/github/pages-gem

Inspecting the actual HTML of the local site versus the live site, there's a pretty obvious difference. Here's the markup for the local site (truncated):

```html
<div class="language-xml highlighter-rouge">
  <div class="highlight">
    <pre class="highlight">
      <code>
        <span class="nt">&lt;svg</span> <span class="na">xmlns=</span>
        <span class="s">"http://www.w3.org/2000/svg"</span>
        <span class="na">width=</span><span class="s">"1364"</span>
        <span class="na">height=</span><span class="s">"486"</span>
        <span class="na">viewBox=</span><span class="s">"0 0 1364 486"</span><span class="nt">&gt;</span>
        <span class="nt">&lt;path</span> <span class="na">fill=</span>
        <span class="s">"none"</span> <span class="na">stroke=</span><span class="s">"#000"</span>
        <span class="na">stroke-linecap=</span><span class="s">"round"</span>
        ...
      </code>
    </pre>
  </div>
</div>
```

Then here's the markup I was seeing on the live site:

```html
<div class="language-xml highlighter-rouge">
  <div class="highlight">
    <pre class="highlight language-xml" tabindex="0">
      <code class="language-xml">
        <span class="token tag"><span class="token tag"><span class="token punctuation">&lt;</span>svg</span>
          <span class="token attr-name">xmlns</span><span class="token attr-value">
            <span class="token punctuation attr-equals">=</span>
            <span class="token punctuation">"</span>http://www.w3.org/2000/svg<span class="token punctuation">"</span>
          </span>
          <span class="token attr-name">width</span><span class="token attr-value">
            <span class="token punctuation attr-equals">=</span>
            <span class="token punctuation">"</span>1364<span class="token punctuation">"</span>
          </span>
          <span class="token attr-name">height</span><span class="token attr-value">
            <span class="token punctuation attr-equals">=</span>
            <span class="token punctuation">"</span>486<span class="token punctuation">"</span>
          </span>
          ...
      </code>
    </pre>
  </div>
</div>
```

The exceptionally short class names (`na`, `s`, `nt` and such) are what I expect to get from Rouge, but instead I was getting much more detailed, longer class names that didn't match my CSS, so they were left as plain un-highlighted text.

Maybe GitHub is rolling out a new version of the Pages gem that includes a newer Rouge version that creates incompatible markup? That would be pretty rude and also unlikely, there's nothing in the Rouge changelog that would indicate a breaking change like this.

Or maybe they've updated something and Jekyll no longer respects the `highlighter: rouge` configuration option, so it's falling back to some other highlighter that creates different markup. That would also be a rude change, and there hasn't been a release of the Pages gem since [August 2024](https://github.com/github/pages-gem/releases/tag/v232). It seems unlikely that the gem would be out of sync with the system that actually builds your website.

A bit stumped, I asked a friend if they saw the highlighting and they said they did. So it's just a me problem. I tried in Firefox and had no issue—the highlighting showed up exactly as expected.

You might be thinking "it's obvious Will, you've got some browser extension that's messing it up!" But no, I've only got two extensions: [1Blocker][1blocker] and [1Password][1password].[^extension-naming] There's no way either of these would alter the syntax highlighting in code blocks.

1Blocker mostly (as far as I'm aware) uses the _Content Blocker_ API that just hides elements in the DOM, rather than mutating them.

[1password]: https://1password.com
[1blocker]: https://1blocker.com
[^extension-naming]: Seemingly I only use 1Extension.

1Password should only be adding a little account selection dropdown on pages with a login form. There's absolutely no reason for their extension to do anything on my website apart from go "nope no login form here". [^no-api]

[^no-api]: The fact that 1Password requires a browser extension instead of using the OS's specifically-designed API for autofilling passwords is not great. It was understandable before the widespread availability of system-level APIs for autofill, but [iOS and MacOS have had these APIs][auth-services] for over 7 years now. They support it on iOS, but MacOS is left with a misbehaving browser extension.

[auth-services]: https://developer.apple.com/documentation/AuthenticationServices

Well out of complete desperation as I didn't have any better ideas, I disabled both, and sure enough the highlighting worked.

It turns out 1Password is applying its own syntax highlighting to any block matching this selector:

```css
code[class*="language-"], [class*="language-"] code,
code[class*="lang-"], [class*="lang-"] code
```

Searching in the extension code for "token" (you can view the source of all scripts injected by extensions in the developer tools) quickly led me to the unobfuscated `highlightAllUnder` function name, with that selector. A post on the [1Password forum][1p-forum] identifies this code as coming from [prism.js][prismjs], a JavaScript code highlighting library.

[prismjs]: https://prismjs.com/
[1p-forum]: https://www.1password.community/discussions/developers/1password-chrome-extension-is-incorrectly-manipulating--blocks/165639

So there you go, all my wondering about caching and GitHub Pages gem versions was for nothing. I was blinded by the fact it's absurd that my password manager is injecting a code highlighting script into every page I visit, so I didn't bother to try disabling extensions sooner.

I contacted 1Password support and they confirmed what I'd already found in the forum; it's a known issue and they're working on a fix. Hopefully they will share some information on how this code got into the extension. My assumption is that it's used in the main app for some feature (like code blocks in notes) and accidentally got included as a dependency of the browser extension.
