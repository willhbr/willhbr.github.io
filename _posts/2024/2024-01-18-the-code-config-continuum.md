---
title: The Code-Config Continuum
tags: design languages
---

At some point you've probably written or edited a config file that had the same block of config repeated over and over again with just one or two fields changed each time. Every time you added a new block you'd just duplicate the previous block and change the one field. Maybe you've wished that the application you're configuring supported some way of saying "configure all these things in the same way".

What this is exposing is an interesting problem that I'm sure all sysadmins, devops, SREs, and other "operations" people will appreciate deeply:

Where should something sit on the continuum between config and code?

This follows on from the difficulty of [parsing command-line flags](/2023/11/12/parsing-flags-is-surprisingly-hard/). Once your application is sufficiently complex, you'll either need to use something that allows you to write the flags in a config file, or re-write your application to be configured directly from a config file instead of command-line arguments.

The first logical step is probably to read a JSON file. It's built-in to most modern languages, and if it's not then there's almost certainly a well-tested third-party library that does the job for you. You just need to define the shape of your config data structure (please define this as a statically-typed structure that will fail to parse quickly with a good error message, rather than just reading the config file as a big JSON blob and extracting out fields as you go, setting yourself up for a delayed failure) and you're all set.

This file will inevitably grow as more options and complexity are added to the application, and at some point two things will happen: firstly someone who hasn't dealt with tonnes of JSON will ask why they can't add comments into the config file, and someone will write a script that applies local overrides of configuration options by merging two config files to allow for easier development for a local environment.

To remedy the first issue you could probably move to something like YAML or TOML. Both are designed as config-first rather than object-representation-first, and so support comments and some other niceties like multi-line strings.

If you stuck with JSON or chose to use TOML, you'll soon end up with another problem: you need to keep common sections in sync. Say you have something like a set of database connection configs, one for production and one for development (a good example is a Rails `database.yml` file). You want to keep all the boring bits in sync so that development and production don't stray too far from one another.

I run into this with my [`pods.yaml` config files](https://pod.willhbr.net). The program I wrote to [track helicopter movements around the Sydney beaches](/2023/07/29/helicopter-tracking-for-safer-drone-flights/) has five different container configurations that I can run, all of them need the a handful of common flags:

```yaml
flags:
  timezone: Australia/Sydney
  point_a:
    lat: -34.570
    long: 152.397
  point_b:
    lat: -32.667
    long: 149.469
  http_timeout: 5s
```

If this was JSON or TOML I would have to repeat that same block of config five times, and if I ever changed the area I was scanning, I would have to remember to update each place with the same values.

However, YAML is a very powerful config language; you can capture references to parts of the config and then re-use them in other parts of the file:

```yaml
flags: &default-flags
  timezone: Australia/Sydney
  point_a:
    lat: -34.570
    long: 152.397
  point_b:
    lat: -32.667
    long: 149.469
  http_timeout: 5s

containers:
  my-container:
    name: test-container
    flags:
      <<: *default-flags
  my-other-container:
    name: second-test-container
    flags:
      <<: *default-flags
```

Here I use `default-flags` to set the `flags` attribute of both containers to the exact same value.
{:class="caption"}

This is quite powerful and very useful, but there are still plenty of things that you can't express: mathematical operations, string concatenation, and other data transformations. I can't redefine how I write the configuration to be completely different to what the program that's parsing the YAML expects.

```yaml
# Reference a field, and transform it
field: new-$another_field
# Grab an environment variable
field: $USER
# Do some arithmetic using a field
field: 2 * $other_field
# A simple conditional
field: $PRODUCTION ? enabled : disabled
```

Some things that you can't do in YAML.
{:class="caption"}

That being said, YAML is far from simple:

> The YAML spec is 23,449 words; for comparison, TOML is 3,339 words, JSON is 1,969 words, and XML is 20,603 words.
> Who among us have read all that? Who among us have read and understood all of that? Who among us have read, understood, and remembered all of that?
> For example did you know there are nine ways to write a multi-line string in YAML with subtly different behaviour?
>
> —[Martin Tournoij: _YAML: probably not so great after all_](https://www.arp242.net/yaml-config.html)

YAML is full of surprising traps, like the fact that the [presence or absence of quotes around a value changes how it is parsed](https://github.com/crystal-lang/crystal/pull/13546) and so the [country code for Norway gets parsed as the boolean value `false`](https://www.bram.us/2022/01/11/yaml-the-norway-problem/).

Even if you decide that the power of YAML is worth these costs, you're still going to run into a wall eventually. [`noyaml.com`](https://noyaml.com/) is a good entrypoint to the world of weird YAML behaviour.

As your application becomes more complex—or as the interdependence of multiple applications becomes more complex—you'll probably want to split the config into multiple files[^complex-applications].

[^complex-applications]: I can imagine a student or junior developer reading this and thinking "when would your configuration ever get too big for one file?". Trust me, it does.

A classic example would be doing something like putting all the common flags that are shared between environments in one file, and then the development, staging, and production configurations each in their own file that reference the common one. YAML has no way of supporting this, and so you'll end up writing a program that either:

- concatenates multiple YAML files before sending them to the application to be parsed
- parses a YAML file and reads attributes in it to define a rudimentary `#include` system
- generates a single lower-level YAML config file that is given to the application based on multiple higher-level config files

And of course whichever option you chose will be difficult to understand, error-prone, hard to debug, and almost impossible to change once all it's idiosyncrasies are being relied upon to generate production configuration.

The sensible thing to do—of course—is to use an existing configuration language that is designed from the ground up for managing complex configuration, like [`HCL`](https://github.com/hashicorp/hcl). HCL is a language that has features that look like a declarative config ("inspired by [libucl](https://github.com/vstakhov/libucl), [nginx configuration](http://nginx.org/en/docs/beginners_guide.html#conf_structure), and others") but is basically a programming language. It has [function calls](https://developer.hashicorp.com/terraform/language/expressions/function-calls), [conditionals](https://developer.hashicorp.com/terraform/language/expressions/conditionals), and [loops](https://developer.hashicorp.com/terraform/language/expressions/for) so you can write an arbitrary program that translates one config data structure into another before it gets passed to an application.

This is all very good, but now you've got another problem: you need to learn and use another programming language. At some point you're going to say "why doesn't this value get passed through correctly?" and the solution will be to _debug your configuration language_. That could involve using an actual debugger, or working out how to `printf` in your config language.

Chances are pretty high that you're not very good at debugging this config language that you don't pay much attention to, and the tooling for debugging it is probably not as good as a "real" programming language that's been around for 29 years.

If you've done any [Rails](https://rubyonrails.org) development, then you've come across Ruby-as-config before. Ruby has powerful metaprogramming features that make writing custom DSLs [fairly simple](https://www.toptal.com/ruby/ruby-dsl-metaprogramming-guide), and the Ruby syntax is fairly amenable to being written like a config language. If there is a problem with the config then you can use familiar Ruby debugging tools and techniques (assuming you have some of those), but the flip side is that the level of weird metaprogramming hacks required to make a configuration "readable"—or just look slick—are likely outside of the understanding of anyone not deeply entrenched in weird language hacks.

Of course you're free to choose whichever language you like, they're all fairly capable of taking some values and translating them to a data structure that the end application can ingest. You could even write your config in Java.

There are a lot of additional benefits to using a real programming language to write your configuration. As well as abstracting away configuration details, you can add domain-specific validation that doesn't need to exist in the application (perhaps enforcing naming conventions just for your project), or dynamically load config values from another source—perhaps even another config file—before they are passed into the application.

The next iteration is when the config continues to increase in complexity[^more-complex], and so you decide to make some kind of tool that helps developers make common changes. Adding and removing sections is the obvious use-case. Strictly speaking it doesn't have to be due to the config being complex, it could just be that you want some automated system to be able to edit the files.

[^more-complex]: It'll happen to you one day!

Your problem is that you have no guarantees about the structure of the config. Since it's a general-purpose programming language, details could be scattered anywhere throughout the program. With JSON, it's super easy to parse the file, edit the data, and write a well-formatted config back out—you just have to match the amount of indentation and ideally the order of keys too. Doing this for most programming languages is much more difficult (just look at the [work that has gone into making `rubyfmt`](https://github.com/fables-tales/rubyfmt)).

Even if you can parse and output the config program, the whole point of using a general-purpose language was to allow people to structure their configs in different ways, so to make a tool that is able to edit their configs, you're going to have to enforce a restricted format that is easier for a computer to understand and edit.

So if you've got an application that expects a config file with hostnames and ports in a list, something like this:

```json
[
  {
    "hostname": "steve",
    "port": 4132
  },
  {
    "hostname": "brett",
    "port": 5314
  },
  {
    "hostname": "gavin",
    "port": 9476
  }
]
```

The simplest translation to a Ruby DSL could look like:

```ruby
[
  host {
    hostname "steve"
    port 4132
  },
  host {
    hostname "brett"
    port 5314
  },
  host {
    hostname "gavin"
    port 9476
  }
]
```

If someone was deploying this to a cloud service, they might not want to write all that out, so their config might look like:

```ruby
zones = ["us-east-1", "us-west-2", "au-east-1", ...]
STANDARD_PORT = 4123

zones.map do |zone|
  host {
    hostname "host-#{zone}"
    port STANDARD_PORT
  }
end
```

A program that has to edit these files to "add a new host" basically has to understand the intent behind the whole file[^maybe-llm]. This is an exceptionally difficult job. I read a book about robots as a child that likened computer speech to squeezing toothpaste out of a tube, and speech recognition to pushing the toothpaste back into the tube. Creating the config is like squeezing the toothpaste, having a computer edit the config is like putting the toothpaste back.

[^maybe-llm]: Maybe an LLM could get us there most of the time?

There are two paths you can take from here: double down on the programming language and build higher-level abstractions over the existing config to remove the need for the computer to edit the files, or move towards stricter formats for config files to allow computers to edit them.

You're being forced to pick a position on the code-config continuum, between something that's bad for people but good for computers, and something that's better for people and bad for computers. There's no right answer, and every option trades off between the two ends of the spectrum.
