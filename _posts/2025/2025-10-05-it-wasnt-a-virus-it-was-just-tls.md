---
title: "It Wasn't a Virus, It Was Just TLS"
tags: web debugging
---

This has been going on for like a year. Every time I run an HTTP server to preview something, I get a bunch of junk data sent to it:

```
100.73.68.18 - - [16/Aug/2025 19:55:15] code 400, message Bad HTTP/0.9 request type
('\\x16\\x03\\x01\\x02\\x00\\x01\\x00\\x01ü\\x03\\x03W#Ø7e¬(ÛãÙþ>-cÞ±öý^rO7\\x83=æÁ\\x8bÑ"ÎD\\x97')
```

I had no idea where this was coming from. Some background process on my laptop? A device on my network? A browser extension gone rogue?

Clearly I wasn't actually _that_ concerned about it since I have ignored it for so long. But then this week I noticed that the same thing was happening with my Caddy server:

```json
"Unsolicited response received on idle HTTP channel starting with \"\\x1f\\x8b\\b\\x00i\\b\\x9fh\\x00\\xff+N\\xccM\\xe5\\x02\\x00\\xebÓšC\\x05\\x00\\x00\\x00\"; err=<nil>"
```

I [run Caddy as an HTTP proxy](/2025/03/09/a-slim-home-server-with-alpine-linux/) in order to get sensible domain names for my self-hosted services, so this traffic had to be coming from one of my own devices.

It finally boiled over and I had to get to the bottom of it. So I started in the only way I know how: writing a server in Crystal.

The Python (and Caddy) servers were telling me they were receiving invalid HTTP requests, but they didn't give me much more to go on. Was it invalid data passed during an HTTP request, was it sent before or after the successful request?

A real HTTP server would obfuscate most of this detail, so instead I used the Crystal `TCPServer` class to make a simple debugging view that showed more info about the actual HTTP data being written. All lines received would be printed, and every request would get the same HTTP 302 redirect response.

Servers in Crystal can be shockingly simple:

```crystal
require "socket"

OK = "
HTTP/1.1 302
Location: http://endash/
".strip

server = TCPServer.new("0", 80)

id = 0
while client = server.accept?
  id += 1
  new_id = id
  spawn do
    puts "Connection #{new_id}: #{client.inspect}"
    handle_client(new_id, client)
    while line = client.gets
      puts "#{new_id.to_s.rjust(3)}: #{line.inspect}"
      break if line.empty?
    end
    client.puts OK
    client.close
  end
end
```

The server would read lines from the client, printing each line, and when it got to an empty line (the end of the headers) it would write the canned response and close the connection. Each request would be prefixed with the client number so I could differentiate between the connections that were established.

Using this and some prior debugging with the Python server I could pin down the behaviour:

- The first request from Safari always triggered the garbage
- The second request to the same (host, port) did not
- No requests from Firefox triggered it
- Using Safari after initially sending a request from Firefox would still trigger it

This meant it was something specific to Safari, not related to the OS or another device (I should have noted initially that the IP the request was coming from was always my laptop, which would have ruled out any other device). Since it didn't happen in Firefox, and using Firefox didn't change Safari's behaviour then it was unlikely to be any shared infrastructure in the OS.

Next I turned off my any browser extensions and used a private browsing window, and still got the same behaviour. It's reassuring that some extension wasn't sending nonsense traffic around.

By assigning an ID to each TCP connection, I could see the order in which each connection was established, and then look at the order that the data was received to get a bit better picture of what the request flow was. Interestingly the socket for the legitimate HTTP request was always opened first—and so got the first ID—but the garbage data was what ended up being received first. I didn't really know what to make of this, but it's an interesting data point that'll be useful later.

Doing a web search for the first section of bytes didn't yield anything useful—basically no meaningful results. What did get me a result was using an LLM—I do want to pattern match on a series of tokens after all. I asked "I'm getting a weird non-http request to a development server from Safari on MacOS, it's sending this data, what is it?" and included the first chunk of the request bytes (escaped). Chatty G responded:

> That blob of data you pasted isn’t an HTTP request at all — it’s the start of a TLS ClientHello message.

Aha! There we go! A further search led me to [this excellent explanation][client-hello] that details every part of the `ClientHello` message. This makes sense, and I am always seeing that `16 03 01` at the start of the message, which is the important part that says "this is a TLS `ClientHello` message".

[client-hello]: https://tls12.xargs.org/#client-hello

That's not a virus, Safari is just trying to use TLS on a host that doesn't support TLS. But why does Safari do this when the server is plain HTTP?

One possibility is [HTTP Strict Transport Security][hsts] (HSTS), where the server can set a header and the browser will then refuse to use plain HTTP for a certain time period. I thought that because the server was on a Tailscale "MagicDNS" domain, maybe they'd set a wildcard HSTS policy, but if that were the case then the browser should refuse to connect at all, rather than just attempting a TLS connection and giving up.

[hsts]: https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security

What seems to be the answer is that Safari tries fairly aggressively to upgrade the connection to HTTPS, whereas Firefox does not. If the server had responded back to that `ClientHello` message, I would have been directed to an HTTPS site without my server having to do a redirect itself.

So there you go. I wasn't hacked, Safari was just trying to be helpful.
