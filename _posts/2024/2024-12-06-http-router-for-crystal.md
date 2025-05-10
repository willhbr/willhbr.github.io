---
title: "HTTP Router for Crystal"
tags: crystal
---

The most common thing that I do with [Crystal macros](https://crystal-lang.org/reference/latest/syntax_and_semantics/macros/index.html) is to write some way of generating a `case` statement. If you're writing something that does networking or deserialisation, translating data into method calls is very common, and automatically generating the code to do it is neat.

I've been adding some more HTTP endpoints to my container status board, which has meant that my previously-simple routing logic started to get a bit messy, so it was time to write a macro. I did look at [awesome-crystal](https://github.com/veelenga/awesome-crystal) to see if there was an existing library that I could use. There are two—[router.cr](https://github.com/tbrand/router.cr) and  [orion](https://github.com/obsidian/orion)—but neither are quite what I'm looking for. They more closely match the [Rails-style routing DSL](https://guides.rubyonrails.org/routing.html), whereas I just wanted something that would dispatch between methods on an `HTTP::Handler` class.

The resulting macro isn't very big, and all it does is generate a `call(context)` method for you with a single `case` statement in it. It means you can do this:

```crystal
class MyHander
  include HTTP::Handler
  include HTTP::Router

  @[HTTP::Route(path: "/stuff")]
  @[HTTP::Route(path: "/stuff", method: :HEAD)]
  def get_stuff(context)
    context.ok_json(result: "success!")
  end

  @[HTTP::Route(path: "/stuff", method: :POST)]
  def post_stuff(context)
    contents = context.request.body.get_to_end
    puts contents
    context.ok_json(result: "success!")
  end
end
```

And not have to manually write this out:

```crystal
def call(context : HTTP::Server::Context)
  req = context.request
  case { req.method, req.path }
  when { "GET", "/stuff" }
    self.get_stuff(context)
  when { "HEAD", "/stuff" }
    self.get_stuff(context)
  when { "POST", "/stuff" }
    self.post_stuff(context)
  else
    call_next context
  end
end
```

You can [have a look at it on Codeberg](https://codeberg.org/willhbr/http-router).
