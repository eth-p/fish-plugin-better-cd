# Better `cd` for Fish Shell

A better version of `cd` (and `pushd`) for your Fish shell.


## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```
fisher add eth-p/fish-plugin-better-cd
```

You can also alias `cd` to `bettercd`, if you like:

```fish
alias cd bettercd
alias cdun bettercd --undo
```

If you're familiar with `fzf` or `z`, there's a couple of recommended defaults:

<details><summary>Like fzf:</summary>

Fuzzily enter part of the path name, and a `fzf` prompt will be displayed if there are multiple matches.

```fish
set -U bettercd_resolve  fzf
set -U bettercd_tiebreak common,fzf
```

</details>

<details><summary>Like z:</summary>

Fuzzily enter part of the path name, and the common parent or highest weighted candidate will be used.

```fish
set -U bettercd_resolve  z,fzf
set -U bettercd_tiebreak common,z
set -U bettercd_search_z all
```

</details>



## Features

**Change directories with `:/path-relative-to-git-root`.**  
Just like `git add`, and with completion support.

```fish
$ git init
$ mkdir folder
$ mkdir -p other/folder
$ bettercd folder && pwd
/repo/folder

$ bettercd :/other/folder && pwd
/repo/other/folder
```



**Fuzzy find your directories with `fzf` or `z`**  
(requires [fzf](https://github.com/junegunn/fzf) and either [fd](https://github.com/sharkdp/fd) or [z](https://github.com/jethrokuan/z); must be enabled, see below)

```console
$ mkdir -p foo/bar/baz
$ mkdir -p foo/cat/dog
$ bettercd baz && pwd
/tmp/foo/bar/baz

$ bettercd ../../dog && pwd
/tmp/foo/cat/dog

$ bettercd proj && pwd
/home/me/projects
```



**Undo your previous `bettercd`.**   
Did you not mean to change to that directory?

```console
$ pwd
/home/me/desktop

$ bettercd ~/downloads && pwd
/home/me/downloads

$ bettercd --undo && pwd
/home/me/desktop
```



## Configuration

All configuration is done with variables, preferably with `set -U` for universal variables.

### Features

- `bettercd_resolve` (default: `fzf`, format: `resolver,resolver,...`)  
  Specifies which [resolvers](#resolvers) are used for populating the list of candidate directories.

- `bettercd_tiebreak` (default: `common,fzf`, format: `tiebreaker,tiebreaker,...`)  
  Specifies which [tiebreakers](#tiebreakers) are used for picking between multiple candidate directories.

- `bettercd_reporel` (default: `true`, format: `true` or `false`)  
  If enabled, allows navigating relative to the git repo root with `:/path/from/root`.
  Fuzzy matching is also still available for this!

### Search Settings

- `bettercd_search_depth` (default: `4`, format: `number`)  
  Specifies how deep of a search the [fzf resolver](#fzf-resolver) will do.

- `bettercd_search_z` (default: `best`, format: `all`, `best` or `common`)  
  When using the [z resolver](#z-resolver), what answers returned by `z` will be used.

- `bettercd_user_search_exclude_paths` (format: array)  
  Speicifes a list of absolute paths that the [fzf resolver](#fzf-resolver) will ignore.

- `bettercd_user_search_exclude_names` (format: array)  
  Speicifes a list of file globs that the [fzf resolver](#fzf-resolver) will ignore.

### Tweaks

- `bettercd_fzf_args` (format: array)  
  A list of arguments passed to `fzf` in the [fzf resolver](#fzf-resolver).
- `bettercd_fzf_interactive_args` (default: something nice, format: array)  
  A list of arguments passed to `fzf` in the [fzf tiebreaker](#fzf-tiebreaker).
- `bettercd_fd_args` (format: array)  
  A list of arguments passed to `fd` in the [fzf resolver](#fzf-resolver).



## Resolvers

Bettercd's fuzzy matching works by collecting a list of candidate paths for the provided search path. This is done with resolver functions, which take the search path and print out a list of candidate paths.

### fzf-resolver

> (requires [fzf](https://github.com/junegunn/fzf) and [fd](https://github.com/sharkdp/fd))

The `fzf` resolver uses a combination of `fd` and `fzf` to return a list of fuzzily-matching paths under the target directory. It is *very* likely to return a ton of candidates, and it's recommended to use the `fzf` tiebreaker to pick one.

### z-resolver

> (requires [z](https://github.com/jethrokuan/z))

The `z` resolver uses `z` to print a list of paths that would be matched by `z`.
You can configure how many paths are returned by setting `bettercd_search_z` to either `best`, `all`, or `common`.

### Custom Resolvers

You can create custom resolvers by defining a `__bettercd_resolve_with_RESOLVER` function:

```fish
function __bettercd_resolve_with_homedir
	for dir in $HOME/*
		printf "%s\n" -- "$HOME"
	end
end
```



## Tiebreakers

Whenever bettercd's fuzzy matching returns more than one candidate, it needs to be narrowed down to a single result. For this, there are tiebreaker functions.

### fzf-tiebreaker

> (requires [fzf](https://github.com/junegunn/fzf))

The `fzf` tiebreaker displays a list of candidates, and asks you to pick one.

### z-tiebreaker

> (requires [z](https://github.com/jethrokuan/z) and perl)

The `z` tiebreaker uses the `z` database to pick the highest-weighted directory from the list of candidates. If no candidate is located in the database, the next tiebreaker will be used instead.

### common-tiebreaker

The `common` tiebreaker simply picks the common parent of all candiates, if there is one. This is good for navigating to a parent directory without considering any of its children.

### Custom Tiebreakers

You can create custom resolvers by defining a `__bettercd_tiebreak_with_TIEBREAKER` function:

```fish
function __bettercd_tiebreak_with_first
    argparse 'x-nothing' -- $argv || return $status
	echo $argv[1]
end
```

