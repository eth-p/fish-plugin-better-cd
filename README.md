# Better `cd` for Fish Shell

A small quality-of-life improvement to `cd` (and `pushd`) that allows you to cd into a path relative to the git repository's top level working directory.


## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```
fisher add eth-p/fish-plugin-better-cd
```


## Improvements

**Change directories with `:path-relative-to-git-root`.**  
Just like `git add`, and with completion support for `cd`.

```fish
$ git init
$ mkdir folder
$ mkdir -p other/folder
$ cd folder && pwd
/repo/folder

$ cd :/other/folder && pwd
/repo/other/folder
```
