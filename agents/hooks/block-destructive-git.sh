#!/usr/bin/env bash
# PreToolUse hook: hard-block destructive git/gh commands.
# Reads tool_input JSON on stdin, emits {permissionDecision: "deny"} when matched.
# Rules enforced here are intentionally NOT duplicated in CLAUDE.md.

set -euo pipefail

raw=$(cat)
cmd=$(printf '%s' "$raw" | jq -r '.tool_input.command // ""')

# Empty / non-shell invocations — nothing to check.
[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Inspect one parsed sub-command (argv array). Calls deny() if it matches a rule.
check_argv() {
  local -a argv=("$@")
  [ ${#argv[@]} -lt 2 ] && return 0
  local prog=${argv[0]} sub=${argv[1]}
  [[ "$prog" == "git" || "$prog" == "gh" ]] || return 0

  local -a rest=("${argv[@]:2}")
  local a b i

  case "$prog $sub" in
    "git commit")
      deny "Blocked by hook: 'git commit' is reserved for Jaren. Stage changes and present a commit message for approval instead."
      ;;
    "git push")
      for a in "${rest[@]}"; do
        case "$a" in
          -f|--force|--force=*|--force-with-lease|--force-with-lease=*|--force-if-includes|--force-if-includes=*)
            deny "Blocked by hook: force-push is destructive. Ask Jaren to push force changes manually."
            ;;
        esac
      done
      ;;
    "git reset")
      for a in "${rest[@]}"; do
        if [[ "$a" == "--hard" ]]; then
          deny "Blocked by hook: 'git reset --hard' discards uncommitted work. Use 'git stash' or ask Jaren."
        fi
      done
      ;;
    "git clean")
      for a in "${rest[@]}"; do
        # short-flag cluster containing 'f' (e.g. -f, -fd, -xdf)
        if [[ "$a" =~ ^-[a-zA-Z]*f[a-zA-Z]*$ ]]; then
          deny "Blocked by hook: 'git clean -f' deletes untracked files. Ask Jaren first."
        fi
        if [[ "$a" == "--force" ]]; then
          deny "Blocked by hook: 'git clean --force' deletes untracked files. Ask Jaren first."
        fi
      done
      ;;
    "git branch")
      for ((i=0; i<${#rest[@]}; i++)); do
        a=${rest[i]}
        if [[ "$a" == "-D" ]]; then
          deny "Blocked by hook: force-deleting branches is destructive."
        fi
        if [[ "$a" == "--delete" ]]; then
          for b in "${rest[@]:$((i+1))}"; do
            if [[ "$b" == "--force" ]]; then
              deny "Blocked by hook: force-deleting branches is destructive."
            fi
          done
        fi
      done
      ;;
    "git checkout")
      # `git checkout -- <paths>` or `git checkout .` discard working-tree changes.
      for a in "${rest[@]}"; do
        if [[ "$a" == "--" || "$a" == "." ]]; then
          deny "Blocked by hook: 'git checkout -- ...' / 'git checkout .' discards working-tree changes."
        fi
      done
      ;;
    "git restore")
      # `git restore .` (and `--staged .`) reverts working-tree or index paths.
      for a in "${rest[@]}"; do
        if [[ "$a" == "." ]]; then
          deny "Blocked by hook: 'git restore .' discards working-tree/index changes."
        fi
      done
      ;;
    "gh pr")
      a=${rest[0]:-}
      case "$a" in
        review|comment|merge|reply|close|reopen)
          deny "Blocked by hook: peer-interaction gh commands (review/comment/merge/reply/close) must be done by Jaren."
          ;;
      esac
      ;;
    "gh issue")
      a=${rest[0]:-}
      case "$a" in
        comment|close|reopen)
          deny "Blocked by hook: peer-interaction gh commands (comment/close/reopen) must be done by Jaren."
          ;;
      esac
      ;;
  esac
}

# Split the raw command on shell control operators so each sub-command is inspected in isolation.
# This prevents false positives like `echo "git commit"` and still catches `git add . && git commit`.
normalized=$(printf '%s' "$cmd" | sed -E 's/(\|\|?|&&|;)/\n/g')

while IFS= read -r sub; do
  [ -z "$sub" ] && continue
  # Word-split the sub-command. `read -ra` skips leading IFS and does not honor quotes,
  # which is exactly what we want: `echo "git commit"` tokenizes as (echo, "git, commit")
  # so argv[0] is `echo` — not matched.
  read -ra argv <<< "$sub"
  check_argv "${argv[@]}"
done <<< "$normalized"

exit 0
