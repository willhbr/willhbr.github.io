---
title: "Building Dependency Injection with Crystal Macros"
tags: crystal languages
---

When I first came across dependency injection I was a sceptic. Surely we could just create objects the normal way instead of worrying about modules and bindings? Eventually though I realised how you're actually just generating the boilerplate code that you'd need to pass the dependencies around manually, and writing that code yourself is a huge waste of time.

I then wondered how hard it would be to implement the whole thing using Crystal macros. The aim is to have all the dependency resolution happen at compile time, so any failures to find a dependency will result in a compilation failure, and you're not paying the price of a hash lookup or something similar to find each dependency during construction.

# Dependency Model

The model I've implemented is based on [Dagger](https://dagger.dev) (and its cousin, Hilt) since that's what I've used the most. How Dagger works is that every injectable type is "installed" in a component, and can access any dependency from that component or its parent component. In a Hilt Android app, this means that a dependency in the `ActivityComponent` can inject something from the `SingletonComponent`, but not the other way around.

Each injectable type also has a policy of whether a new object should be created each time, or whether Dagger should hold on to the object and share it between dependent classes. In Dagger these are "scopes" which everyone gets confused about because `ActivityScope` and `ActivityComponent` seem like they should be the same thing, but `ActivityScope` just says to keep the object for the life of the activity, and can only be used on dependencies in the `ActivityComponent`. The equivalent for `SingletonComponent` is just `Singleton`, which is confusing because it is a scope, but it's not named that way.

I decided to not match the nomenclature and invent my own terminology. Each collection of dependencies is a _scope_, which may have a parent scope (and the parent scope may also have its own parent). Every injectable type must have either a `@[Retain]` or `@[Recreate]` annotation that denotes whether it should be held onto or not.

What I like about this model is that you are effectively adding some lifetimes to objects in a language that doesn't actually support them.

# Implementation

The first trick that makes this whole thing work is defining the scopes as classes. They could be defined by annotations or just instances of a single `Scope` class, but as you'll see later this lets us trick the compiler into validating our dependency resolution at compile time for us. Doing that would be much harder if the scopes were defined another way.

In a simple HTTP server, we might have scopes that look like this:

```crystal
class GlobalScope < Scope
end

class RequestScope < SubScope(GlobalScope)
end
```

`GlobalScope` holds everything that is accessible anywhere in the application and lives until the process exits, then `RequestScope` holds things that are only relevant to a single incoming request and will be discarded once it has been handled.

Don't worry about `SubScope`—we'll get to that later.

Now the main thing we need is to generate the code that builds our object and its dependencies. There are a few ways of defining the macro to do this—you could define a macro on a module and call that from inside the class—but what I ended up doing was creating a generic module with [an `included` hook][crystal-hooks]. The actual code looks like this:

[crystal-hooks]: https://crystal-lang.org/reference/latest/syntax_and_semantics/macros/hooks.html

```crystal
class RequestProcessor
  include Injectable(RequestScope)

  ...
end
```

Using a generic module means that at compile time we have access to `T`—the type of the scope—and `@type`—the class we're building the injector for. Other approaches could get the same thing, but it fits really nicely with the generic module.

In the module we define a hook:

```crystal
module Injectable(T)
  macro included
    ...
  end
end
```

The macro hook is invoked immediately on `include`, but we can do the classic trick of defining a `finished` macro _inside_ that macro that calls another macro. That way we can run code after the whole class has been defined.

{% raw %}
```crystal
macro included
  {% verbatim do %}
    macro finished
      build_injector
    end
  {% end %}
end
```
{% endraw %}

I've written so many macros that I don't even hesitate at the idea of a macro defining a macro that calls a macro. That's just how I write code.

That `build_injector` macro does the actual work to generate the code. This happens in a few stages; I didn't want to be overly prescriptive on which method would be called for injection, so you have to annotate it with `@[Inject]`, which means we first need to find the right method. This is a bit clumsy in a macro:

{% raw %}
```crystal
{% method = nil %}
{% for m in @type.methods %}
  {% if m.annotation(Inject)
       unless method.nil?
         method.raise "multiple @[Inject] methods: #{m.name} and #{method.name}"
       end
       method = m
     end %}
{% end %}

{% if method.nil?
     @type.raise "no @[Inject] annotated method on #{@type}"
   end %}
```
{% endraw %}

After that we have `method`, which is a [`Def`][macros-def] object. Looking at the arguments to a particular method is easier than trying to process instance variables, and only doing constructor injection instead of field injection (in Dagger parlance) gives a bit more flexibility to the class.

[macros-def]: https://crystal-lang.org/api/latest/Crystal/Macros/Def.html

The next trick is to use the unsafe `.allocate` method to grab some uninitialised memory where we can put our object. We then just call the right `initialize` method (as defined by `method`) which will set the instance variables. That's just a matter of generating a method call from the information in `method`:

{% raw %}
```crystal
instance = {{ @type }}.allocate

instance.{{ method.name }}(
  {% for arg in method.args %}
    {{ arg.restriction }}.inject(scope),
  {% end %}
)
```
{% endraw %}

This can be a bit hard to parse, so let's look at an example. If we have this class:

```crystal
class RequestProcessor
  include Injectable(RequestScope)

  @[Inject]
  def initialize(
    @params : URI::Params,
    @context : HTTP::Context,
  )
  end
end
```

Then the generated `inject` method would look like this:

```crystal
def inject(scope)
  instance = RequestProcessor.allocate

  instance.initialize(
    URI::Params.inject(scope),
    HTTP::Context.inject(scope),
  )
  return instance
end
```

Note that `@type` is expanded to `RequestProcessor` in the macro.

Now, this doesn't actually work because we need to be able to retain objects in the scope, so that if they're injected in two places, both will get the same instance. What we've got currently will just make a new instance of every object every time anything is injected, which isn't very useful.

In this `inject` method the initial change is quite simple; instead of calling the `inject` method on each class to create an argument, read it from the scope—that's why we have the scope in the first place. We'll assume that the scope has a `.get` method, and the change is fairly simple:

{% raw %}
```crystal
instance = {{ @type }}.allocate

instance.{{ method.name }}(
  {% for arg in method.args %}
    scope.get({{ arg.restriction }}),
  {% end %}
)
```
{% endraw %}

The problem is that we now have to go and write that `.get` method. Working out how to do this took some serious head scratching. The problem is that we need to generate some code that will look at the type that's passed in, find out if it should be recreated or retained (and whether there's an existing retained instance), then return the retained instance or create a new one.

Perhaps the most naïve way of doing this would be to have a `Hash(Class, Object)` that stores the objects, but Crystal doesn't support using `Class` _or_ `Object` as type constraints for instance variables, so that's not an option.

I fiddled around with trying to do horrible unsafe things with `pointerof()` but that didn't really get anywhere because even if I can store pointers to objects, I still need to know if I even need to store them in the first place.

I even thought about calling a specially-formatted method that would be handled by [`method_missing`][crystal-hooks], parsed back into a type, and somehow worked it out from there.

In the end the solution was much simpler; all it took was a realisation of how redefining classes and namespaces work.

If you do this in Crystal, you will add a new method to the `String` class:

```crystal
class String
  def sup
    "Sup, #{self}"
  end
end
```

But if you do this, you will define an entirely new class called `Geode::String` that is unrelated to the top-level `String` class:

```crystal
module Geode
  class String
    def sup
      "Sup, #{self}"
    end
  end
end
```

That works the same if `Geode` is a module, class, or struct.

I thought that because my macro was generating code that lived inside the to-be-injected class, I couldn't patch new methods into other classes, so I couldn't define a new field on `RequestScope` from within that macro.

In Crystal every type is resolved relative to the current module or class, so within `Geode` if you wrote `String` you'd get your custom class, not the actual string class. If you want to be unambiguous, you can prefix the type with double colons to turn it into an absolute path (just like in C++). So in `Geode` you can use `::String` to refer to the actual string class.

What I didn't realise is that you can do this same thing when you're patching a class. So from within one class, you can patch a class in an outer module just by passing an absolute path. Since we have the type of the scope in our generic module as `T`, we can patch the class like this:

{% raw %}
```crystal
class ::{{ T }}
  {% if @type.annotation(::Retain) %}
    @var_{{ @type.id }} : {{ @type }}? = nil

    def get_{{ @type.id }} : {{ @type }}
      @var_{{ @type.id }} ||= {{ @type }}.inject(self)
    end
  {% else %}
    def get_{{ @type.id }}
      {{ @type }}.inject(self)
    end
  {% end %}
end
```
{% endraw %}

This checks whether our type needs to be retained, then either generates an instance variable and getter method, or just a getter method.

The getter method will be named something like `get_RequestProcessor`. I didn't include it in the example, but since we can have generic types or types nested in modules, we actually need to strip any special characters out of the type name, like this: `@type.stringify.gsub(/[():]/, "_").id`. Since Crystal macros don't have methods, every time we want to access the specially-named getter, we have to duplicate that snippet.

Now we're able to store the object, and we've got a method to access it, but we still don't have our `.get` method. This requires another few tricks that will interact with our specially-named method.

[Macro methods][macro-methods] get instantiated separately for every type that calls them—at least conceptually. We can capture that type in a generic parameter and then call `{% raw %}.get_{{ T.id }}{% endraw %}` to either get the retained instance or a new object:

[macro-methods]: https://crystal-lang.org/reference/latest/syntax_and_semantics/macros/macro_methods.html

{% raw %}
```crystal
def get(cls : T.class) : T forall T
  {% begin %}
    {% name = T.stringify.gsub(/[():]/, "_") %}

    {% if @type.has_method? "get_#{name.id}" %}
      self.get_{{ name.id }}
    {% else %}
      {% T.raise "#{T} not registered in #{@type}" %}
    {% end %}
  {% end %}
end
```
{% endraw %}

I'm actually combining this with `has_method?` in order to fail with a more sensible error message. This is how the compiler is tricked into doing our dependency resolution at compile time: it needs to generate all the instantiations of this `.get` method, and if it can't call the right getter, then we've got an object that can't be constructed through dependency injection.

Although that's still only half the story. I promised earlier that I'd get to `SubScope(T)`, and this is where that comes in. Since scopes are organised in a hierarchy, in order to have the compiler do type checking, that hierarchy needs to be represented in the type system. By making `SubScope(T)` a generic class, the child scope can have a concrete reference to its parent type, and the fallback `.get` method call is directly on the parent scope type, rather than being a dynamic dispatch on the `Scope` superclass.

That's a lot to take in, so here's the code then we can go through an example.

{% raw %}
```crystal
def get(cls : T.class) : T forall T
  {% begin %}
    {% name = T.stringify.gsub(/[():]/, "_") %}

    {% if @type.has_method? "get_#{name.id}" %}
      self.get_{{ name.id }}
    {% else %}
      @parent.get(cls)
    {% end %}
  {% end %}
end
```
{% endraw %}

Let's say we have `RequestLogger` which is in `RequestScope`, and `Logger` which is in `GlobalScope`. `RequestLogger` injects the `Logger`. How does that dependency get resolved?

The `Injectable(T)` module macro will generate the `inject` method, which will build the call to `initialize`:

```crystal
def inject(scope)
  instance = RequestLogger.allocate

  instance.initialize(
    scope.get(Logger),
  )
  return instance
end
```

In this method, `scope` is a `RequestScope`. The Crystal compiler sees that we've called `.get` with a parameter of type `Class(Logger)`, and it generates a new specialisation of that method for us, and runs our macro code in that method.

The `@type.has_method?` check returns `false`, since `Logger` is registered in the `GlobalScope`, and so there's no `get_Logger` method patched into the `RequestScope`. The code generated for `.get` looks like this:

```crystal
def get(cls : Logger.class) : Logger
  @parent.get(Logger)
end
```

`@parent` is defined in the initialiser for `SubScope(S)` as being of type `S`:

```crystal
class SubScope(S) < Scope
  def initialize(@parent : S)
  end
end
```

Since `RequestScope` inherits from `SubScope(GlobalScope)`, the compiler knows that `@parent` _must_ be a `GlobalScope`, and so it knows it needs to create a specialisation on that type to satisfy this `.get(Logger)` call.

In this case, `GlobalScope` is a regular `Scope` and so the generated method is slightly different. It does the check for whether there's a `get_Logger` method defined—in this case there is, so it will delegate to that. If there wasn't, then it will raise an exception and compilation will fail.

If we put enough `@[AlwaysInline]` annotations on these methods, then the `get(Logger)` call in `RequestLogger` _should_ be able to skip right to reading the field from whichever scope holds the logger, without doing any method dispatches. Talk about zero-cost abstraction.

# `Provider` and `Lazy`

Any good dependency injector will know you can't inject dependencies without deferring their construction in some cases. This lets you do something like:

```crystal
class MyFeature
  include Injectable(GlobalScope)

  @database : Database

  @[Inject]
  def initialize(
    config : Config,
    old_database : Provider(OldDatabase, GlobalScope),
    new_database : Provider(NewDatabase, GlobalScope)
  )
    if config.use_new_database?
      @database = new_database.get
    else
      @database = old_database.get
    end
  end
end
```

The implementation for these is fairly straightforward:

```crystal
struct Provider(T, S)
  def self.inject(scope : S)
    new(scope)
  end

  def initialize(@scope : S)
  end

  def get
    @scope.get(T)
  end
end
```

The biggest challenge here was that originally I didn't have them being generic over the scope, which meant the type of `@scope` was `Scope+` (any `Scope` subclass), and when the `get(T)` method was instantiated, it would be instantiated on the top-level class, which wouldn't have the special getter method defined, and the dependency resolution would fail. Making them generic on the scope adds a bit of complexity, but it's necessary to have the resolution work at compile time.

Both of these classes have to be special-cased into the construction of the objects, which is a little messy. The actual call to the `initialize` method looks like this:

{% raw %}
```crystal
instance.{{ method.name }}(
  {% for arg in method.args %}
    {% if arg.restriction.nil?
         arg.raise "needs restriction on #{arg}"
       end %}
    {% if arg.restriction.resolve?.nil?
         arg.raise "Unable to resolve #{arg.restriction}"
       end %}

    {% if arg.restriction.resolve? < Provider %}
      {{ arg.restriction }}.inject(scope),
    {% elsif arg.restriction.resolve? < Lazy %}
      {{ arg.restriction }}.inject(scope),
    {% else %}
      scope.get({{ arg.restriction }}),
    {% end %}
  {% end %}
)
```
{% endraw %}

This will always create a new `Provider` or `Lazy` instance (neither wrapper type should be retained) and then the actual object creation is done in `Provider#get` and `Lazy#get`, which call `@scope.get(T)`.

# `PartialInjectable`

The other classic dependency injection pattern is a class that has some fields injected, and some fields passed in explicitly. Usually this is done by generating a factory class, which is exactly what I did. It was quite satisfying to be able to generate code that would invoke the macro that I'd just written to then generate more code, and have it all fit together.

The macros are fairly similar to the rest, it just generates an inner struct named `Factory` and uses the [`splat_index`](https://crystal-lang.org/api/latest/Crystal/Macros/Def.html#splat_index:NumberLiteral%7CNilLiteral-instance-method) to differentiate between injected arguments and regular arguments. The injected arguments are each automatically wrapped in a `Provider`, so that the dependencies are only resolved when `new` is called on the factory.

# Qualifiers

If you want to inject two objects of the same type in Dagger [you can use annotations][qualifiers] to differentiate them. I thought about using annotations in Crystal to do the same thing, but decided against it as it would be a bunch more work and complexity. Instead you can implement a single-field struct that wraps the type you want to duplicate—I even made a convenient macro for it.

[qualifiers]: https://dagger.dev/semantics/#keys

# Scope Parameters

For subscopes that correspond to a particular action (like an HTTP request) you need to be able to put values into the dependency graph. In terms of code, this is as simple as defining the right method on the scope so that the `has_method?` check in the `get` macro method will find it.

I made a macro that helps defining these, since writing them manually would be messy.

```crystal
class RequestScope < SubScope(GlobalScope)
  params [
    context : HTTP::Server::Context
  ]
end
```

Then when you make the scope, you pass in the parameters: `global.new_request_scope(context: context)`. These will then be available to inject to any class in that scope.

# Using it

Here's a somewhat contrived, overly simple example of where this might be useful. We've got two scopes just like the rest of the post, a global config, and a processor that is only used for one request.

Here are the scopes and config:

```crystal
class AppConfig
  getter do_stuff : Bool
end

class GlobalScope < Scope
  params [
    config : AppConfig
  ]
end

class RequestScope < SubScope(GlobalScope)
  params [
    context : HTTP::Server::Context
  ]
end
```

Here's the actual interesting stuff. What's neat is that we don't have to plumb `Logger` or `AppConfig` into the `Handler`, and if we decide that `Logger` should be request-scoped in order to log with embedded request information, we can just move it into that scope and not have to do all the rewiring.

```crystal
@[Retain]
class RequestProcessor
  @[Inject]
  def initialize(
    @context : HTTP::Server::Context,
    @logger : Logger,
    @config : AppConfig
  )
  end

  def process
    @logger.log { "Processing request!" }
    ...
    if @config.do_stuff
      write_data(@context)
    end
  end
end

@[Retain]
class Handler
  include HTTP::Handler

  @[Inject]
  def initialize(@global : GlobalScope)
  end

  def call(context)
    req_scope = @global.new_request_scope(context: context)
    processor = req_scope.get(RequestProcessor)
    processor.process
  end
end
```

Now we just need to set up the application by loading the config, creating the root scope (and passing the config in), and starting our server. The server could also be constructed by dependency injection if we really wanted.

```crystal
config = Config.load_from_file

global_scope = GlobalScope.new(config: config)
server = HTTP::Server.new [global_scope.get(Handler)]
server.bind_tcp "0", 80
server.listen
```

# But Why

Surprisingly I didn't do this _entirely_ for my own amusement, I did actually have a use case that dependency injection would have made easier. I made some changes to [my SSH honeypot][ssh-honeypot] that I wrote years ago so that instead of just logging the commands, it would run them in a container. It would hash the username, password, and remote address to create a container name so that repeated connections would be run in the same container.

[ssh-honeypot]: https://codeberg.org/willhbr/ssh-honeypot

I then wanted to change this so that I could optionally share containers based on some logic. I would usually do this by having a `ContainerDispatcher` or something that would be owned by the SSH server, and pass a reference to it to each `PodmanConnection` when a client was connected. The `PodmanConnection` would ask the dispatcher for a container, and since it would have visibility into all running containers, it could return an existing one or create a new one.

This is a tiny microcosm of where dependency injection is useful. The connection should exist in its own scope, and request a dispatcher from _somewhere_. It doesn't care if that dispatcher is in the same scope or in the parent scope—it just says "give me the thing that will let me get containers". The SSH server doesn't really need to know that the dispatcher should be shared among all connections, it doesn't even really need to _know_ about dispatching between containers at all.

I know dependency injection is a hallmark of over-architected enterprise software, but in cases like these I think it's a useful tool.

You can see the [full implementation](https://codeberg.org/willhbr/geode/src/branch/main/src/geode/dependency_injector.cr) in [Geode](https://codeberg.org/willhbr/geode). If I end up using this in my projects, no doubt I'll make some changes as I find pain points and other shortcomings.
