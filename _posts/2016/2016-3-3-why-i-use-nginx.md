---
title: Why I use Nginx
date: 2016-3-6
layout: post
---

There are two very important reasons why I use Nginx to run my website:

1. It was the first thing I used
2. It has smaller config files than Apache

Even though I have been using it for quite some time, I didn't really understand it - until I setup a second static hosting domain to host a Jenkins theme, which made me realise it's not too bad.

> The css would only be applied if the http headers were correct (ie it had text/css rather than just text/plain). Files servered though GitLab's 'raw' mode have a text/plain header.

So this is my nginx config file, in sections.

    http {
      include /etc/nginx/mime.types;
      passenger_root # Path to the passenger gem;
      passenger_ruby # Path to the ruby shim, from rbenv;

All of my config is in the http section. I'd guess that I can have other sections for different protocols, but this is just a basic web server so all I need is HTTP.

The include mime types line will make nginx serve static files with the correct Content-Type header for the file extension, which is why serving from this works for my Jenkins server but GitLab doesn't.

    server {
      location / {
        root /var/www/blog;
      }
    }

This section defines a default server - anything that doesn't match will just be sent to this, for example [foobar.javanut.net](https://foobar.javanut.net) will just go to the main blog. I could add more things in here if I wanted a subsection to go to somewhere else - maybe I wanted to serve some other content at javanut.net/my_stuff. I could just make a new location block and set the root to be a different location on my server.

    server {
      listen 80;
      server_name static.javanut.net;
      root /var/www/static;
    }
  
This is basically the same as the previous section, it's just another static file server that points to a different folder. The main point here is that the `server_name` has been set, so that it is only accessible on `static.javanut.net`. In the previous example, the `location {}` block is probably unnecessary as it isn't needed here.
  
      server {
        listen 80;
        server_name my_rails_app.javanut.net;
        root /var/www/my_rails_app/current/public;
        passenger_enabled on;
      }
    }
    
Again this is very similar, but this is for a Rails app using passenger. Passenger needs to be installed when nginx is compiled - there is no plugin system for nginx.
