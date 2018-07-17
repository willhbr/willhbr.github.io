---
title: Learn Enhancer 1.6
layout: post
date: 2015-6-8
---

Exam season has started, so naturally I'm looking at any excuse to either not study. Today I had another look at my Chrome extension: [Learn Enhancer](https://chrome.google.com/webstore/detail/learn-enhancer/dnllhgllbbihefjdpamldjnlpllogkcf?hl=en). I made this so when I look at a set of lecture notes instead of showing the content in a tiny frame in the page it would expand it to fill the page. All it does is look for a certain element on a page (an iframe with a pdf in it) and redirect you to the url of the pdf document. All in all it's about 10 lines of javascript.

It works amazingly well for files that are embedded, but some lecturers like to mark their files as 'force download'. For normal people I assume this isn't much of a problem, but whenever I go looking for a file that comes from Learn my downloads folder isn't the first place I look, so I typically end up with duplicates of duplicates clogging up my downloads.

Instead of changing my habits (or studying for discrete math like I was meant to) I had a look into what causes a browser to download a file rather that display it. There are a number of ways that you can do this; in HTML 5 there is a `download` flag that you can add to a link that tells the browser to download it - but only if that browser is Chrome, Opera or Firefox. Moodle (aka Learn) is firmly rooted in the '00s and so this wasn't being used - if it was then it would be trivial to remove that flag from certain links.

Next up was the `content-type` of the request - if it is set to `application/x-forcedownload` then the browser will save it. Sure enough the response from Moodle came back with `content-type: application/x-forcedownload`. All I had to do was change that and then I would be happy. My first thought was using javascript to make an ajax request and then pipe the data back into the DOM as a PDF, a quick test and a load of ascii on my display I reconsidered.

Another option would be to make a proxy that would get the data and then send a new response back with a brand new header, but a quick `wget` showed that Learn checks for a cookie when you try to get the file. Plus it would be really slow and require a server just to run this silly script.

Eventually I realised that I wasn't limited to the functionality of javascript - this was going to be part of an extension, I can use chrome APIs to intercept and modify data! Sure enough there is a [method](https://developer.chrome.com/extensions/webRequest#event-onHeadersReceived) that allows you to pick up responses, modify the header, and then give it to Chrome to use. Perfect.

Enter `content-disposition`. It turns out that the content type isn't the only thing that determines if the file should be displayed or downloaded. `content-disposition` allows you to specify that the file is an attachment and it should have a certain filename. Some more Google-fu and I changed this to `inline` and bam, inline PDFs with no forced downloading.

I also took this opportunity to use another cool feature in Chrome extensions; as well as having a javascript content script that is injected into all pages, you can have CSS that is injected as well - so now any styling that irks me can be gone in a flash of `display: none;`

If you do use Moodle or Blackboard on Chrome, you can [download Learn Enhancer](https://chrome.google.com/webstore/detail/learn-enhancer/dnllhgllbbihefjdpamldjnlpllogkcf?hl=en) to ease your eyes.
