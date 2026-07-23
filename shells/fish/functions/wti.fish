function wti --description "GitHub issues → branch name → worktree → Claude plan session"
    argparse 'b/base=' 'n/dry-run' 'h/help' -- $argv; or return 1

    if set -q _flag_help
        echo "Usage: wti [issue-number ...] [-b/--base <branch>] [-n/--dry-run]"
        echo "Without arguments, pick open issues with fzf (TAB for multi-select)."
        return 0
    end

    if not git rev-parse --git-dir &>/dev/null
        echo "wti: not a git repository" >&2
        return 1
    end

    set -l issues (string replace -r '^#' '' $argv)
    if test (count $issues) -eq 0
        set issues (gh issue list --limit 100 --json number,title --jq 'sort_by(-.number) | .[] | "\(.number)\t\(.title)"' \
            | fzf --multi --layout=reverse --delimiter \t --preview 'gh issue view {1}' --preview-window 'right:60%:wrap' \
            | cut -f1)
        test (count $issues) -gt 0; or return 1
    end

    set -l issue_lines
    for n in $issues
        set -l raw (gh issue view $n --json number,title --jq '"#\(.number) \(.title)"')
        if test $status -ne 0
            echo "wti: cannot read issue #$n" >&2
            return 1
        end
        set -a issue_lines (string join ' ' -- $raw | string replace -ra '\s+' ' ' | string trim)
    end

    set -l repo (gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
    test -n "$repo"; or set repo (basename (git rev-parse --show-toplevel))
    set -l recent_branches (git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -12)

    set -l branch_prompt "Output ONLY a git branch name. No backticks, no quotes, no explanation.

Repository: $repo
Issues to implement:
"(string join \n $issue_lines | string collect)"

Recent branches in this repository — match their naming convention (same prefix style, same use of issue numbers):
"(string join \n $recent_branches | string collect)"

Rules: lowercase, hyphen-separated words, under 40 chars after any prefix."

    echo "wti: generating branch name..." >&2
    set -l out (env MAX_THINKING_TOKENS=0 claude -p --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt='' $branch_prompt 2>/dev/null | string replace -a '`' '')
    set -l branch (string trim -- $out[-1])

    if not string match -rq '^[a-zA-Z0-9][a-zA-Z0-9._/-]{2,60}$' -- $branch
        set branch "issue-"(string join '-' $issues)
        echo "wti: branch generation failed, falling back to $branch" >&2
    end

    set -l plan_prompt "Plan the implementation of these GitHub issues in $repo:
"(string join \n $issue_lines | string collect)"

First read each issue's full body and discussion with 'gh issue view <number> --comments', then explore the relevant code. Plan before implementing: present the implementation plan and wait for my confirmation before writing any code."

    if set -q _flag_dry_run
        echo "branch: $branch"
        echo "---"
        echo $plan_prompt
        return 0
    end

    set -l wt_args switch --create $branch
    set -q _flag_base; and set -a wt_args --base $_flag_base
    wt $wt_args -x claude -- --permission-mode auto $plan_prompt
end
