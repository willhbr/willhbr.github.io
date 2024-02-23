---
title: Basics of Functional Programming
---

As someone who enjoys learning new programming languages, it was only a matter of time before I came across functional programming languages, higher order functions, and the like. Earlier this year I found out that Java 8 now supports some functional programming and have been writing less boilerplate code ever since - much to the horror of my team mates. So this is for you, so you can hopefully understand my spaghetti of lambdas.

Functional programming is based around the idea of passing code around just like you would any other object. If you're into design patterns, it's like you're using a very loose version of the [Strategy pattern](https://en.wikipedia.org/wiki/Template_method_pattern) or the [Template pattern](https://en.wikipedia.org/wiki/Template_method_pattern). You provide a set of instructions that will be inserted into an existing algorithm or operation.

Most languages that support higher-order functions (functions that take code as a parameter) have three 'bread and butter' functions built-in: `map`, `filter`, and `reduce`. These simplify common list operations by abstracting away the boilerplate.

# Map

Let's say that I have a list of countries, and I want to present them to a user in a certain format. This is a faily common example where I have a list and I want to do an operation on each of its elements to produce a new list. You could say that there will be a _mapping_ from each element in the first list to the element in the second list. In first year you are told to do something like this:

```ruby
countries = # Some list of country objects
country_names = []
for country in countries
    country_names.push(country.name)
end
# Do something with the list of countries
```

However a far more succinct way of doing this is to map the list:

```ruby
countries = # some list of countries
country_names = countries.map { |country| country.name }
```

Both methods are doing the same thing, but (for someone who understands functional programming) the second is much clearer and reduces the amount of noise in the code. Of course the disadvantage is that it can hide potentially costly operations.

An important note with map is that the operation should affect the object that you are mapping. For example if you map the countries to get all their names, but also reset some attribute of the country - you're asking for problems in the future. If someone later decides that they only want to get the names of the first ten countries and you were relying on the fact that some other action is performed on all of them - problems are inbound.

# Filter

Filter treats your function like a sieve - everything that it accepts is let through, the rest is ignored. So in this case your lambda is taking an item and returning `true` if you want that item to make it through the sieve. Filter reduces even more boilerplate:

```swift
let numbers = [1, 2, 5, 6, 9]
var even_numbers = [Int]()
for number in numbers {
  if number % 2 == 0 {
    even_numbers.append(number)
  }
}
// Do something with the even ones
```

```swift
let numbers = [1, 2, 5, 6, 9]
let even_numbers = numbers.filter { number in number % 2 == 0 }
// Do something with the even ones
```

You can of course chain filter statements together, or include a few conditions - basically like an SQL `WHERE` clause. Filter is especially useful when you have a list of objects, and you want to get rid of the ones that are null.

# Reduce

When you have a list of items and want to distill it down to one object that represents some aspect of the whole list, reduce is what you're looking for. The lambda takes two arguments - the reduced list so far, and the item that you want to reduce 'into' this reduced form. Reduce also takes an intial value, which is what the reduced form should start off as. A great example is summing a list of numbers - the initial reduced form is `0`, and each time you want to add the current number to that.

```ruby
numbers = [1, 2, 3, 6, 7]
sum = numbers.reduce(0, { |so_far, number| so_far + number })
```

Reduce is hard to explain - mainly because I don't end up using it very often. Most languages include helpers for the common reduce operations: `join`, `sum`, and `product` are great examples. Each take a list and give you back a single value that is the combination of every item in the list.

> If you think about it, both map and filter can be implemented using reduce - making reduce the only list operation you really need. So really map and filter are just helpers the common cases of reduce.

# Let's make a lambda!

So with all this knowledge, how do you go about using it? Well...

In Ruby any method that accepts a block (Ruby has [lots of names](https://awaxman11.github.io/blog/2013/08/05/what-is-the-difference-between-a-block/) for it's anonymous functions) can be followed by a code block, either with `do ... end` or `{ ... }`

In Swift closures are a type (defined by their arguments and the type they return) and like ruby can either by inside the argument list, or after the function call if the argument is at the end.

Java doesn't really support lambdas. They are instead an anonymous implementation of an interface that has just one method. So a lambda that turns a country into a string of the country name is actually a an implementation of the generic interface `Function<T, R>`, (ie it's type is `Function<Country, String>`) and it has a method `R apply(T t)` that takes in a value of type T and returns a result of type R. The code in the lambda provides the implementation of this method.

All of the list operations are hidden in the `stream()` method on lists, as well as the `Steam.of()` method that can create a stream from an Array. To turn your stream back into a list, you'll want the `.collect(Collectors.toList())` method. So the country to coutry name would look something like:

```java
List<Country> countries = // Some list from somewhere
List<String> names = countries
    .stream()
    .map(country -> country.getName())
    .collect(Collectors.toList());
```

(Of course Java manages to still make a one line function into four)

## Method references

If you functionally program enough, there will be some boilerplate - like creating a lambda that just calls one method on an object. So you can often just refer to that method, rather than writing out the whole lambda declaration:

```java
(item) -> item.method()
// Can be replaced with
Item::method
```

```ruby
{ |item| item.method() }
# Can be replaced with
&:method
```

If you want to learn more functional programming, [Haskell](https://learnyouahaskell.com/chapters), [Clojure](https://clojure.org/) (Or [Common LISP](https://www.gigamonkeys.com/book/)), and [Elixir](https://www.manning.com/books/elixir-in-action) are all interesting.
