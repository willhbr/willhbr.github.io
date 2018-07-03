---
title: More Fun With Generics in Kotlin
layout: post
date: 2017-05-23
---

Android now supporting Kotlin means more people playing around with it. [Ben Trengrove](https://bentrengrove.com) is one of them - [he has made](https://bentrengrove.com/blog/2017/5/21/fun-with-types-extensions-and-generics-in-kotlin) a quite neat way of representing units in a type-safe wrapper. This disallows doing operations on two units of different measurements - for example speed cannot be added to a distance. Adding helper extensions to numeric types allows you to use it like this:

```kotlin
val distance = 21.kilometers

// This is OK because they are both distances
println(distance + 5.miles)

// This fails because you can't add distance to time
println(distance + 9.minutes)
```

You can have a look at Ben's code [here](https://gist.github.com/bentrengrove/9759a3fbb564d62e1e63f417c58a3895). Currently Ben's code allows you to multiply one quantity by another. The result is a quantity with the same unit of the operands passed to the multiplication. This doesn't follow the rules of [dimensional analysis](https://en.wikipedia.org/wiki/Dimensional_analysis) - if a distance is multiplied by another, the result not a distance, it's a 2D area.

What this means is that you can do code like this:

```kotlin
val width = 10.meters
val height = 5.meters

// Area has unit Distance.Meter, not meters squared
val area = width * height
```

This piqued my interest - how could you implement units like speed and area, that are composed of multiple units? Of course you could just remove the `.div` and `.times` methods and replace them with extension functions that return a `Quantity<Speed>` or `Quantity<Area>` for each combination of units that you're interested in.

But surely we can do better? This is what I set out to do, I wanted to be able to define the [base units](https://en.wikipedia.org/wiki/SI_base_unit) and derive every other unit from them. If you want to skip the rambling, you can check out the [end result here](https://gist.github.com/javanut13/424f33324588107ee59d4b1ae929843d).

----

The premise of this approach is to make two new subclasses of `Unit`[^all-objects] that each have two generic constraints - each of which must also be a type of `Unit`. These represent a division type and a multiplication type, `QuotientUnit` and `ProductUnit`. All units have a suffix attribute that stores the standard identifier for that type (like "m" for meters, "s" for seconds, etc). `QuotientUnit` and `ProductUnit` create their suffix from the suffixes of their parts with either "/" or "." inbetween.

[^all-objects]: When implementing this, my first idea that turned out to be a dud was to make every different measure a Kotlin `object`. This did mean that the types could be part of generic constraints, so `QuotientUnit<Kilometer, Second>` is a valid type. This seemed like a good idea initially, but quickly ended when I realised that `QuotientUnit<Mile, Second>` is a different type to `QuotientUnit<Kilometer, Minute>` - even though they both represent `distance/time`.

The basic units are still defined in a similar way: [^no-prefix]

[^no-prefix]: In my examples I omit the prefix of the base type (eg `Distance.`) for readability. You can import them directly which allows you to use units with no prefix (eg `Metre`) or just import the class and access the companion variables (eg `Distance.Metre`).

```kotlin
abstract class Unit(val suffix: String, val ratio: Double) {
  internal fun convertToBaseUnit(amount: Double) = amount * ratio
  internal fun convertFromBaseUnit(amount: Double) = amount / ratio

  override fun toString() = suffix
}

open class Distance(suffix: String, ratio: Double): Unit(suffix, ratio) {
  companion object {
    val Mile = Distance("mi", 1.60934 * 1000.0)
    val Kilometer = Distance("km", 1000.0)
    val Meter = Distance("m", 1.0)
    val Centimeter = Distance("cm", 0.1)
    val Millimeter = Distance("mm", 0.01)
  }
}
```

The implementation of the composite units looks like this: [^Unit-toString]

[^Unit-toString]: I've changed my `Unit` class to have a `.toString` method that simply returns the suffix, differing slightly from Ben's original version.

```kotlin
class QuotientUnit<A: Unit, B: Unit>(a: A, b: B):
    Unit("$a/$b", a.ratio / b.ratio)
class ProductUnit<A: Unit, B: Unit>(a: A, b: B):
    Unit("$a.$b", a.ratio * b.ratio)
```

They are really just a placeholder to keep the type system in check. We can then use these to extend our `.div` and `.times` methods to return quantities with composite types. So inside the Quantity class we add:

```kotlin
operator fun <R: Unit> div(quantity: Quantity<R>): Quantity<QuotientUnit<T, R>> {
  return Quantity(amount / quantity.amount, QuotientUnit(unit, quantity.unit))
} 
operator fun <R: Unit> times(quantity: Quantity<R>): Quantity<ProductUnit<T, R>> {
  return Quantity(amount * quantity.amount, ProductUnit(unit, quantity.unit))
} 
```

So now when we divide a distance in kilometers by a time in hours, we get a `QuotientUnit<Distance, Time>` with a suffix of "km/h":

```kotlin
val distance = 21.kilometers
val time = 1.5.hours
println("Speed is: ${distance / time}") // Speed is: 14 km/h
```

And we should be able to do conversions between composite units as well, because the ratio of a composite unit is calculated based on the original units.

```kotlin
val speed = 21.kilometers / 1.5.hours
val milesPerHour = speed.to(QuotientUnit(Mile, Hour))
println("Speed is $milesPerHour") // Speed is 8.7 mi/h
```

Now that's quite useful. However typing `QuotientUnit(Mile, Hour)` is not very elegant. Perhaps we can use some helper function to make this a bit more readable?

We can actually do better than a helper function, instead we can make an extension operator that defines `/` and `*` on pairs of units. This lets us spell a composite unit like this: `Mile / Hour`, which is the same as `QuotientUnit(Mile, Hour)`. You can do this like so:

```kotlin
operator fun <A: Unit, B: Unit> A.div(other: B) = QuotientUnit(this, other)
operator fun <A: Unit, B: Unit> A.times(other: B) = ProductUnit(this, other)
```

With all this, we can now do the unit conversion problems you get in physics class with almost no effort:

```kotlin
// James Bond is running along the roof of a train
// It takes him 1 minute to run the length of a 20-metre carriage
// The train is moving at 60 miles per hour
// How fast is James moving relative to the ground, in km/h?
val jamesSpeed = 20.meters / 1.minute
val trainSpeed = 60.miles / 1.hour

val totalSpeed = jamesSpeed + trainSpeed

val metricSpeed = totalSpeed.to(Kilometer / Hour)

println("Speed relative to ground is: $metricSpeed")
// Speed relative to ground is: 97.76 km/h
```

Easy!

The last thing I wanted to clear up was the need to repeat code for all the helper properties (`6.minutes`, `9.kilometers` etc). These have to be repeated for every type of unit, and I wanted a way of creating units without this repitition. In reality you'd probably keep these to make it easier on yourself, but it's nice to have an alternative.

How about just a simple infix function that operates on a number and a unit? Or how about if you multiply a number by a unit, it creates a quantity with that unit? What about invoking the unit with brackets - like a function call - to create a quantity in that unit? These are all quite straightforward: [^to-to-into]

[^to-to-into]: I decided to rename `.to` to `.into` so that it didn't clash with the built-in `.to` extension in Kotlin that turns two objects into a `Pair`

```kotlin
// 5 into Minute makes a Quantity(5, Minute)
infix fun <T: Unit> Number.into(unit: T) = Quantity(this.toDouble(), unit)
// 79 * Kilometer makes a Quantity(79, Kilometer)
operator fun <T: Unit> Number.times(unit: T) = this into unit
// Second * 3 makes a Quantity(3, Second)
operator fun <T: Unit> T.times(value: Number) = value into this
// Hour(12) makes a Quantity(12, Hour)
operator fun <T: Unit> T.invoke(value: Number) = value into this
```

All of these make it super easy to create quantities. And of course, you can use them with composite units: `5 * (Kilometer / Hour)`, `Second(8)`, `9.into(Metre * Metre)` each create speed, duration, and area quantities.

Using these we could solve our physics problem from above like so:

```kotlin
// James' target is running twice as fast as him along the train
// How fast is the target moving relative to the ground, in m/s?
val jamesSpeed = 20 * (Meter / Minute)
val targetSpeed = 2 * jamesSpeed
val trainSpeed = 60 * (Mile / Hour)

val totalSpeed = targetSpeed + trainSpeed

val metricSpeed = totalSpeed.into(Meter / Second)

println("Speed relative to ground is: $metricSpeed")
// Speed relative to ground is: 27.5 m/s
```

Another helper that we can add is a division operator that operates on two quantities of the same type, producing a ratio of the two values rather than another quantity. You can use this to see "how many items of length X fit in space Y?". This is done like so, inside the `Quantity` class:

```kotlin
operator fun div(other: Quantity<T>) = unit.convertToBaseUnit(amount) / other.unit.convertToBaseUnit(other.amount)

// To work out the ratio between two speeds:

println("Speed ratio: ${jamesSpeed / targetSpeed}")
// Speed ratio: 0.5
```

For completeness I also added operators for multiplying values by numbers with no units - letting you do things like "double this distance" with `2 * distance`. Quantities are also comparable, so less than and greater than also work.

Hopefully this explanation illuminates some of the magic generics in the code - which you can [view here](https://gist.github.com/javanut13/424f33324588107ee59d4b1ae929843d). I'm sure there are operations and helpers that I'm missing, or ways that this code can be cleaned up and simplified. This would make for a kick-ass back-end for a unit conversion app!
