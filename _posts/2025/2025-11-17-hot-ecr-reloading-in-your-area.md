---
title: "Hot ECR Reloading in Your Area"
tags: crystal
---

Everyone knows that ECR—the templating system built into the Crystal standard library—works at compile time, which makes it as efficient as writing to an `IO` manually. This is unlike other templating formats (usually in interpreted languages) like ERB (embedded Ruby) that parse and evaluate the template at runtime. This has the advantage of being able to change the template contents without stopping and restarting the program.

After I realised that ECR is [just a few classes in the standard library][html-ecr-templates] that are actually very easy to modify, I realised that I could get a lot of the runtime reloading advantages of ERB in ECR with some reasonably horrific hacks.

[html-ecr-templates]: /2025/11/13/html-safe-ecr-templates/

Firstly, I just want you to understand just how cool ECR is. I always assumed it was much more complicated than it actually is, I thought it did a full parse and had to understand the Crystal code within the tags, but it's actually much cleverer than that.

There isn't even a parser, there is [a lexer][ecr-lexer] and that goes straight into the code generator. No messing about.

[ecr-lexer]: https://github.com/crystal-lang/crystal/blob/1c72aa8f20d40bfdfed1324df35bb33419b774e1/src/ecr/lexer.cr

What happens is the lexer trundles along until it comes across an opening tag (either `<%`, `<%=`, or `<%-`). All the text before the tag is a single string literal token. It keeps looking at the code inside the tag until it gets to a closing tag (`%>` or `-%>`) and then the whole section of code is one single token. It keeps going like this until it gets to the end of the file.

The real magic happens in the code generator. The contents of the code blocks are effectively just dumped unmodified into the output, so if we have this ECR:

```
ECR solves at least <%= 1 << 10 %> problems
```

We get this code:

```crystal
io << "ECR solves at least"
(1 << 10).to_s io
io << " problems"
```

In this case the code section is just a single expression, so it's fairly straightforward. Surely though if we have control flow, or a block, we'd have to do something different? No! It just follows the same formula:

```
<% 10.times do |i| %>
 line number <%= i %>
<% end %>
```

Since Crystal doesn't rely on significant whitespace or anything, we can just pop the contents of each of those code blocks into the generated file:

```crystal
10.times do |i|
io << "line number "
i.to_s io
end
```

The ECR processor didn't need to know or care that `10.times do |i|` started a new block. If there was a mis-matching `end`, that would be picked up by the actual Crystal compiler when the generated code is compiled. Syntax errors appear as coming from the ECR file because there are annotations that map the expressions in the generated code to the corresponding line and column number in the ECR file.

Anyway, we can totally do this compile-time-only stuff at runtime. Well, not actually. But mostly.

The ECR file is basically just a series of string literals separated by code snippets. We can't change the code snippets at runtime, but the strings are fair game. I did wonder if you could do something where you wrap each code section in a `Proc` or conditional and if they get removed or re-ordered you could only evaluate the ones that remained in the file, but since they can have any inter-dependence (defining variables, etc) this would get very fragile very quickly. Although since like 95% of the time what I want to change is a misspelled HTML class attribute, being able to update the text content of the template is a huge improvement.

I wrote then re-wrote it a few times, and the end result is much simpler than I was expecting at the start. The most important thing is failing fast if the ECR file has changed in a way that we can't render it anymore. Any change to the actual code will invalidate the template and the code will have to be recompiled to pick up the changes.

[The processor][ecr-runtime-processor] that runs at compile time generates very similar code to the actual ECR processor. To check whether the code has changed, it builds a list of all the code snippets as strings. At the start of the generated code I call a helper method that takes this list, rereads the ECR file, and iterates through the tokens. If any code token is different or missing, the file has changed too much and we throw an exception. Otherwise we return a list of new strings that will replace the string literals. The generated code takes this list and inserts strings based on their index in the file (since that won't change, since we'll have failed already in that case).

[ecr-runtime-processor]: https://codeberg.org/willhbr/geode/src/commit/279e1a79730243d5c8880675db828c4707e67c4f/src/geode/html_safe_ecr/runtime_html_ecr_processor.cr

Here's the (slightly abridged) generated code for the ECR example above:

```crystal
strings = Geode::HTMLSafeECR::RuntimeLoader.get_strings(
  "test.ecr",
  [nil, " 1 << 10 ", nil]
)
io << strings[0]
(1 << 10).to_html io
io << strings[1]
```

The array passed to `get_strings` is generated from the original ECR file contents. Each `nil` is where there's a string literal—something that can be replaced—and every non-`nil` string is a bit of code that must remain in the altered ECR file.[^could-fail]

[^could-fail]: I should actually check the type of code block (whether it's output or control or whatnot) but I haven't been bothered yet.

On release builds, all this code is removed and I swap back over to the boring compile-time-only processor, so all of this nonsense disappears and it works just like a normal ECR.

I've added this to the HTML-safe ECR generator in [Geode](https://codeberg.org/willhbr/geode)—that I [wrote about the other day][html-ecr-templates]—and have also simplified that code a whole bunch by splitting out the HTML-generating code into `to_html`, which removed the need for the `Builder` wrapper and `unsafe_write` method entirely. This has simplified the model of composable components, meaning that any object can override `to_html` and be inserted into an ECR template with `<%= %>`, and the escaping (or lack thereof) will work as you'd expect. You can see [this commit in endash](https://codeberg.org/willhbr/endash/commit/c90f8ef235b6104dc8b93a24a08e8b880acfe729) as an example of swapping templates over to use this method.
