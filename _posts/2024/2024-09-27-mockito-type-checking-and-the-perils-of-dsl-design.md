---
title: "Mockito, Type Checking, and the Perils of DSL Design"
tags: languages design
---

So this one takes a bit of explaining but we'll get there in the end. The Mockito `when()` function has a really subtle trap that can lead to unexpected behaviour. For the longest time I thought it was because the authors wanted a slightly cleaner API, but after some more thought I realised that it's almost unavoidable. We'll get to that later, first let's get into the actual API.

The basic API for Mockito is super simple, you create a mock with `mock(MyClass.class)` and then you use a DSL to tell the mock how to act under certain conditions:

```java
ThingSizer myMock = mock(ThingSizer.class);
when(myMock.getThingSize()).thenReturn(ThingSize.LARGE);

System.out.println(myMock.getThingSize());
// => ThingSize.LARGE
```

It's that `when()` call that throws things off. It might look like you need to put the function call inside the brackets, but that's not how Java works. The only thing that `when()` receives is the result of the function call, allowing you to do this:

```java
ThingSize size = myMock.getThingSize();
when(size).thenReturn(ThingSize.LARGE);
```

The way this actually works is that every method call on a mock object is added to a global list, and `when()` just grabs the latest mock call (in this case that's `getThingSize()`) and attaches the provided return value for the next time that method gets called.

With that in mind, we don't even have to pass the result of the mock method call into `when()`, we just have to pass an object that matches the return type:

```java
myMock.getThingSize();
when(ThingSize.TINY).thenReturn(ThingSize.LARGE);

myMock.getThingSize();
// => ThingSize.LARGE
```

In this case it's pretty obvious that you're doing something wrong, but it's not hard to run into cases where the failure is much more subtle. Since that list of method invocations is global, it doesn't matter where it's called from, just as long as it's called before `when()`.

```java
ThingSize retrieveThingSizeFrom(ThingSizer sizer) {
  return sizer.getThingSize();
}

when(retrieveThingSizeFrom(myMock)).thenReturn(ThingSize.LARGE);
```

To a novice mockito-er, it looks like we're mocking the `retrieveThingSizeFrom()` method, but we're actually setting the mock behaviour on code that's _inside_ that method and it just happens to work because we call `getThingSize()` within `retrieveThingSizeFrom()`. Obviously a terrible thing to do would be:

```java
ThingSize getRandomThingSize(ThingSizer a, ThingSizer b) {
  if (Random.rand() < 0.5) {
    return a.getThingSize();
  } else {
    return b.getThingSize();
  }
}

ThingSizer mockA = mock(ThingSizer.class);
ThingSizer mockB = mock(ThingSizer.class);
when(getRandomThingSize(mockA, mockB)).thenReturn(ThingSize.LARGE);
```

There's a 50% chance that `mockA` will be configured, and a 50% chance that `mockB` will be configured. How do you end up with code like this in reality? It's easy—you just forget that an object isn't a mock.

Let's assume that this is setup in some test helper somewhere. `ProxySizer` wraps our `ThingSizer` and maybe does some additional checks or whatever.

```java
ThingSizer mock = mock(ThingSizer.class);
ProxySizer sizer = new ProxySizer(mock);
```

Later in our test we want to change what our proxy returns, so we do this:

```java
when(sizer.getThingSize()).thenReturn(ThingSize.LARGE);
```

And of course it works, despite `sizer` not being a mock. Since it proxies to an object that _is_ a mock, the only thing that matters is that the return types match up and `thenReturn` is able to grab the mock invocation from the global list. This becomes an even subtler trap to fall into when the return type is a primitive or another commonly-used type.

I've known about these failures for ages and I always thought it was just a poor API design choice that Mockito was stuck with. They decided on the `when` "DSL" syntax and then later realised that it had some pitfalls that users could fall into. My assumption was that you could just do:

```java
when(sizer).getThingSize().thenReturn(ThingSize.MEDIUM);
```

The `when()` call takes an object, validates that it's a mock, and returns a special type that lets you configure the mocking without relying on a global list of objects. I then actually sat down and thought about this some more—what would the type of that object be? [The signature for `when()` is][when-sig]:

[when-sig]: https://site.mockito.org/javadoc/current/org/mockito/Mockito.html#when(T)

```java
public static <T> OngoingStubbing<T> when(T methodCall)
```

It takes in the returned value (labelled somewhat dishonestly as `methodCall`) and uses generic type inference to return an `OngoingStubbing<T>` where `T` is the return type. This means that [`.thenReturn`][thenreturn-sig] can have a generic constraint such that any argument to it must be of type `T`. This is the only way to get some type safety when setting up the mock. If `when()` instead took the mock object as an argument instead of the return value, you wouldn't be able to return your `OngoingStubbing` object to be able to call `thenReturn`. The signature of `when()` would look like:

[thenreturn-sig]: https://site.mockito.org/javadoc/current/org/mockito/stubbing/OngoingStubbing.html#thenReturn(T)

```java
public static <T> MockConfigurator<T> when(T mock)
```

What methods would we add on that `MockConfigurator`? It's supposed to allow us to set the return values for different method calls, but we don't know the methods that are on `T` to be able to expose a compile-time DSL on the `MockConfigurator` object, we'd just get an error:

```java
when(sizer).getThingSize().thenReturn(ThingSize.MEDIUM);
           ^ Unknown method getThingSize() for MockConfigurator<ThingSizer>
```

Of course we could just use strings to match the method name at runtime (that's basically what's going to happen under the hood anyway):

```java
when(sizer).onCall("getThingSize").thenReturn(ThingSize.MEDIUM);
```

Although that means we just lost type checking on the method name _and_ the return type. We got rid of the global list of mocked method calls, at the cost of completely losing our type checking within a single method call. There's no nice way in Java for us to communicate the type information using generics.

You could make some steps forward by passing _both_ the mock and the method in the form of a lambda into the `when` call:

```java
public static <M, T> OngoingStubbing<T> when(M mock, Function<M, T> method)
```

With access to the mock that we're operating on, the `when()` method doesn't have to consult a global list of mock method invocations, it can interrogate the mock directly. By passing in a lambda that calls the method we want to mock, `when()` can interrogate the mock immediately after running the lambda. The downside is that this approach is much more verbose:

```java
when(mockSizer, m -> m.getThingSize()).thenReturn(ThingSize.LARGE);
```

Of course there's nothing stopping you running into all the same problems with proxy objects and suchlike as before, but at least now `when()` can check that the first argument passed is a mock, and that the lambda calls exactly one method on that mock.

This is a great example of where allowing succinct syntaxes can allow for better APIs and better code. In Swift with a [`KeyPath`](https://developer.apple.com/documentation/swift/keypath) or an `@autoclosure` you could reduce the boilerplate on the `when()` call:

```swift
// With a KeyPath
when(mockSizer, \.thingSize).thenReturn(.large)
// With an @autoclosure
when(mockSizer, mockSizer.getThingSize()).thenReturn(.large)
```

`KeyPath` can only reference a property, so you'd have to allow both of these approaches, and there's always the possibility that someone passes two mocks in, which you'd have to handle:

```swift
when(mockA, mockB.getThingSize()).thenReturn(.medium)
```

Of course, if you were doing this in Swift you'd want to use a macro that can actually introspect on the method call passed to `when()` (I'd give you an example but I don't know anything about Swift macros).

What have I learnt? DSL design in languages like Java with fewer bells and whistles is really tricky, and there's probably a good reason that an API is designed a particular way. If I find you setting mock behaviour implicitly via a method call on a real object that proxies to a mock, you can expect a slightly passive-aggressive code review coming your way.
