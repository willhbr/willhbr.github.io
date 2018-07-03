---
title: "Needless complexity: Generalising a Scheme for Aikido Training"
date: 2017-06-18
layout: post
---

> It is perhaps a little known fact that I have practiced [Aikido][aikido-wiki] for about the last 13 years now.

I'm bad at writing introductions, so let's jump straight to the problem. When training with more than one other person, you have to have some way of deciding who attacks who - you can't just alternate. Normally when practicing _tachi waza_ the most senior student goes first and does the technique four times to the _uke_ before the roles are swapped. So what to do when someone else joins your pair?

You could just make a directed triangle - the person A is attacked by B, the B by C, and C by A, before the cycle repeats. This is easy to describe and can easily be extended to any number of people, but person A will never be attacked by person C - they miss out on any feedback that person C may have for them. You want a method that will allow everyone to train with everyone else, as well as allowing each member to do the technique enough times to improve.

At the moment, this is the recommended way of training:

```
A - B
A - C
B - C
B - A
C - A
C - B
```

Now this is fine. Apart from the fact that it only applies to exactly three people. The programmer in me wants a method that applies to any number of people. How about:

```swift
func train(members: [Person]) {
  for nage in members.sorted(by: .rank) {
    for uke in members.sorted(by: .rank) where uke != nage {
      uke.attack(nage)
    }
  }
}
```

Basically starting from the highest ranked member, each member should have a turn as _nage_. They should be attacked by each other member, in the order of their rank. This is how training in a pair works, and works just the same way if the whole class is training together.

This gets slightly more confusing when you doing weapons practice - there is a less clear distinction between the _uke_ and the _nage_; the _uke_ is often not thrown by the _nage_, and the _uke_ still has to learn the attack as it not just a single strike or grab.

It's common with weapons practice for a pair to train with one role, then swap and train before moving on to the next member of the group. This reduces the distraction of changing partners, letting you focus on the technique. This can be generalised in a similar way - this time each member of the group in descending rank order is the 'key' member, who practices both sides of the technique with each other member, then the 'key' member is changed to the next member in rank.

```swift
func train(members: [Person]) {
  for key in members.sorted(by: .rank) {
    for other in members.sorted(by: .rank) where key != member {
      other.attack(key)
      key.attack(other)
    }  
  }
}
```

Basically I think too much about the efficiency of how I am training, rather than focussing on the training itself. I guess that's what happens when you spend all day learning about Software Engineering and stuff.


[aikido-wiki]: https://en.wikipedia.org/wiki/Aikido
