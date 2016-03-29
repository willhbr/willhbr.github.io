---
title: Why I dislike ATDD
layout: post
date: 2016-3-29
---

_This was written as the final section to a university lab report on testing, ATDD, and mocking._

Both cucumber and concordion aim to make it easier to write more understandable tests at a higher level - instead of writing unit tests that test very specific and granular aspects of a class, the acceptance tests ensure that the feature behaves as expected for the end user.

At my internship over the summer, I worked on an open source project management system called Redmine, and some of its plugins. The Redmine Backlogs plugin adds agile functionality to Redmine, and has a massive suite of Cucumber tests that I had to maintain. After seeing the 'bad side' of computer evaluated acceptance tests and ATDD, I am very sceptical to the benefits of cucumber - and have major doubts in concordion.

The Backlogs tests consisted of about 20 feature files, each ranging from 1-2 scenarios, up to about 6. This could be about 200 lines of steps. The actual definitions were split into 3 files (given, when, and then steps - it was a Ruby project so it isn't as strict as the Java implementation). These were about 1500 lines each.

Imagine the following scenario: you're tasked with making the tests pass after some feature was added, or a change in the environment caused them to fail. Running the tests reveals which of the scenarios is failing, and you have a line in a feature file that is causing it to fail. Due to the fact that the actual definition of the step is defined by a regular expression, you can't find it by simply searching for the line in the feature. Eventually you find it somehow - probably by doing a regex search for something similar to the step text.

Now that you've found the step definition, you can debug that step - or any of the steps above or below it in the scenario (which you have to find by repeating the same ordeal outlined before). You fix the scenario and any others that were affected by the change. You decide that it's good practice to write a new test that tests the feature that was just added.

Here you have the reverse problem from debugging - you don't know what steps have been defined to create the new test. Your IDE or editor likely doesn't have any kind of autocomplete to help you fill out the steps in the scenario. Instead you add a expression to the step definition files that will be used in just your test - adding to the mass of bespoke step definitions already written.

This is obviously the worst case of cucumber or any ATDD framework. On the flip side, I created my own plugin for Redmine while I was working. When it came time to test it, we decided that cucumber would be easiest - the whole team understood it and it was already setup for one plugin, so the amount of work needed to get it working on another was minimal.

Working on another project from scratch, cucumber was very easy to use - I knew off the top of my head every valid step definition and the options that I could give it. When creating my own definitions, I could write them in such a way so that they could be reused and extended later to test different situations. Obviously this is the difference between knowing a codebase and being completely new to it, as well as the worst type of codebase - an unmaintained open source project - versus the easiest to understand - a small project by one developer, which is you.

Even knowing that I was working in the worst case, I am sceptical to the benefits of computer evaluated acceptance tests. Talking to Sam - a coworker over the summer, and all-round testing guru - he says that the idea of cucumber is flawed to begin with. It assumes that the client or PO will provide acceptance criteria detailed enough to test the feature sufficiently and specific enough to be turned into valid cucumber instructions. If I was working with a PO that did give this quality acceptance critera, I would jump to cucumber almost immediately

Concordion on the other hand, completely stumps me. I understand that having nicely formatted results that can be shown off to stakeholders could prove useful, however the overhead required to test using concordion seems to be through the roof for little or no gain. In a nutshell what concordion appears to do is take all the assertions out of a normal jUnit test and put them inline in HTML elements. Once again this disconnect between the actual code and the expected results would make it harder to maintain and debug tests. In my mind cucumber is better because the content of the feature files is just the description and expected result, whereas the concodion files mix the description and tests with the layout of the result.

It seems like the end result of concordion could be acheived by parsing jUnit tests with a known format of JavaDoc and assertion messages. These could be parsed as the tests were run and then generate an HTML file - much like a JavaDoc - with the test results, which then can be styled appropriately. In fact, this could probably be done with annotations and reflection, without the need to parse the test code manually.

So far my thoughts on ATDD is that developers should spend time doing what they are best at, with the tools that they work best with - nine times out of ten this is writing code in their preferred IDE, not writing english or HTML-jUnit hybrids that will be run as tests. Perhaps my view of ATDD is skewed because I first used cucumber in the worst possible way. If I do end up using ATDD as part of my group project, I hope it is well managed and used appropriately - maybe I will come around to this way of testing.