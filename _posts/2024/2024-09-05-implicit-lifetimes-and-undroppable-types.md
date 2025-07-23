---
title: "Implicit Lifetimes and Undroppable Types"
tags: languages opinion
---

Ok I need to put a really heavy caveat at the start here: I am not a Rust expert. I wouldn't even call myself a Rust novice. I'm more of a Rust admirer. I've spent plenty of time trying to learn Rust and then just going back to [Crystal](/2023/06/24/why-crystal-is-the-best-language-ever/) whenever I actually want to get something done. I don't think this is a knock on Rust, it's just got a very different set of priorities to Crystal. The biggest difference is that the Crystal standard library is batteries-included whereas in Rust you have to find a module for the anode and cathode separately. The furthest I've got into a Rust project was rewriting [pod](https://codeberg.org/willhbr/pod). I got about 60% of the way through and then ran out of free time and enthusiasm.[^cool-maths]

[^cool-maths]: I did do a cool thing where all the operations that you can do on a container were reversible, so every operation would return the operation that reversed it, which would theoretically make automatic rollbacks really easy to implement.

So if you _are_ a Rust expert, either stop reading now or just read this with the mindset of when a small child is telling you about what they learnt in school today.

With that out of the way, instead of talking about Rust, let's talk about Java. Without even realising it, you think about the lifetimes of variables implicitly as you're writing a program. Consider this:

```java
void handleRequest(Request req, ResponseWriter writer) {
  checkValid(req);

  database.getUser(req.id);
  ...
}
```

Without looking at the implementation of `checkValid`, you can be pretty sure from context that it:

- Will not hold onto a reference to the request
- Will not mutate the request
- Will throw an exception if the request is invalid

None of that is enforced by the type system though, you have to just assume that whoever wrote `checkValid` wrote it in good faith and good taste. The difference in Rust is that you can enforce the first two invariants using the type system (Rust doesn't have exceptions so you can't do the last one, you'd have to design the API differently).

So in Java we could totally do this:

```java
void checkValid(Request req) {
  GlobalCheckedRequestStore.addRequest(req);
  req.id += 4;
}
```

And there's nothing the type system can do prevent us from doing this. However in Rust, the `Request` would be _borrowed_ by the `checkValid` function, and so you can't give it to something else that will hold onto it for longer than the function. That would forbid is from passing it to our sneaky `GlobalCheckedRequestStore.addRequest`, since that will store it and keep it around after `checkValid` has returned.

As soon as you start looking, you'll see these kind of things appear constantly. In Python you shouldn't do this:

```python
my_file = open('/tmp/file', 'w')
my_file.write('some text')
my_file.close()
my_file.write('some more text')
```

_Obviously_ that won't work, and since you're really clever you can spot it. However when the program gets complicated, you'll probably start to struggle. Python has a solution to this problem though: `with`. Just use `with` and you can never accidentally write to a closed file!

```python
with open('/tmp/file', 'w') as my_file:
  my_file.write('some text')
  write_more_text(my_file)
```

Problem solved!

Wait but what if `write_more_text` does something that holds onto a reference to `my_file` after the function returns... **damnit** we're doing implicit lifetimes again! Or what if we're really silly and do:

```python
my_file = None
with open('/tmp/file', 'w') as f:
  my_file = f
my_file.write('some text')
```

This just appears over and over and over, especially when async work is involved. You'll see a version of this problem in basically every server API (HTTP, TCP, WebSockets, etc), and File APIs. It's particularly easy to do this when you're working asynchronously:

```crystal
require "http/server"

server = HTTP::Server.new do |context|
  context.response.content_type = "text/plain"
  spawn do
    sleep 10.seconds
    context.response.print "I'm a slow response"
  end
  context.response.print "Hello world, got #{context.request.path}!"
end
```

The response will have already been sent to the client and `context.response` closed by the time we try to write "I'm a slow response".

Rust solves this problem with strict lifetime checks. This isn't a problem in Rust because the compiler will stop you from setting `my_file` to `f` or sharing access to the `context` from two async contexts.

What Rust doesn't do is prevent you from forgetting to close a file. The [actual `File` implementation in Rust says](https://doc.rust-lang.org/std/fs/struct.File.html):

> Files are automatically closed when they go out of scope. Errors detected on closing are ignored by the implementation of `Drop`. Use the method `sync_all` if these errors must be manually handled.

The type system can't save you from this one. As soon as a file goes out of scope, it is closed and any error is silently ignored.

What actually started this whole train of thoughts was reading [this blog post](https://without.boats/blog/ownership/) about ownership in Rust. I'm not going to pretend I understand even some of the type theory, but this one section stood out to me:[^is-this-the-point]

[^is-this-the-point]: I don't know if this is really the main point of that post, but this is what I got out of it.

> Let’s take a very simple example, a transaction which must be committed or aborted:
>
> ```rust
> impl Transaction {
>     pub fn commit(self) -> TransactionResult;
>
>     pub fn abort(self);
> }
> ```
>
> The problem with a session type like this is that the user can just drop the transaction. You might say in this case that you’ll write a destructor and abort the transaction on drop (I’ll return to that idea in the next section), but you can surely imagine more complex examples in which there isn’t an obvious state transition to perform on drop.

This made me see lifetimes in a new way that I hadn't considered before: you can use a lifetime to _prevent_ an object from being discarded when it's in a particular state.

Currently every type in Rust can be implicitly dropped when it reaches the end of the lexical scope it is bound in. The type can define what happens at this point by overriding the destructor, which is how things like [`Arc`][arc] work. What the type _can't_ do is say "I cannot be discarded".

[arc]: https://doc.rust-lang.org/std/sync/struct.Arc.html

If we could do this, it would look something like this:

```rust
fn main() {
  let undroppable = Undroppable::new();
}
```

That would of course fail to compile:

```console
$ cargo run
   Compiling
 --> src/main.rs:2:7
  |
2 |     let undroppable = Undroppable::new();
  |         ^ help: This type does not implement std::ops::Drop
  |
```

This is not real, it's just an illustration.
{:class="caption"}

A type that you cannot instantiate because it'll stop your project from compiling doesn't seem that useful, but it's like the [`never` type](https://doc.rust-lang.org/std/primitive.never.html) (that also appears in [Swift](https://developer.apple.com/documentation/swift/never) and [Kotlin](https://kotlinlang.org/api/latest/jvm/stdlib/kotlin/-nothing.html)).

We can apply this to our file API. Instead of just having a `File` type, we'll have a `Path` which represents the location of the file before we open it, an `OpenFile` which we can read and write from, and a `ClosedFile`.

The trick is that `OpenFile` cannot be dropped, which means the compiler will force us to call `.close()` on the `OpenFile`.

```rust
fn main() {
  let path = Path::new("/tmp/file");
  let file: OpenFile = path.open();
  write_contents_to_file(&file);
  // This turns the OpenFile into a ClosedFile
  file.close().unwrap();
} // The ClosedFile gets dropped here
```

Of course there has to be an internal way for the `OpenFile` to be translated into a `ClosedFile` within the `.close()` method—for example a private destructor that can only be called from methods in that type. That `.close()` method signature would look something like:

```rust
impl OpenFile {
  fn close(self) -> Result<ClosedFile, Err>
}
```

It takes ownership of the `OpenFile`, closes the system resource, uses the internal destructor to drop the `OpenFile` and returns a `ClosedFile` that represents the state of the file on close. This forces the caller to close the file and handle the errors.

This same pattern could apply in so many situations where some explicit action **must** be done before an object is discarded. Make sure that a `Response` object has been written to, require that a `Thread` gets `join`-ed, make sure a `Channel` is closed, that every `async` is `await`-ed, or make sure a database transaction either committed or rolled back. The list goes on.

This could even work around issues like [async cleanup](https://without.boats/blog/asynchronous-clean-up/). A type that needs to do async work (or error-prone work) to clean itself up just has to make itself un-droppable and move the cleanup into a method that transitions to a type that can be trivially dropped.

I remember in university being _explicitly_ told that objected-oriented "becomes-a" is a terrible anti-pattern, which I suppose is still true if you're talking about the Java type system, which can't even express nullability properly.

Last year [I wrote a long ramble about concurrency](/2023/10/31/how-i-learned-to-stop-worrying-and-love-concurrency/), where I mostly glossed over the whole concept of lifetimes, but wrote:

> What I’d like is—somehow—for concurrent data access to be verified as easily as types are checked in Crystal. I get most of the benefits of static typing and dynamic typing by using Crystal’s type inference, can the lifetimes of variables be inferred in a similar way? I think this would be a very hard problem, and probably only practical if the general population of developers was already used to adding lifetime annotations—like they are with types—so you could just require fewer of them.

Much like nullability in Java, adding any kind of lifetimes into an existing type system would be incredibly difficult, as you don't know the lifetime of any unannotated type, so all bets are immediately off. In Java you `@NotNull` as much as you want, but someone can totally just throw a `null` your way and you have to deal with that at runtime.

You'd maybe end up in a similar situation to C++, where you can use `std::unique_ptr<>` and references as much as you want, but eventually a function is going to expect a raw pointer, and you're going to have to work out whether that pointer will move, share, or borrow ownership.

I think what I'd really like is a language with a batteries-included standard library, an ownership model like Rust's, but also a shorter syntax for creating reference-counted types.[^pony]

[^pony]: Maybe that's [Pony](https://www.ponylang.io)?
