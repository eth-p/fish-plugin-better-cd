# ---------------------------------------------------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2021-2022 eth-p
# ---------------------------------------------------------------------------------------------------------------------

function bettercd --description "Change directory"
	set -l resolve_args
	set -l resolve_from
	set -l resolve_query "$argv[1]"
	set -l flag_undo

	# If the command was aliased to `cd`, don't accept arguments.
	set -l _flag_print_config
	if test (status current-command) != "cd"
		argparse 'print-config' 'u/undo' -- $argv || return $status

		set flag_undo $_flag_undo
		if test -n "$_flag_print_config"
			__bettercd_show_config
			return 0
		end
	end

	# If '--undo' is provided, go back to the previous directory.
	if test -n "$flag_undo"
		builtin cd -- "$__bettercd_last_pwd"
		return $status
	else
		set -g __bettercd_last_pwd "$PWD"
	end

	# If the target path exists as-is, use that.
	if test -d "$resolve_query"
		builtin cd -- "$resolve_query"
		return $status
	end

	# If the target starts with ":" and we're in a git repo, navigate.
	if test "$bettercd_reporel" = "true"
		if string match --regex '^:(?:$|/)' -- "$resolve_query" >/dev/null
			set -l repo_top (
				git rev-parse --show-toplevel 2>/dev/null || begin
					printf "%s: Not in a git repository\n" (status current-command) 1>&2
					return 1
				end
			)

			# If the target is literally ":", it's the repo root.
			if test "$resolve_query" = ":"
				builtin cd -- "$repo_top"
				return $status
			end

			# If the target parth exists, use that.
			if test -d "$repo_top$resolve_query"
				builtin cd -- "$repo_top$resolve_query"
				return $status
			end

			# Otherwise, adjust the path resolve parameters.
			set resolve_query (string replace --regex '^:(?:$|/)' '' "$resolve_query")
			set resolve_from "$repo_top"
			set resolve_args $resolve_args --from="$repo_top"
		end
	end

	# Resolve and cd to the directory.
	set -l resolved (bettercd_resolve --null-is=. $resolve_args -- "$resolve_query" || return $status)
	if test -n "$resolved"
		builtin cd -- (string join "/" $resolve_from "$resolved")
		return $status
	end

	# Use the builtin cd.
	builtin cd $argv
	return $status
end

function __bettercd_show_config --description "[internal] Print all config vars"
	for var in $__bettercd_config_vars
		set -l vals (eval "printf '%s\n' \$$var")
		printf "\x1B[33m%s\x1B[0m" "$var"
		for val in $vals
			printf " %s" (string escape -- $val)
		end
		printf "\n"
	end
end

# ---------------------------------------------------------------------------------------------------------------------
# Config:
# ---------------------------------------------------------------------------------------------------------------------

# Default Config
set -g __bettercd_config_vars
function __bettercd_default --description "[internal] Sets a default config option"
	set -a __bettercd_config_vars "$argv[1]"
	if not set -q "$argv[1]"
		set -g "$argv[1]" $argv[2..]
	end
end

__bettercd_default bettercd_fzf_args
__bettercd_default bettercd_fzf_interactive_args  --height=20% --min-height=7 --reverse --info=inline
__bettercd_default bettercd_fd_args

__bettercd_default bettercd_resolve               fzf
__bettercd_default bettercd_tiebreak              common,fzf
__bettercd_default bettercd_reporel               true

__bettercd_default bettercd_search_depth          4
__bettercd_default bettercd_search_z              best

__bettercd_default bettercd_user_search_exclude_paths
__bettercd_default bettercd_default_search_exclude_paths \
	"$HOME/Library" \
	"$HOME/Applications" \
	"/Applications" \
	"/Volumes"

__bettercd_default bettercd_user_search_exclude_files
__bettercd_default bettercd_default_search_exclude_files \
	"*.app" \
	"*.localized" \
	"*.photoslibrary" \
	".git"

