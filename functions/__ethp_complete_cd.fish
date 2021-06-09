# -----------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2018 eth-p
# -----------------------------------------------------------------------------
function __ethp_complete_cd -d "Completions for 'cd' relative to the repo top-level"
	set -l repo_root (__ethp_cd_repo_root)
	if [ $status -ne 0 ] # Not in a repo.
		return 1
	end
	
	set -l tokens (commandline -bo)
	set -l token $tokens[2]
	
	# If the path is empty, we should offer suggestions from the repo root.
	if [ "$token" = "" ]
		if ! [ "$repo_root" = (pwd) ] 
			__ethp_complete_cd_suggest_from "$repo_root" ""
		end
		return 0
	end
	
	# If the path doesn't start with ":/", we aren't going to complete it.
	if [ "$token" != ":" ] && [ (string sub "$token" --length=2) != ":/" ]
		return 0
	end
	
	# Extract the dirname and basename from the token.
	set token (string sub "$token" --start=3)
	if [ (string sub "$token" --start=-1) = "/" ]
		set token "$token."
	end
	
	set -l token_dirname (dirname -- "$token")
	set -l token_basename (basename -- "$token")
	
	# If the dirname is "." (a quirk of using dirname with no parent dir), we're looking at
	# the repo root. Treat it specially.
	if [ "$token_dirname" = "." ]
		__ethp_complete_cd_suggest_from "$repo_root" ""
		return 0
	end

	# Print suggestions.
	if [ -d "$repo_root/$token_dirname" ]
		__ethp_complete_cd_suggest_from "$repo_root" "/$token_dirname"
	end
end

function __ethp_complete_cd_suggest_from -d ""
	set -l file
	set -l ltrim (math (string length "$argv[1]") + 2)
	for file in "$argv[1]$argv[2]"/*
		if [ -d "$file" ]
			printf ":/%s/\tgit\n" (string sub "$file" --start=$ltrim)
		end
	end
end
