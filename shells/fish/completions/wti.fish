complete -c wti -f
complete -c wti -s b -l base -x -d 'Base branch' -a '(git for-each-ref refs/heads/ --format="%(refname:short)" 2>/dev/null)'
complete -c wti -s n -l dry-run -d 'Print branch name and prompt without creating anything'
complete -c wti -s h -l help -d 'Show usage'
complete -c wti -x -a '(gh issue list --limit 50 --json number,title --jq \'.[] | "\(.number)\t\(.title)"\' 2>/dev/null)'
