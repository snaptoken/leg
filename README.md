# leg

Command line tool that helps you make step-by-step programming walkthroughs.

## Install

    $ gem install snaptoken

## Usage

    $ leg help

## More documentation

There is no documentation, everything is nascent and undecided right now, come
back another time!

## How to do things

### Modify a step

    $ git rebase -i $(leg ref step-name)^
    ... change step-name from 'pick' to 'edit' ...
    $ vim ...
    $ git commit --amend
    $ git rebase --continue

### Modify the first step

    $ git rebase -i --root
    ...

### Insert one or more steps

    $ git rebase -i $(leg ref insertion-point)^
    ... change insertion-point from 'pick' to 'edit' ...
    $ vim ...
    $ git commit
    $ vim ...
    $ git commit
    $ vim ...
    $ git commit
    $ git rebase --continue

### Split a step into multiple steps

    $ git rebase -i $(leg ref step-name)^
    ... change step-name from 'pick' to 'edit' ...
    $ cp file_to_edit.c final.c
    $ git checkout HEAD^ file_to_edit.c
    $ vim file_to_edit.c
    $ git commit --amend
    $ vim file_to_edit.c
    $ git commit
    ...
    $ vim file_to_edit.c
    $ git commit
    $ mv final.c file_to_edit.c
    $ git commit
    $ git rebase --continue

### Combine multiple steps into one

    $ git rebase -i $(leg ref first-step)^
    ... change each step after first-step from 'pick' to 'squash' ...

### Reorder steps

    $ git rebase -i $(leg ref first-step)^
    ... change order of steps in file ...

### Find where a change was introduced

`git blame` or `git bisect`

