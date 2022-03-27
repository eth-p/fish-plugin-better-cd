complete --erase --command bettercd
complete --command bettercd --require-parameter --no-files --arguments '(__bettercd_complete)' 

function __bettercd_complete
	if test "$bettercd_reporel" = "true"
		__bettercd_complete_git && return
	end

	__fish_complete_directories

	# set -l complete (commandline --current-token)
	# __bettercd_resolve_do --dump --tiebreak= -- "$complete"
end

function __bettercd_complete_git
	set -l repo_root (git rev-parse --show-toplevel)
	if test $status -ne 0
		return 1
	end
	
	set -l tokens (commandline -bo)
	set -l token $tokens[2]
	
	# If the path is empty, we should offer suggestions from the repo root.
	if test "$token" = ""
		if ! test "$repo_root" = "$PWD"
			__bettercd_complete_git_suggest_from "$repo_root" ""
			return 0
		end
		return 1
	end
	
	# If the path doesn't start with ":/", we aren't going to complete it.
	if test "$token" != ":" && test (string sub "$token" --length=2) != ":/"
		return 1
	end
	
	# Extract the dirname and basename from the token.
	set token (string sub "$token" --start=3)
	if test (string sub "$token" --start=-1) = "/"
		set token "$token."
	end
	
	set -l token_dirname (dirname -- "$token")
	set -l token_basename (basename -- "$token")
	
	# If the dirname is "." (a quirk of using dirname with no parent dir), we're looking at
	# the repo root. Treat it specially.
	if test "$token_dirname" = "."
		__bettercd_complete_git_suggest_from "$repo_root" ""
		return 0
	end

	# Print suggestions.
	if test -d "$repo_root/$token_dirname"
		__bettercd_complete_git_suggest_from "$repo_root" "/$token_dirname"
		return 0
	end

	return 1
end

function __bettercd_complete_git_suggest_from -d ""
	set -l file
	set -l ltrim (math (string length "$argv[1]") + 2)
	for file in "$argv[1]$argv[2]"/*
		if test -d "$file"
			printf ":/%s/\tGit\n" (string sub "$file" --start=$ltrim)
		end
	end
end

