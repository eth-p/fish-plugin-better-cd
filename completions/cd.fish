complete -e -c cd -F 
complete -c cd -a '(__fish_complete_cd)' # Built-in completions.
complete -c cd -a '(__ethp_complete_cd)' # Custom completions.
complete -c cd -n '__ethp_completing_cd' -f # Do not allow files when using ":"
