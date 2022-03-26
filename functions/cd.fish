# -----------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2021 eth-p
# -----------------------------------------------------------------------------
function cd -d "Change the current working directory"
	set -g better_cd_last_pwd (pwd)

	if [ (count $argv) -eq 1 ]

		# If the directory literally exists, use that.
		if [ -e "$argv[1]" ]
			builtin cd $argv
			return $status
		end

		# If the path starts with ":/", it's relative to the repo top-level.
		if [ "$argv[1]" = ":" ] || [ (string sub $argv[1] --length=2) = ":/" ]
		
			
			# If not, let's try finding it relative to the top-level. 
			set -l target_path (string sub $argv[1] --start=3)
			set -l repo_root (__ethp_cd_repo_root)
			
			if [ $status -ne 0 ] # Not in a repo.
				echo "Not in a git repository" 1>&2
				return 1
			end
			
			if ! [ -e "$repo_root/$target_path" ] # It doesn't exist.
				echo "cd: The directory '$target_path' does not exist in the repository" 1>&2
				return 1
			end
			
			# Try to cd.
			builtin cd "$repo_root/$target_path"
			return $status
		end

		# If fzf is installed and it can find a directory, go there.
		if [ "$better_cd_disable_fzf" != "true" ] && command -vq fzf && command -vq fd
			set candidates (__bettercd_candidates $argv[1])

			# If there are no candidates, return early.
			if [ (count $candidates) -eq 0 ]
				builtin cd $argv
				return $status
			end

			# If there is only a single candidate, use that.
			if [ (count $candidates) -eq 1 ]
				builtin cd $candidates[1]
				return $status
			end

			# If there are multiple and they're not all children of a parent path, let the user select.
			set -l cut_length (string length $candidates[1])
			for candidate in $candidates[2..]
				if [ "$candidates[1]/" != (string sub --length=$cut_length $candidate)/ ]
					set -l user_selected ""

					if [ "$better_cd_disable_fzf_tiebreak" != true ]
						set user_selected (
							printf "%s\n" $candidates \
							| fzf --reverse --height=20% --min-height=7 \
							  --info=inline --header="Multiple paths matched...")
					end

					if [ -z "$user_selected" ]
						builtin cd $argv
						return $status
					end

					builtin cd "$user_selected"
					return $status
				end
			end

			# At this point, they're all children of a parent. Select the parent.
			builtin cd $candidates[1]
			return $status
		end
		
	end	
	
	# Default to the original behaviour.
	builtin cd $argv
	return $status
end

function __bettercd_candidates --description "Get candidates for fuzzy cd"
	if [ -z "$better_cd_search_depth" ]; set better_cd_search_depth 4; end
	if [ -z "$better_cd_search_ignore_paths" ]; set better_cd_search_ignore_paths "$HOME/Library" "$HOME/Downloads"; end
	if [ -z "$better_cd_search_ignore_names" ]; set better_cd_search_ignore_names "*.app" "*.localized" "*.photoslibrary"; end

	# Split into a serach root and search term (so we can search parents)
	set -l regex_escaped_home (string escape --style=regex "$HOME")
	set -l search_root (string match --regex "^(?:^$regex_escaped_home/|(?:../)*)" $argv[1])
	set -l search_term (string sub --start=(math (string length $search_root) + 1) $argv[1])

	# Get the "here" location so we can convert absolute paths into exclusion rules.
	set -l old_pwd (pwd)
	set -l here "$old_pwd/"
	if [ -n "$search_root" ]
		set here (cd "$search_root" || return $status && pwd; cd "$old_pwd")
	end
	
	set -l here_len (string length "$here")

	# Get a list of excluded paths.
	set -l excluded
	for excluded_dir in $better_cd_search_ignore_paths
		if [ "$here" = (string sub --length=$here_len "$excluded_dir/") ]
			set excluded $excluded --exclude (string sub --start=(math $here_len + 1) $excluded_dir)
		end
	end
	
	for excluded_dir in $better_cd_search_ignore_names
		set excluded $excluded --exclude $excluded_dir
	end

	# Use fd and fzf to get a list of candidates.
	if [ -n "$search_root" ]
		cd $search_root || return $status
	end

	fd . --type=d --maxdepth="$better_cd_search_depth" $excluded \
		| fzf --filter "$search_term" \
		| sed 's/^\.\//'(string replace --all '/' '\/' (string escape --style=regex $search_root))/ \
		| sort

	cd "$old_pwd"

end

function cdno --description "Undo the last `cd`"
	builtin cd "$better_cd_last_pwd"
	return $status
end

