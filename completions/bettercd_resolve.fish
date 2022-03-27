complete --erase --command bettercd_resolve
complete --command bettercd_resolve --short-option d --long-option debug --description "Enable debug printing"
complete --command bettercd_resolve --long-option from --require-parameter --no-files --arguments '(__fish_complete_directories)' --description "Resolve under the context of a specific directory"

