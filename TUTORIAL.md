# Creating a step-by-step programming tutorial with `leg`

Create a project folder for your tutorial, `cd` into it, and run `leg init`.

```sh
$ cd ~/projects
$ mkdir fizzbuzz-tutorial
$ cd fizzbuzz-tutorial
$ leg init
```

This creates two folders: `doc/`, where you will write the text of your
tutorial, and `step/`, which is a "working directory" that you will use to
write and modify the actual code steps of your tutorial.

(Also, a hidden `.leg/` directory is created which marks your project folder as
the root of a `leg` tutorial. This is used by `leg` internally, so you don't
have to worry about it.)

Create a file in the `step/` folder called `fizzbuzz.js`, with the following
contents:

```js
var n = 1;
while (n <= 100) {
  console.log(n);
  n++;
}
```

Save it, and then run `leg commit`. Congratulations, you have created your
first step! Now open `step/fizzbuzz.js` again, and modify it like so:

```js
var n = 1;
while (n <= 100) {
  if (n % 3 == 0) {
    console.log("Fizz");
  } else {
    console.log(n);
  }
  n++;
}
```

Save it, and then run `leg commit`. Your tutorial now has 2 steps! 

## Rendering the tutorial

Run the `leg build` command to build the tutorial into a nice HTML page. Open
`build/html/tutorial.html` in your web browser to see the result.

You can add text in between the steps of your tutorial by simply adding
(Markdown-formatted) text to `doc/tutorial.litdiff`. For example:

```diff
# My FizzBuzz Tutorial

Hello! This is a step-by-step tutorial that teaches you how to write your own
[FizzBuzz](http://wiki.c2.com/?FizzBuzzTest).

The first thing to do is to write a `while` loop.

~~~ Loop through numbers 1 to 100
--- /dev/null
+++ b/fizzbuzz.js
@@ -0,0 +1,5 @@
+var n = 1;
+while (n <= 100) {
+  console.log(n);
+  n++;
+}

Now that we have our `while` loop, with the base case of printing out each
number, we can start handling special cases. We'll start with handling "Fizz".

~~~ Print "Fizz" for multiples of 3
--- a/fizzbuzz.js
+++ b/fizzbuzz.js
@@ -1,5 +1,9 @@
|var n = 1;
|while (n <= 100) {
-  console.log(n);
+  if (n % 3 == 0) {
+    console.log("Fizz");
+  } else {
+    console.log(n);
+  }
|  n++;
|}
```

## Adding the rest of the steps

```js
var n = 1;
while (n <= 100) {
  if (n % 3 == 0) {
    console.log("Fizz");
  } else if (n % 5 == 0) {
    console.log("Buzz");
  } else {
    console.log(n);
  }
  n++;
}
```

```js
var n = 1;
while (n <= 100) {
  if (n % 3 == 0) {
    console.log("Fizz");
  } else if (n % 5 == 0) {
    console.log("Buzz");
  } else {
    console.log(n);
  }
  n++;
}
```

```js
var n = 1;
while (n <= 100) {
  if (n % 3 == 0) {
    console.log("Fizz");
  } else if (n % 5 == 0) {
    console.log("Buzz");
  } else if (n % 15 == 0) {
    console.log("FizzBuzz");
  } else {
    console.log(n);
  }
  n++;
}
```

## Amending a step

Oops, that last step we committed has a bug! Let's fix that. In
`step/fizzbuzz.js`, move the `n % 15` case above the other two cases:

```js
var n = 1;
while (n <= 100) {
  if (n % 15 == 0) {
    console.log("FizzBuzz");
  } else if (n % 3 == 0) {
    console.log("Fizz");
  } else if (n % 5 == 0) {
    console.log("Buzz");
  } else {
    console.log(n);
  }
  n++;
}
```

Now run the `leg amend` command, and it will overwrite the step you committed
with this new code.

## Resolving conflicts

Let's try something a little more challenging. Let's say we want to rewrite our
steps to use a `for` loop instead of a `while` loop. That means going back and
amending the first step of our tutorial.

We can do that by running `leg goto 1` to checkout the first step of the
tutorial into the `step/` folder. Then modify `step/fizzbuzz.js` to look like
this:

```js
for (var n = 1; n <= 100; n++) {
  console.log(n);
}
```

Now run `leg amend`. `leg` will try to apply the change you just made to all
the steps that come after it. Often, with large files, it can do this
automatically. But sometimes you will have to resolve merge conflicts manually.

In this case, after running `leg amend`, you will get a message saying that you
need to resolve a merge conflict with step 2. To resolve the conflict, open
`step/fizzbuzz.js` and resolve it by hand, or use a merge tool. The final
result should look like this:

```js
for (var n = 1; n <= 100; n++) {
  if (n % 3 == 0) {
    console.log("Fizz");
  } else {
    console.log(n);
  }
}
```

When the conflict is resolved and you've saved `step/fizzbuzz.js`, run
`leg resolve` to continue.

## Inserting steps

So far, whenever we've run `leg commit` we've been adding steps to the end of
our tutorial. We can also insert commits in the middle of our tutorial by
running `leg goto <step-number>`, making changes, and running `leg commit`.
This will add step(s) *after* the given `<step-number>`.

For example, let's add a step after step 1 that prints out a welcome message at
the beginning of the program. First, run `leg goto 1`. This checks out step 1
into the `step/` folder. Now modify `step/fizzbuzz.js` thusly:

```js
console.log("Welcome to fizzbuzz!");

for (var n = 1; n <= 100; n++) {
  console.log(n);
}
```

Save the file and run `leg commit`. A new step 2 will be inserted and all the
steps afterward will be bumped up one. Note that there may be conflicts that
need to be resolved, as is always possible when making changes to past steps.

## Splitting a step into multiple steps

(The example here will be splitting the `n % 15` step into a step that does
`n % 3 == 0 && n % 5 == 0` and then a step that simplifies that to `n % 15`.
And maybe I'll think of a third step it can be split into...)

## Reording steps

(Here we'll try moving the welcome message step to the end of the tutorial.)

## Squashing multiple steps into a single step

(I guess here we'll undo the splitting into steps of `n % 15` that we did
earlier, for lack of any better ideas.)

