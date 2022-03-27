# ---------------------------------------------------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2021-2022 eth-p
# ---------------------------------------------------------------------------------------------------------------------

function bettercd_resolve --description "Resolves a cd path"
	argparse -i 'd/debug' 'dump' 'null-is=' 'from=' -- $argv || return $status
	set -l ret_cwd "$PWD"
	set -l ret_status 0

	# If argv is empty, return early.
	if test (count $argv) -eq 0
		if test -n "$_flag_null_is"
			printf "%s\n" "$_flag_null_is"
			return 0
		end

		printf "bettercd_resolve: requires path to resolve\n"
		return 1
	end

	# If '--from' is passed, cd into that.
	if test -n "$_flag_from"
		builtin cd "$_flag_from" 2>/dev/null
		if test $status -ne 0
			printf "%s: %s\n" (status current-command) (builtin cd "$_flag_from" 2>&1 | string sub --start=5) 1>&2
			return 1
		end
	end

	# If '--debug' is passed, call the resolve function without stderr redirected.
	if test -n "$_flag_debug"
		__bettercd_resolve_do --debug $_flag_dump -- $argv 3>&2
		set ret_status $status
	else
		__bettercd_resolve_do $_flag_dump -- $argv 3>/dev/null
		set ret_status $status
	end

	# Reset the current directory and return the status of the resolve function.
	builtin cd "$ret_cwd" 2>/dev/null
	return $ret_status
end


function __bettercd_resolve_do --description "[internal] Resolves a cd path"
	argparse 'debug' 'dump' 'resolve=' 'tiebreak=' -- $argv || return $status
	
	# Get the array of resolvers.
	set -l resolve $_flag_resolve
	if test -z $resolve
		set resolve $bettercd_resolve
	end
	set resolve (string split -- ',' $resolve)
	for resolve_name in $resolve
		set -l resolve_fn "__bettercd_resolve_with_$resolve_name"
		printf "[resolve] using resolver '%s'\n" "$resolve_fn" 1>&3
		if not type -q "$resolve_fn"
			printf "%s: unsupported resolver '%s'\n" (status current-command) "$resolve_name" 1>&2
			return 1
		end
	end

	# Get the array of tiebreakers.
	set -l tiebreak $_flag_tiebreak
	if test -z $tiebreak
		set tiebreak $bettercd_tiebreak
	end
	set tiebreak (string split -- ',' $tiebreak)
	for tiebreak_name in $tiebreak
		set -l tiebreak_fn "__bettercd_tiebreak_with_$tiebreak_name"
		printf "[resolve] using tiebreaker '%s'\n" "$tiebreak_fn" 1>&3
		if not type -q "$tiebreak_fn"
			printf "%s: unsupported tiebreaker '%s'\n" (status current-command) "$tiebreak_name" 1>&2
			return 1
		end
	end

	# Get all the candidates.
	set -l candidates (
		for resolve_name in $resolve
			set -l resolve_status 0
			if test -n "$_flag_debug"
				"__bettercd_resolve_with_$resolve_name" -- $argv 3>&2
				set resolve_status $status
			else
				"__bettercd_resolve_with_$resolve_name" -- $argv 3>/dev/null
				set resolve_status $status
			end

			if test $status -ne 0
				return $resolve_status
			end
		end
	)

	set -l candidates_count (count $candidates)

	# If '--dump' is set, just dump all the candidates.
	if test -n "$_flag_dump"
		printf "%s\n" $candidates
		return 0
	end

	# If there are no candidates, return with an error.
	if test $candidates_count -eq 0
		printf "%s: The directory '%s' was not found\n" (status current-command) $argv[1] 1>&2
		return 1
	end

	# If there is a single candidate, return it.
	if test $candidates_count -eq 1
		printf "%s\n" $candidates[1]
		return 0
	end

	# If there are multiple candidates, defer to tiebreakers.
	for tiebreak_name in $tiebreak
		printf "[tiebreak] trying tiebreaker '%s'\n" "$tiebreak_name" 1>&3
		set -l tiebreaker_status
		set -l tiebreaker_results

		if test -n "$_flag_debug"
			set tiebreaker_results ("__bettercd_tiebreak_with_$tiebreak_name" -- $candidates 3>&2)
			set tiebreaker_status $status
		else
			set tiebreaker_results ("__bettercd_tiebreak_with_$tiebreak_name" -- $candidates 3>/dev/null)
			set tiebreaker_status $status
		end

		if test "$tiebreaker_status" -eq 0
			set -l tiebreaker_results_count (count $tiebreaker_results)
			if test $tiebreaker_results_count -eq 1
				# If it's a single result, that's what it resolved down to.
				printf "[tiebreak] tiebreaker returned match\n" 1>&3
				echo $tiebreaker_results
				return 0
			else if test $tiebreaker_results_count -ge 2
				printf "[tiebreak] tiebreaker returned subset\n" 1>&3
				# If it's multiple results, filter down the list for the next resolver.
				set candidates $tiebreaker_results
			else
				printf "[tiebreak] tiebreaker returned nothing\n" 1>&3
			end
		end
	end

	# No tiebreaker worked, so show an error.
	printf "%s: Multiple candidates for '%s'\n" (status current-command) $argv[1] 1>&2
	return 1
end

# ---------------------------------------------------------------------------------------------------------------------
# Resolvers:
# ---------------------------------------------------------------------------------------------------------------------

function __bettercd_resolve_with_z --description "[internal] Resolves a cd path using z"
	argparse 'mode=' -- $argv || return $status
	__bettercd_requires z     || return $status
	
	# If --mode is set, use that. Otherwise, use $bettercd_search_z.
	set -l mode "$_flag_mode"
	if test -z "$mode"; set mode "$bettercd_search_z"; end

	switch "$mode"

		# Pick the best match.
		case "best"
			z --list "$argv[1]" 2>/dev/null | grep -v '^common:' | awk '{ print $2 }' | head -n1

		# Pick all matches.
		case "all"
			z --list "$argv[1]" 2>/dev/null | awk '{ print $2 }'

		# Pick the common directory, or best otherwise.
		case "common" 
			set -l common_dir (z --list "$argv[1]" 2>&1 | awk '/^common:/{ print $2 }' | head -n1)
			if test -n "$common_dir"
				echo "$common_dir"
			else
				__bettercd_resolve_with_z --mode=best "$argv[1]"
			end

		# Unknown.
		case *
			printf "bettercd: '%s' is not a supported 'z' mode\n" "$bettercd_search_z" 1>&2
			return 1
	end
end

function __bettercd_resolve_with_fzf --description "[internal] Resolves a cd path using fd and fzf"
	argparse 'x-nothing' -- $argv || return $status
	__bettercd_requires fzf       || return $status
	__bettercd_requires fd        || return $status

	# In order to properly search parents, we need to perform the searching from the topmost directory.
	# To do this, we split the requested path into a "search root" (topmost dir) and "search term" (start of search).
	#
	# Example: ../../desk
	#   search_root -> ../../
	#   search_term -> desk
	set -l regex_escaped_home (string escape --style=regex -- "$HOME")
	set -l search_root (string match --regex -- "^(?:^$regex_escaped_home/|(?:../)*)" "$argv[1]")
	set -l search_term (string sub --start=(math (string length $search_root) + 1) -- "$argv[1]")
	printf "[resolve:fzf] search_root: %s\n" "$search_root" 1>&3
	printf "[resolve:fzf] search_term: %s\n" "$search_term" 1>&3

	# Navigate to the search root and get its full path, in order to build the exclusion rules.
	set -l original_pwd "$PWD"
	set -l here "$PWD/"

	if test -n "$search_root"
		builtin cd "$search_root" 2>/dev/null
		if test $status -ne 0
			printf "%s: %s\n" (status current-command) (builtin cd "$search_root" 2>&1 | string sub --start=5)
			return 1
		end

		set here "$PWD/"
	end

	set -l here_len (string length -- "$here")

	# Build the `--exclude` arguments for `fd`.
	set -l exclude_args

	set -l excluded_paths $bettercd_default_search_exclude_paths $bettercd_user_search_exclude_paths
	set -l excluded_files $bettercd_default_search_exclude_files $bettercd_user_search_exclude_files
	
	for excl in $excluded_files
		set exclude_args $exclude_args --exclude="$excl"
	end

	for excl in $excluded_paths
		# If the excluded path resides in the same directory that we're searching,
		# then we get the relative path and add it to the exclusion arguments.
		printf "[resolve:fzf] exclude is '%s' under '%s'?\n" "$excl/" "$here" 1>&3 

		if test "$here" = (string sub --length=$here_len -- "$excl/")
			set exclude_args $exclude_args \
				--exclude=(string sub --start=(math $here_len + 1) -- "$excl")
		end
	end

	# Use fd to find all files, and filter it down with fzf.
	# After that, use sed to replace the leading './' with the relative path to the original pwd.
	__bettercd_run fd . --type=d --maxdepth="$bettercd_search_depth" $bettercd_fd_args $exclude_args \
		| __bettercd_run fzf $bettercd_fzf_args --filter "$search_term" \
		| sed 's/^\.\//'(string replace --all '/' '\/' (string escape --style=regex -- $search_root))/

	builtin cd "$original_pwd"
end

# ---------------------------------------------------------------------------------------------------------------------
# Tiebreakers:
# ---------------------------------------------------------------------------------------------------------------------

function __bettercd_tiebreak_with_common --description "[internal] Tiebreak candidates using a common parent"
	argparse 'x-nothing' -- $argv || return $status
	set -l candidates $argv

	# Check to see if all candiates share a parent path.
	# If they do, use that.
	set -l parent_no_slash (printf "%s\n" $candidates | sort | head -n1)
	set -l parent          "$parent_no_slash/"
	set -l parent_len      (string length -- "$parent")
	printf "[tiebreak:common] expecting parent '%s'\n" "$parent" 1>&3 

	for candidate in $candidates
		if test (string sub --length=$parent_len -- "$candidate/") != "$parent"
			return 0
		end 
	end

	printf "%s\n" "$parent_no_slash"
end

function __bettercd_tiebreak_with_fzf --description "[internal] Tiebreak candidates interactively with fzf"
	argparse 'x-nothing' -- $argv || return $status
	__bettercd_requires fzf       || return $status

	printf "%s\n" $argv | sort | fzf $bettercd_fzf_interactive_args --header "Multiple paths matched."
	return $status
end

function __bettercd_tiebreak_with_z --description "[internal] Tiebreak candidates using the best match from the z database"
	argparse 'x-nothing' -- $argv || return $status
	__bettercd_requires z         || return $status
	__bettercd_requires perl      || return $status
	set -l candidates $argv

	perl -e '
		use Cwd;
		my $handle;
		
		# Read the database into a map.
		my %database;
		open $handle, "<", $ARGV[1];
		while (<$handle>) {
			$_ =~ s/\n$//;
			my ($weight, $entry) = split / +/,$_,2;
			$database{$entry} = $weight;
		}
		close $handle;
		
		# Find the best candidate.
		open $handle, "<", $ARGV[0];
		my $best_weight = 0;
		my $best_path = "";
		my $cwd = getcwd();
		while (<$handle>) {
			$_ =~ s/\n$//;
			my $target = $_;
			my $full_target = $cwd . "/" . $target;
			if (exists $database{$full_target}) {
				my $weight = $database{$full_target};
				if ($weight gt $best_weight) {
					$best_weight = $weight;
					$best_path   = $target;
				}
			}
		}
		close $handle;
		print "${best_path}";
	' (printf "%s\n" $candidates | psub) (z --list 2>/dev/null | psub)
end

# ---------------------------------------------------------------------------------------------------------------------
# Utils:
# ---------------------------------------------------------------------------------------------------------------------

function __bettercd_requires --description "[internal] Returns an error if a command is not installed"
	if not type -q $argv[1]
		printf "bettercd: requires '%s', but not installed\n" "$argv[1]"
		return 1
	end
end

function __bettercd_run --description "[internal] Print command to fd3 and run it"
	for arg in $argv[2..]
		printf "[exec:%s] %s\n" "$argv[1]" "$arg"
	end 1>&3
	$argv
end

