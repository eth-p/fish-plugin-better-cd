# -----------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2018 eth-p
# -----------------------------------------------------------------------------
function __ethp_completing_cd -d "Checks if cd'ing relative to the repo root"
	set -l repo_root (__ethp_cd_repo_root)
	if [ $status -ne 0 ] # Not in a repo.
		return 1
	end
	
	set -l tokens (commandline -bo)
	set -l token $tokens[2]
	
	test "$token" = ":" || test (string sub "$token" --length=2) = ":/"
	return $status
end
