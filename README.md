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
(requires [fzf](https://github.com/junegunn/fzf) and either [fd](https://github.com/sharkdp/fd) or [z](https://github.com/jethrokuan/z); must be enabled, see below)

```console
$ mkdir -p foo/bar/baz
$ mkdir -p foo/cat/dog
$ cd baz && pwd
foo/bar/baz

$ cd ../../dog && pwd
foo/cat/dog
```



**Undo your previous `cd`.**   
Did your fuzzy-cd go into the wrong directory?

```console
$ cd ~/D
```



## Configuration

All configuration is done with variables, preferably with `set -U` for universal variables.

- `better_cd_search_depth` (default: 4)  
  The max depth to search when fuzzy searching (with fzf).
- `better_cd_search_ignore_paths`  
  Full paths that will be ignored when fuzzy searching (with fzf).
- `better_cd_search_ignore_names`   
  Directory names that will be ignored when fuzzy searching (with fzf).
- `better_cd_disable_fzf_tiebreak`   
  If set to `true`, only `cd [path]` with exactly one fuzzy match will be used, rather than prompting the user to pick between a list with fzf.
- `better_cd_fuzzy_with_fzf` (default: false)  
  If set to `true`, fuzzy matching sources will come from `fzf`.
- `better_cd_fuzzy_with_z` (default: false)  
  If set to `true`, fuzzy matching sources will come from `z`.
- `better_cd_fuzzy_with_z_like_z` (default: false)  
  If set to `true`, only the top candidate from `z` will be picked.



### Recommended Defaults

If you prefer to use fzf searching:

```fish
set -U better_cd_fuzzy_with_z false
set -U better_cd_disable_fzf_tiebreak true
set -U better_cd_fuzzy_with_fzf true
```

If you prefer to use z:

```fish
set -U better_cd_fuzzy_with_fzf false
set -U better_cd_fuzzy_with_z true
set -U better_cd_fuzzy_with_z_like_z true
```

