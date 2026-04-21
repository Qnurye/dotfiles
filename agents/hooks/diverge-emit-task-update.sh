#!/usr/bin/env bash
set -euo pipefail
trap 'exit 0' EXIT

raw=$(cat)

[[ -z "${DIVERGE_MONITOR_DIR:-}" ]] && exit 0

tool_name=$(printf '%s' "$raw" | jq -r '.tool_name // "TaskUpdate"')
task_id=$(printf '%s' "$raw" | jq -r '.tool_input.taskId // .tool_input.id // ""')
status=$(printf '%s' "$raw" | jq -r '.tool_input.status // ""')
subject=$(printf '%s' "$raw" | jq -r '.tool_input.subject // ""')
owner=$(printf '%s' "$raw" | jq -r '.tool_input.owner // ""')

if [[ "$tool_name" == *Create* ]]; then
  event_name="task_create"
else
  event_name="task_update"
fi

data=$(jq -cn \
  --arg taskId "$task_id" \
  --arg status "$status" \
  --arg subject "$subject" \
  --arg owner "$owner" \
  '{taskId: $taskId, status: $status, subject: $subject, owner: $owner} | with_entries(select(.value != ""))')

EMIT_SH="${DIVERGE_EMIT_SH:-$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh}"
if [[ ! -f "$EMIT_SH" ]]; then
  # Fallback: resolve relative to this hook's own location
  _self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  EMIT_SH="$_self_dir/../skills/diverge/monitor/emit.sh"
fi
# shellcheck source=/dev/null
source "$EMIT_SH" 2>/dev/null || exit 0

diverge_emit task "$event_name" "$data"

if [[ ! -f "${DIVERGE_MONITOR_DIR}/task-dir" && -n "$task_id" ]]; then
  task_file=$(find ~/.claude/tasks -name "${task_id}.json" -maxdepth 2 -print -quit 2>/dev/null || true)
  if [[ -n "$task_file" ]]; then
    dirname "$task_file" > "${DIVERGE_MONITOR_DIR}/task-dir"
  fi
fi

exit 0
