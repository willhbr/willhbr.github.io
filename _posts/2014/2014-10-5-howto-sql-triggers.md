---
title: "howto: SQL Triggers"
layout: post
date: 2014-09-29
---

So, I have a computer science test on Thursday and have been getting annoyed at triggers. Triggers are basically a wee bit of sql that 'watches' the database for a certain action, and then executes a block of sql when the action is performed.

The action can be an `insert`, `update` or `delete` and the trigger can be run `before`, `after` or `instead of` the statement that set off the trigger.

For example the following statement is triggered when there is a new row inserted into the `testtable` table and it will duplicate two attributes (`attr` and `attr1`) into a second table called `result`, once for each row that has been inserted.

```
create trigger testtrigger
  before insert on testtable
  for each row
    insert into result values(new.attr, new.attr1);
```

This is all very nice for one statement, but what if you need a couple, or some conditions? You can turn the single statement into a `begin ... end` block to run multiple sql statements:

```sql
create trigger testtrigger
  before update on testtable
  for each row
    begin
      if new.attr = 'somevalue'
        insert into result values(new.attr, old.attr);
      else
        insert into result values('constant', 'mismatching data types');
      end if;
    end;
```

This snippet will run before an update on `testtable` and will execute one of two different statements depending on the new value of `attr`.

When the trigger started on insert or update, a tuple `new` is set to be the new row that is being inserted (Sometimes you need to call it `:new`). On update you get `new` and `old` to work with.

### Gotcha

When you're running this in some clients or interactive prompts, the interpreter will mistake the first semicolon as the end of the statement and fail. To fix this you just need to add:

```sql
delimiter //

create trigger mytrigger ...

//
delimiter ;
```

around your statement.

And that's basically all I learnt about triggers. I don't know why you'd want to do this kind of stuff in your database when you would do it with your database application.. but whatever.
