# -----------------------------------------------------------------------------
# Wrappers around the fish cd and pushd commands for quality of life improvements.
# Copyright (C) 2021 eth-p
# -----------------------------------------------------------------------------
function cd -d "Change the current working directory"
	if [ (count $argv) -eq 1 ]
	
		# If the path starts with ":/", it's relative to the repo top-level.
		if [ "$argv[1]" = ":" ] || [ (string sub $argv[1] --length=2) = ":/" ]
		
			# If a relative file already exists with that name, it should take priority. 
			if [ -e "$argv[1]" ]
				builtin cd $argv
				return $status
			end
			
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
		
	end
	
	# Default to the original behaviour.
	builtin cd $argv
end
