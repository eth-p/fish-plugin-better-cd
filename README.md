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



**Fuzzy find your directories with `cd`.**  
(requires [fd](https://github.com/sharkdp/fd) and [fzf](https://github.com/junegunn/fzf))

```console
$ mkdir -p foo/bar/baz
$ mkdir -p foo/cat/dog
$ cd baz && pwd
foo/bar/baz

$ cd ../../dog && pwd
foo/cat/dog
```



## Configuration

All configuration is done with variables, preferably with `set -U` for universal variables.

- `better_cd_search_depth` (default: 4)  
  The max depth to search when fuzzy searching.
- `better_cd_search_ignore_paths`  
  Full paths that will be ignored when fuzzy searching.
- `better_cd_search_ignore_names`   
  Directory names that will be ignored when fuzzy searching.
- `better_cd_disable_fzf_tiebreak`   
  If set to `true`, only `cd [path]` with exactly one fuzzy match will be used, rather than prompting the user to pick between a list with fzf.
- `better_cd_disable_fzf`  
  If set to `true`, fuzzy matching will be disabled.

