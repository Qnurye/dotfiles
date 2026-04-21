#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' EXIT

raw=$(cat)

[[ -z "${DIVERGE_MONITOR_DIR:-}" ]] && exit 0

to=$(printf '%s' "$raw" | jq -r '.tool_input.to // ""')
message=$(printf '%s' "$raw" | jq -r '.tool_input.message // ""')

SIGNALS="PHASE_DONE PHASE_TESTS_DONE TESTS_WRITTEN BLOCKED NEEDS_CONTEXT CONVENTION_START CONVENTION_REVIEW CONVENTION_ROUND_2 CONVENTION_AGREED CONVENTION_DEADLOCK MERGE_AND_VERIFY FIXES_APPLIED REVIEW_COMPLETE FIX_REQUEST FIX_DONE DECISION TEST_FEEDBACK"

first_word=$(printf '%s' "$message" | head -1 | awk '{print $1}' | sed 's/:$//')

signal_name=""
for sig in $SIGNALS; do
  if [[ "$first_word" == "$sig" ]]; then
    signal_name="$sig"
    break
  fi
done

EMIT_SH="${DIVERGE_EMIT_SH:-$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh}"
if [[ ! -f "$EMIT_SH" ]]; then
  # Fallback: resolve relative to this hook's own location
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  EMIT_SH="$_self_dir/../skills/diverge/monitor/emit.sh"
fi
# shellcheck source=/dev/null
source "$EMIT_SH" 2>/dev/null || exit 0

if [[ -n "$signal_name" ]]; then
  data=$(jq -cn --arg to "$to" --arg msg "$message" '{to: $to, message: $msg}')
  diverge_emit signal "$signal_name" "$data"
else
  preview=$(printf '%s' "$message" | head -c 120)
  data=$(jq -cn --arg to "$to" --arg preview "$preview" '{to: $to, preview: $preview}')
  diverge_emit signal message "$data"
fi

exit 0
