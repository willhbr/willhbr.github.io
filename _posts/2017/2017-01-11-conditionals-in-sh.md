---
title: Conditionals in SH
---

I've been spending more time than I would like writing shell scripts recently, as I spend more time [configuring my setup](https://github.com/willhbr/dotfiles) than I do on 'real' projects. What I've found interesting is how simple the core of a shell is, and the tricks some commands do to build on this.

Most \*nix users have probably had a moment were they were writing a shell script and forgotten the syntax for an `if` statement. I write shell scripts so infrequently I often have to look it up. However all the `if` statement does is run the condition command and check the exit status, if it is 0 it will run the main block, anything else and it runs the else block.

"But what about the square brackets?" I would think to myself. Well that's just a command. You know, the `[` command. `man [` reveals that this is just a standard command with some flags to tell it what kind of thing to check.

Let's take a simple conditional that checks that two numbers are equal:

```shell
if [ $num1 -eq $num2 ]; then
  echo "Equal!"
fi
```

If `num1` is `4` and `num2` is `5`, the `[` command will receive `"4"`, `"-eq"`, `"5"`, and `"]"` (remember everything is a string in the shell). The command takes the arguments up to the closing square bracket and does the comparison, in this case `-eq` means integer comparison. As far as I can tell the closing bracket is just for readability - if you have a condition with with logical operators (`||` or `&&`) then each part of the expression can be in separate brackets (or you can use the `-o` and `-a` options to keep them in the same set of brackets).

So this means that we can do things like this:

```shell
[ -f some/file/path ] && cool_function_on_file some/file/path
```

Making use of the `&&` builtin, rather than writing a whole `if;then;fi` block. Or when we remember that the condition can be any command, we can be a [bit smarter in scripts](https://github.com/willhbr/dotfiles/blob/a1e7d4e12fc0dfae279bf1b6e972d29750b3e309/zsh/gcd.sh#L109):

```shell
if git clone "$full_remote$user/$project.git" "$_path"; then
  echo_cd $_path
fi
```

This will only change to the cloned repos directory if it cloned successfully (indicated by the result of the `git` command).

`for` loops work in a similar way, except instead of the condition we have a command that produces an output with each element separated by the `$IFS` variable. The `$IFS` is basically just whitespace/ newlines so we can capture the output of `ls` and iterate through each filename:

```shell
for filename in $(ls); do
  echo "It's a thing: $filename"
done
```

So in short, I have learnt a bit about shell scripting and now think it's kind of neat rather than getting frustrated at the seemingly nonsensicle syntax.

> For reference `[[` and `==` are builtins to BASH and other newer shells. `==` is no different to `=` (but it can't be used to accidentally assign something). `[[` works the same as `[` apart form the fact that it can be used with `<` and `>` for comparison, as it can process them before they are interpreted as IO redirection as part of a normal command.
