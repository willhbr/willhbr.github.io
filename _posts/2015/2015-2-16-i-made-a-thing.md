---
title: "I made a thing"
layout: post
date: 2015-2-16
---

Last year I was tasked with creating a database-heavy Android app. The default Android SQLite database is pretty average - everything has to be done with raw SQL statements and the results are always `Cursor` objects, which aren't the best things to deal with. Not wanting to deal with all that business (even though some aspects of the project ended up requiring it) I took a few hours and made the basis of what because a nice wee wrapper for the standard database interface.

I basically tried to replicate what [Arel](https://github.com/rails/arel) does, although without the magic that makes Arel a bit confusing (and hard to implement in Java). It allowed me to make the app fairly quickly worrying about any SQL `insert` or `update` statements - want to save something? Just use the `.save()` method, you don't have to worry about whether it should insert or update.

One of the cool things that you can do that I didn't design for is that the `Record` subclasses don't have to represent a table in the database; As long as the query you send to the constructor has the correct column names the object will get set as expected. (Although like an SQL view, saving the 'record' won't do anything).

I'll try and keep it updated as I use it for new projects and add some features that I may need. If you're looking for an easy/ lightweight way to manage a medium-sized database in your app, then [I've got the thing for you!](https://github.com/JavaNut13/Android-DB-Interface)
