---
title: "How to: Pull an app database from android app"
---

Writing an app on android that uses a database is a bit of a pain - I spent a fair amount of time creating a wrapper around the default interface that makes it behave a bit more like [Arel](https://github.com/rails/arel) and so I don't have to worry about too much SQL. Maybe I'll post it sometime..

I thought debugging the database would be impossible without writing a part of the app that dumps the data onto the screen, _but it turns out.._

[This answer](https://stackoverflow.com/a/14686392/692410) on StackOverflow basically tells you how to pull the database using the adb command into a SQLite `.db` file that can be read with an app like [this](https://sqlitebrowser.org) (Or some better alternative, please?)

Basically to set it up you should run this (Assuming you have [brew](https://brew.sh) installed and `adb` correctly in your path)

```shell
# The bundled version doesn't have zlib
brew reinstall openssl
# So we can use the openssl commands anywhere
echo "export PATH=/usr/local/opt/openssl/bin:\$PATH" >> ~/.bash_profile
```

Save this as `db_pull` in your `$PATH` or working directory.

```shell
#!/bin/bash
app=$1
adb backup -f ./data.ab -noapk $app
dd if=data.ab bs=1 skip=24 | openssl zlib -d | tar -xvf -
```

This can be used like so: `db_pull com.example.app`. You can find the `.db` file in the folder that gets created and open that with SQLite Browser.
