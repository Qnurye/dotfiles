# Overrides fish's bundled claude completion, which lags behind the CLI.
complete -c claude -f -a '(__help_complete)'
complete -c claude -l add-dir -l settings -l mcp-config -l debug-file -l plugin-dir -rF
