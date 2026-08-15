---
title: "Type-Checking SQL Queries With Crystal Macros"
tags: languages crystal
---

The aim of the game here is to use as few macros as possible. I could just have one macro that parses an SQL query, but the fun here is to use the Crystal type system to check the query for us, similar to how I [used the type system to implement dependency injection](/2026/01/31/crystal-dependency-injection/). I'll be avoiding macros, but I'll be using macro _methods_ heavily, as they let you introspect on the types of variables.

The API should also be decomposable, which is more difficult with regular macros. You should be able to split up the query like you would any other expression and have it work as expected, maybe after including a few type annotations.

What makes this process easier is modelling the queries on [SQL pipe syntax](https://research.google/pubs/sql-has-problems-we-can-fix-them-pipe-syntax-in-sql/), instead of traditional SQL. Pipe syntax is conceptually simpler, as each statement is just a transform of the output of the previous statement, and this will make our type-checking much easier.

If you've not come across the pipe syntax, you can take this query:

```sql
SELECT name, computer_count
FROM people
WHERE computer_count > 5
ORDER BY name
```

And rewrite it as a pipeline:

```sql
FROM people
|> WHERE computer_count > 5
|> SELECT name, computer_count
|> ORDER BY name
```

You can just keep tacking on extra steps to the query, which avoids needing nested queries in many cases. As a slightly contrived example, say I wanted to get the alphabetically last person with more than five computers:

```sql
FROM people
|> WHERE computer_count > 5
|> ORDER BY name DESC
|> SELECT name
|> LIMIT 1
```

You get the idea. The important thing to note is that you can fairly easily translate these pipeline queries into quite ugly, very nested regular SQL queries. A query optimiser should be able to translate that back into a sensible query plan, but we're not here to worry about that, we're here to do naughty things with macros.

The pipeline syntax matches really well with method chaining, so the goal is to build queries somewhat like this:

```crystal
People
  .where(computer_count > 5)
  .order_by(:name)
  .select(:name)
  .limit(1)
```

The other ingredient that makes this whole escapade work is [named tuples](https://crystal-lang.org/api/latest/NamedTuple.html). They're unlike other types in Crystal in that the names of the fields are part of the type itself, which you can introspect with macros. We'll use lots of generics, and using a named tuple as the generic type allows us to encode the structure of a table as a type—since what are tables if not a collection of names and types?

{% raw %}
```crystal
def inspect(var : T) forall T
  {% for name, type in T %}
    {% puts "#{name}: #{type}" %}
  {% end %}
end

nt = {
  name: "Will",
  admin: true
}
inspect(nt)
```
{% endraw %}

There's a lot going on here, but it's got the main tricks we need to do this whole thing. `inspect` is a macro method, where the body is generated from macro code once for each set of input types. We call it once with the variable `nt`, which has the type `NamedTuple(name: String, admin: Bool)`. In the actual `inspect` method we introduce a type variable `T` with the `forall T` suffix. This is more akin to the little `<T>` you'd find in `fn foo<T>(arg: T) { ... }`. The `forall` doesn't actually mean that it needs to work for any type `T`, you can just `raise` an exception in the macro code and fail for a particular type. It'll also only be attempted on types that are used to call the function.

The type variable can be accessed from the macro code, whereas the actual variable `var` obviously cannot. Since we've got `T` and we know it's some kind of `NamedTuple`, we can iterate over it to pull out the field names and types. This program won't actually do anything at runtime, but at compile time it'll print:

```
name: String
admin: Bool
```

As a basis for the whole query system, we'll define a generic interface `Source(T)`. This could either be a definition of a table, or some query on a table that produces a schema of type `T`, which we'll just ensure is always a `NamedTuple`.

```crystal
module Source(T)
end
```

We'll then implement a source that reads from a table:

```crystal
struct TableSource(T)
  include Source(T)

  def initialize(@name : String)
  end

  def to_sql(params : Deque(DB::Any)) : String
    "SELECT * FROM #{@name}"
  end
end
```

You could construct this manually, but we can be civilised and use a macro to build one based on the instance variables in a data object:

{% raw %}
```crystal
module Table
  macro included
    {% verbatim do %}
      def self.query
        {% begin %}
          TableSource(NamedTuple(
            {% for var in @type.instance_vars %}
              {{ var.name }}: {{ var.type }},
            {% end %}
          )).new({{ @type.name.stringify.downcase }})
        {% end %}
      end
    {% end %}
  end
end

class User
  include Table
  getter name : String
  getter computer_count : Int32

  def initialize(@name, @computer_count)
  end
end
```
{% endraw %}

We can then just do `User.query` and we've got an appropriate `Source` for that table. Calling `to_sql` on that `TableSource` object would simply give us `SELECT * FROM user`.

# `SELECT`

The simplest transformation you can do in SQL is a `SELECT`, where you take the fields you have access to and return a different set of fields, usually a subset. We'll ignore computed properties for now and just handle selecting a subset of the fields.

On second thought it's not that much simpler than anything else, but this is where I started anyway.

All the operations will be defined as methods on the `Source(T)` module, and they'll return another `Source`, probably of a different type. This is how the pipelining will work. In the simplest case, a `SELECT` from `Source(T)` will return a `Source(R)` where `R` is a strict subset of the fields in `T`.

Anyway, the most basic version of `select` looks like this:

{% raw %}
```crystal
module Source(T)
  def select(**kwargs : K) forall K
    # the macro system is dynamically typed, so the type here doesn't matter
    {% fields = {} of String => Nil %}
    {% for name, type in T %}
      {% fields[name] = type %}
    {% end %}
    {% for name, type in K %}
      {% if fields[name].nil?
           raise "unknown field: #{name}"
         end %}
    {% end %}
    Select(T, NamedTuple(
      {% for name, type in K %}
        {{ name }}: {{ fields[name] }},
      {% end %}
    )).new(kwargs)
  end
end

{% endraw %}
class Select(F, T)
  include Source(T)

  def initialize(@source : Source(F), @fields : ...)
  end
end

User.query.select(name: String)
```

Inside the `select` method, we can use macros to inspect both `T` (the structure of the source table or query) and `K` (the fields that we want to select down to) and produce a `Select` object with the right type parameters. The type signature of the `select` method can just omit the return type and have the compiler fill that in, since there's no way to describe the nonsense we're doing here (filtering down from one set of fields to another).

This approach is a bit of a dead end, however. We won't be able to use this model to select arbitrary expressions (like `computer_count > 4 AS many_computers`) and when we try to find a type for `@fields` we'll run into this limit.

The other problem with it is that you have to provide types for the fields you're selecting (like `name: String`) but we're not even checking that the type is correct. Type-checking this is a little tricky, since the argument isn't of type `NamedTuple(name: String)` it's of `NamedTuple(name: String.class)`, so simple equality checking won't work.

To get proper type-checking and computed properties, the `Select` class needs to have more generics—the source, destination, and fields all need to be their own separate type variables. The `Select` class is fairly simple:

```crystal
class Select(F, T, K)
  include Source(T)

  def initialize(@source : Source(F), @args : K)
  end

  def to_sql(params : Deque(DB::Any)) : String
    String.build do |io|
      io << "SELECT "
      @args.each_with_index do |name, arg, idx|
        io << ", " unless idx.zero?
        case arg
        when Expr
          io << arg.to_sql << " AS " << name
        else
          io << name
        end
      end
      io << " FROM ("
      io << @source.to_sql(params)
      io << ")"
    end
  end
end
```

`F` is the schema we're mapping from, `T` is the schema we map to, and `K` is how we're mapping between them. Although to do this properly we need to handle expressions.

# Expressions

Any sufficiently complicated SQL query will compute values on the fly in `SELECT`, but even the simplest queries will use expressions in the `WHERE` clause. This would be easy to do as a little DSL with no type-checking, but that's amateur hour stuff. To do type-checking, we need more generics.

What we need is for the name of the variables that we're accessing to be available in the type system. When we use them in our query, the transform functions (like `select` or `where`) can check that a column with that name actually exists when it's building the type of the result. We'll do this with `ExprWithVar(P, T)`. `P` is a `NamedTuple` of the fields we're reading, and `T` is the return type of the expression. This expression:

```sql
computer_count > 4
```

Would have the type `ExprWithVar(NamedTuple(computer_count: Int32), Bool)`. A limitation here is that we have to include the type of the variable (`Int32`), but there are some shortcuts to help that we'll get to later.

Just like our `Source` module, we can define extra methods on `ExprWithVar` to build more complicated expressions. The basis of this is an `Expr` type that represents any kind of expression. That can be an expression accessing a variable (`ExprWithVar`), or a constant value (`ConstExpr`) , or an expression based on two other subexpressions (`BiExpr`). You could also implement wrappers for SQL functions, and do type-checking based on their arguments and return values.

I didn't go too far with this, but someone with more time could add all the necessary boilerplate. Here's the basic structure of a `>` operator that can either operate on two expressions, or a constant value.

{% raw %}
```crystal
def >(other : R) forall R
  {% if R < Expr %}
    {% if R.type_vars[1] != T
         raise "#{R} can't be compared with #{T}"
       end %}
    {% begin %}
      {% fields = {} of Symbol => Nil %}
      {% for name, type in P %}
        {% fields[name] = type %}
      {% end %}
      {% for name, type in R.type_vars[0] %}
        {% if (t = fields[name]) && t != type
             raise "mismatching types: #{t} != #{type}"
           end
           fields[name] = type %}
      {% end %}
      {% puts fields %}
      BiExpr(NamedTuple(
        {% for name, type in fields %}
          {{ name }}: {{ type }},
        {% end %}
        ), Bool, T, {{ R.type_vars[1] }}).new(self, other, ">")
    {% end %}
  {% else %}
    BiExpr(P, Bool, T, R).new(self, ConstExpr(R).new(other), ">")
  {% end %}
end
```
{% endraw %}

What's a bit of a hack is that we have to keep the type variables in the same place across different types, so that we can pull out the field names and return type correctly. I've made it so the names are always first, and the type is always second.

It would be great if you could instead cast a particular type to another (in this case `ExprWithVar` to `Expr`) and then access the type variables that it implements that interface with. For example, I don't think there's any simple way to find what type of `Expr` this `ComparisonExpr` is:

```crystal
class ComparisonExpr(P)
  include Expr(Bool)
end
```

It can obviously be used as an `Expr(Bool)`, but as far as I'm aware you can't access that from a `TypeNode` in a macro. I solved this by adding type variables that are not strictly necessary, just so the information was easier to access. I have `ComparisonExpr(P, T)` where `T` is only ever `Bool`, but it means I can grab that type with `.type_vars[1]`.

Going back to our `select` method, the extra type parameter `K` will be a `NamedTuple` where the fields match those in `T`, but all the types will be an `Expr(R)` where `R` matches the type of the field in `T`.

Simple, right?

{% raw %}
```crystal
def select(**kwargs : K) forall K
  {% begin %}
    {% source_fields = {} of String => String
       dest_fields = {} of String => String %}
    {% for name, type in T %}
      {% source_fields[name] = type %}
    {% end %}
    {% for name, type in K %}
      {% if type <= Passthrough %}
        {% if source_fields[name].nil?
             raise "missing field #{name}"
           end %}
        {% dest_fields[name] = source_fields[name] %}
        {{ name }} : Expr({{ source_fields[name] }}) = (
          VarExpr(NamedTuple({{ name }}: {{ source_fields[name] }}), {{ source_fields[name] }}).new)
      {% elsif type <= Expr %}
        {% dest_fields[name] = type.type_vars[1] %}
        {% for input_var, input_type in type.type_vars[0] %}
          {% if source_fields[input_var].nil? || source_fields[input_var] != input_type
               raise "type mismatch: #{input_var}: #{input_type} != #{source_fields[input_var]}"
             end %}
        {% end %}
        {{ name }} : Expr({{ type.type_vars[1] }}) = kwargs[:{{ name }}]
      {% else %}
        {% raise "unknown type #{type}, should be Expr or Passthrough" %}
      {% end %}
    {% end %}

    Select(T, NamedTuple(
      # Output types
      {% for name, type in dest_fields %}
        {{ name }}: {{ type.id }},
      {% end %}
    ), NamedTuple(
      # Expression types
      {% for name, type in dest_fields %}
        {{ name }}: Expr({{ type.id }}),
      {% end %}
    )).new(self, {
      # Expression values
      {% for name, type in dest_fields %}
        {{ name }}: {{ name }},
      {% end %}
    })
  {% end %}
end
```
{% endraw %}

The first part of this method is doing the type-checking by introspecting on the variables in any expressions and making sure the types of those variables match the types in the source table:

{% raw %}
```crystal
{% dest_fields[name] = type.type_vars[1] %}
{% for input_var, input_type in type.type_vars[0] %}
  {% if source_fields[input_var].nil? || source_fields[input_var] != input_type
       raise "type mismatch: #{input_var}: #{input_type} != #{source_fields[input_var]}"
     end %}
{% end %}
```
{% endraw %}

The last bit is just building the right generic arguments for the `Select` so it has the right input, output, and transformation types.

As a shortcut I've also made a `Passthrough` type, which is special-cased to lookup the field in the source table and add it directly to the output.

The type of a `Select` that maps from the `User` table to just select the `name` field would be:

```crystal
Select(
  NamedTuple(name: String, computer_count: Int32),
  NamedTuple(name: String),
  NamedTuple(name: ExprWithVar(NamedTuple(name: String), String)))
```

# `WHERE`

Once we've got expressions, `WHERE` statements are actually really easy. The simplest case is just passing a single `Expr` to `where`:

{% raw %}
```crystal
def where(expr : R) forall R
  {% unless R < Expr(Bool)
       raise "#{R} is not a boolean expression"
     end %}
  {% if R < ExprWithVar %}
    {% fields = {} of String => String %}
    {% for name, type in T %}
      {% fields[name] = type %}
    {% end %}
    {% for name, type in R.type_vars[0] %}
      {% if fields[name].nil?
           raise "unknown field #{name} in #{T}"
         end %}
    {% end %}
  {% end %}
  WhereExpr(T).new(self, expr)
end
```
{% endraw %}

You don't need to build up any complicated types, because the expression has to return a boolean, and the structure of the table doesn't change. `WhereExpr` just needs to build the SQL:

```crystal
class WhereExpr(T)
  include Source(T)

  def initialize(@source : Source(T), @expr : Expr(Bool))
  end

  def to_sql(params : Deque(DB::Any)) : String
    String.build do |io|
      io << "SELECT * FROM ("
      io << @source.to_sql(params)
      io << ") WHERE "
      io << @expr.to_sql(params)
    end
  end
end
```

I also added a special-case where you can use keyword arguments as intended to do simple equality checks on multiple fields, allowing for `.where(name: "Will")`.

{% raw %}
```crystal
module Source(T)
  def where(**kwargs)
    WhereEq(T, typeof(kwargs)).new(self, kwargs)
  end
end

class WhereEq(T, Q)
  include Source(T)

  def initialize(@source : Source(T), @query : Q)
  end

  def to_sql(params : Deque(DB::Any)) : String
    String.build do |io|
      io << "SELECT * FROM ("
      io << @source.to_sql(params)
      io << ") WHERE "
      {% for name, type in Q %}
        io << {{ name.stringify }} << " = ?"
        params << @query[:{{ name }}]
        io << " AND "
      {% end %}
      io << "TRUE"
    end
  end
end
```
{% endraw %}

`Q` will have a subset of the fields in `T`, and I should probably check that the types match up here, but I didn't. Oh well.

# Sugar

Up until this point the main party trick has been doing weird things with named tuples in macros to skirt around the type system. Well I have at least one other trick.

Calling `where` with an expression is not particularly ergonomic. Even if you made a macro to help define typed variables, like this:

```crystal
macro field(name)
  VarExpr(NamedTuple({{ name.var }}: {{ name.type }}), {{ name.type }}).new
end
```

Your `where` would still be repetitive:

```crystal
users.where(
  field(computer_count : Int32) > 30
)
```

You have to repeat the type of `computer_count`, which just isn't good enough. Thankfully there's a solution:

{% raw %}
```crystal
module Source(T)
  def where(&)
    {% begin %}
      b = WhereBlock(NamedTuple(
        {% for name, type in T %}
          {{ name }}: VarExpr(NamedTuple({{ name }}: {{ type }}), {{ type }}),
        {% end %}
      )).new({
        {% for name, type in T %}
          {{ name }}: VarExpr(NamedTuple({{ name }}: {{ type }}), {{ type }}).new,
        {% end %}
      })
      cond = with b yield
      WhereExpr(T).new(self, cond)
    {% end %}
  end
end

class WhereBlock(T)
  def initialize(@data : T)
  end

  macro method_missing(call)
    @data[:{{ call.name }}]
  end
end
```
{% endraw %}

It's surprisingly simple, but it took a little bit of work to get there. `WhereBlock` is simply a wrapper that provides `method_missing` delegation to the fields in a `NamedTuple`, returning an appropriate `VarExpr` with the right type. This simplifies the call down to:

```crystal
users.where { computer_count > 5 }
```

Without losing any type safety. If you try to access a variable that doesn't exist, you'll get an error, as expected.

Interestingly I wasn't able to access `T` in `method_missing` or in a `finished` macro to generate the methods more explicitly. Using a named tuple here seems to just kick the type-checking can down the road long enough to let this code compile.

The other syntactic sugar I added was a `fields` macro to make calling `select` easier:

{% raw %}
```crystal
macro fields(*args, **kwargs)
  {
    {% for arg in args %}
      {{ arg }}: Passthrough.new,
    {% end %}
    {% for name, type in kwargs %}
      {{ name }}: {{ type }},
    {% end %}
  }
end
```
{% endraw %}

The call site is still a bit noisy, but you can remove some type annotations:

```crystal
users.select(
  **fields(name, many_computers: field(computer_count : Int32) > 5))
```

To be honest I could probably extend this macro to wrap the value of the named arguments in a block, and then use the same `WhereBlock` trick with `method_missing`. Hang on a second, that seems doable…

{% raw %}
```crystal
module Source(T)
  def select(&)
    {% begin %}
      s = SelectBlock(NamedTuple(
        {% for name, type in T %}
          {{ name }}: VarExpr(NamedTuple({{ name }}: {{ type }}), {{ type }}),
        {% end %}
      )).new({
        {% for name, type in T %}
          {{ name }}: VarExpr(NamedTuple({{ name }}: {{ type }}), {{ type }}).new,
        {% end %}
      })
      sel = with s yield
      select_impl(sel)
    {% end %}
  end
end

class SelectBlock(T)
  def initialize(@data : T)
  end

  macro method_missing(call)
    @data[:{{ call.name }}]
  end
end
```
{% endraw %}

This works basically the same way as using a block for `where`. The `SelectBlock` class implementation is actually identical, so they could be shared. The block passed to `select` just needs to return a `NamedTuple`, and it can access the existing fields as variables with the same `method_missing` trick. The call site looks like this:

```crystal
User.query.select do
  {
    name: name,
    many_computers: computer_count > 5
  }
end
```

You could do a similar trick where you return a `Tuple` of fields instead of a `NamedTuple`, and autogenerate the column names, like most databases do with normal SQL.

I did implement a basic `JOIN`, which is just a method that takes two `Source` objects and an expression, and returns a `Source` with the union of the two sets of fields. A lot of this is just really messy macro programming, rather than any new tricks, so I won't go into depth on that one. If you're interested you can see all the code [on Codeberg](https://codeberg.org/willhbr/crystal-sql-type-checker).

This is absolutely all just a proof of concept, I don't expect anyone to use this in an actual application. The type-checking is pretty low effort, and I haven't tested it. It is of course a testament to the [weird and wonderful things](/2026/01/31/crystal-dependency-injection/) you can do with Crystal's macro system. This process would be a little easier if I could introspect on types' conformance to certain interfaces, and if the type variable was accessible in more places. Although I don't know if there are good reasons or limitations that make these impossible.
