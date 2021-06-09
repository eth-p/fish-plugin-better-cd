# -----------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2021 eth-p
# -----------------------------------------------------------------------------
function __ethp_cd_repo_root -d "Gets the root of the git repo"
	if not command -sq git
		return 1
	end
	
	set -l toplevel (command git rev-parse --show-toplevel 2>/dev/null)
	if [ -z "$toplevel" ]
		return 1
	end
	
	echo "$toplevel"
	return 0
end
