---
title: "Recklessly Smashing mruby Into Zsh"
tags: design tools
---

If you're a reasonably serious shell user you probably know that you've got to write some things as shell functions instead of scripts because they need to modify the state of the shell itself. Usually that's altering environment variables or changing the working directory of the shell. Often it's just that you want to save some state for later and don't want to deal with saving it to a file and parsing it back later.

I've got an old [shell function called `gcd`][codeberg-gcd] that changes directory to a predefined location where I keep my projects. It also has autocomplete based on the project names. I originally write it with support for cloning repos, so you'd just do `gcd https://codeberg.org/willhbr/dotfiles.git` and it would grab the repo for you and put it in the right place. This ended up being more trouble than it was worth, because parsing a URL in a shell script is a pain, so I simplified it to just `cd` quickly with autocomplete.

[codeberg-gcd]: https://codeberg.org/willhbr/dotfiles/src/branch/main/shell/autoload/gcd

Of course, implementing this in any scripting language (Ruby, Python, etc) would be easy. Even without proper URL parsing you can pretty quickly do a `.split '/'` and trim the `.git` off the end of the last element. But then that script couldn't actually change the directory of your shell. You could just have a shell function that calls the script, captures the output, and calls `cd` itself, but then you've got two moving pieces that you've got to maintain, and you've got to make sure the script _only_ prints the path as any extra output will mess it up.

So I had this terrible thought: Zsh and mruby are both just C programs, and mruby is _designed_ to be compiled into other programs easily. Could I just run these in the same binary, and let a Ruby script do all the things a shell function can do?

The answer is no, not without a lot of effort, but I did see that it's possible.

I started by grabbing the [Zsh source code](https://github.com/zsh-users/zsh) (the GitHub mirror is much faster than the official server), running the `configure` script to generate a `Makefile`, and then spent ages messing around trying to reconcile the [mruby docs][mruby-howto] with a huge `Makefile` that I didn't understand. In the end I hacked it together like this:

[mruby-howto]: https://mruby.org/docs/articles/executing-ruby-code-with-mruby.html

1. [Clone `mruby`][mruby-gh] into the root of the Zsh repo (adding it to `.gitignore`)
2. In the `mruby/` directory, run `make`
3. Add to `CPPFLAGS` and `LIBS` to point to `mruby`

[mruby-gh]: https://github.com/mruby/mruby

```makefile
MRUBY_DIR = /path/to/my/projects/zsh/mruby
CPPFLAGS  = -I$(MRUBY_DIR)/include
LIBS      = -ldl -lncursesw -lrt -lm -lc -L$(MRUBY_DIR)/build/host/lib -lmruby
```

Then I could run `make` in the Zsh directory and get my very own binary in `Src/zsh`. Of course this is a complete hack because the Makefile is generated, so if you _actually_ wanted to do this you'd have to work out how that fits together.

With the hard part out of the way, we can actually write some code to call Ruby. I found where builtin functions are defined (it's [`Src/builtin.c`][builtin-c]) and copied an existing one to define a `require` function that would load a Ruby file.

[builtin-c]: https://github.com/zsh-users/zsh/blob/master/Src/builtin.c

```c
#include "mruby.h"
#include "mruby/compile.h"

/* Builtins in the main executable */

static struct builtin builtins[] =
{
  BIN_PREFIX("-", BINF_DASH),
  BIN_PREFIX("builtin", BINF_BUILTIN),
  BIN_PREFIX("command", BINF_COMMAND),
  BIN_PREFIX("exec", BINF_EXEC),
  // ...
  BUILTIN("require", BINF_PSPECIAL, bin_mruby_require, 1, -1, 0, NULL, NULL),
```

I then found some existing code that would let me read a file—the `zstuff` documentation says "stuff a whole file into memory and return it" which is _exactly_ what I needed. Most of this was hacked together by looking at other builtin Zsh functions.

```c
/**/
int
bin_mruby_require(char *name, char **argv, UNUSED(Options ops), UNUSED(int func))
{
  off_t len;
  char *s, *enam, *buf;
  struct stat st;
  mrb_value obj;
  if (!*argv)
      return 0;
  /* get arguments for the script */
  if (argv[1])
    pparams = zarrdup(argv + 1);

  enam = ztrdup(*argv);
  s = unmeta(enam);
  errno = ENOENT;
  if (access(s, F_OK) == 0 && stat(s, &st) >= 0 && !S_ISDIR(st.st_mode)) {
    len = zstuff(&buf, s);
    obj = mrb_load_nstring(imruby, buf, len);

    if (imruby->exc) {
      obj = mrb_funcall(imruby, mrb_obj_value(imruby->exc), "inspect", 0);
      obj = mrb_funcall(imruby, obj, "to_s", 0);
      fwrite(RSTRING_PTR(obj), RSTRING_LEN(obj), 1, stdout);
      mrb_print_backtrace(imruby);
      putc('\n', stdout);
    }
  } else {
    return 1;
  }

  return 0;
}
```

What tripped me up for a while is that Zsh doesn't have header files (at least not for the builtins) and I kept getting errors saying my function wasn't defined. I'm used to writing civilised languages so I found this quite confusing. Eventually I noticed that every method had an empty doc comment (`/**/`) above it, and if I added that above my new method, it would get added to `builtin.epro`, which I assume is what they're using as their headers.

We're still not there yet, since we actually need to initialise a Ruby interpreter. Once again looking at how the rest of Zsh does things, I saw that functions and stuff were stored in a global `HashTable shfunctab`, defined in `hashtable.c`. I followed the pattern, defining my Ruby interpreter:

```c
/**/
mod_export mrb_state* imruby;

/**/
void
init_mruby(void)
{
  imruby = mrb_open();
}
```

I then called this in the `setupvals` function in `Src/init.c`, so it would be available when I needed it. A quick `make` and I had a Zsh binary that could load Ruby code. That Ruby code couldn't do much, but it would run.

Now here comes the actual hard part: calling Zsh from Ruby. This is where things get hairy, but this is the gist:

```c
static mrb_value
mrb_call_zsh(mrb_state *mrb, mrb_value self)
{
  char *func_name;
  mrb_int argc = mrb_get_argc(mrb);
  const mrb_value *argv = mrb_get_argv(mrb);

  mrb_value func = mrb_cfunc_env_get(mrb, 0);
  func = mrb_funcall(imruby, func, "to_s", 0);
  func_name = RSTRING_PTR(func);

  LinkList args = znewlinklist();
  for (int i = 0; i < argc; i++) {
    mrb_value arg = argv[i];
    arg = mrb_funcall(imruby, arg, "to_s", 0);
    char *str = RSTRING_PTR(arg);
    zaddlinknode(args, str);
  }
  Builtin bf;
  Shfunc shf;
  if ((shf = (Shfunc)
    shfunctab->getnode(shfunctab, func_name))) {
    lastval = doshfunc(shf, args, 1);
  } else if ((bf = (Builtin)
          builtintab->getnode(builtintab, func_name))) {
    LinkList a;
    execbuiltin(args, a, bf);
  } else {
    lastval = 127;
    zputs(func_name, stdout);
    zputs(" not found\n", stdout);
  }

  return self;
}

static mrb_value
mrb_zsh_lookup(mrb_state *mrb, mrb_value self)
{
  mrb_value env[1];
  env[0] = mrb_get_arg1(mrb);

  struct RProc *proc = mrb_proc_new_cfunc_with_env(mrb, mrb_call_zsh, 1, env);
  return mrb_obj_value(proc);
}

// In init_mruby()
mrb_define_method(imruby, imruby->kernel_module,
            "zsh_lookup", mrb_zsh_lookup, MRB_ARGS_REQ(1));
```

This allows a Ruby script to lookup and call a Zsh function by name. If you defined a function in Zsh like this:

```zsh
my_zsh_function() {
  echo "Hello from Zsh!"
}
```

You can get the function and call it from Ruby:

```ruby
zsh_lookup('my_zsh_function').call(nil)
```

It doesn't handle arguments properly, but that's just the start of the problems.

The reason this wouldn't work is that you're merging two programming languages, each with their own object model, garbage collector, and suchlike, and trying to make them work as one. This creates a whole host of awkward questions.

Like how do you determine when an object should be freed? You'll need to track what has a reference to it on both sides. Zsh functions don't return objects, they output text. What happens when you call a Zsh function from Ruby, do you need to do something special to capture the output, or should the output be returned as a string by default? How do you change that behaviour? If you pass a complex Ruby object to a Zsh function, how does that work? Does it get converted into a string? Is it only when you try to read it in Zsh that it becomes a string, but if it gets passed from Ruby to Zsh then back to Ruby it'll stay the same? What if it gets passed to a command as an argument?

None of these questions are unanswerable, but answering them and implementing a consistent behaviour that's bug-free would be a significant amount of work.

There are some projects that are leaning in this direction already. [Fish shell](https://fishshell.com) is the obvious "shell but with a more modern language". [`xonsh`](https://xon.sh/) basically merges a shell with Python, and [`oil`](https://www.oilshell.org/) adds their own proper scripting language into a modern shell. [I wrote about these and the challenges of modernising shells in 2023][modern-shells].

[modern-shells]: /2023/07/06/why-modernising-shells-is-a-sisyphean-effort/

Ultimately though I want to keep using Zsh, with all its features and plugins and extensibility, and then also use my preferred scripting language to write helper functions and autocomplete. Think about all the times a "simple" shell script has to use `grep` and `sed` and `awk` just to do things that are trivial in any scripting language. I've even started [using Ruby as a replacement for these tools because I find it easier](/2025/06/08/using-ruby-in-shell-pipelines/).

If you're going to write a script, unless it's only a few lines just use a real scripting language. I don't really care which one.[^i-totally-do] Most OSes have good scripting languages built in, so you probably don't have to worry about portability that much. It'll be easier to parse arguments, report errors, and do data processing. It'll be easier to add a new feature or edge case. And when you're finally ready to admit it needs to become a _program_ instead of a _script_, it's already structured like one and it'll be easier to migrate to another language.[^use-rust]

[^i-totally-do]: I totally care, it should be Ruby, because Ruby rules and is great for scripting.
[^use-rust]: Honestly [Clap](https://docs.rs/clap/latest/clap/) is so good at providing consistent argument parsing and error messages it makes Rust the obvious choice for writing command-line programs. Crystal is a top contender because it's the [best language ever](/2023/06/24/why-crystal-is-the-best-language-ever/).
