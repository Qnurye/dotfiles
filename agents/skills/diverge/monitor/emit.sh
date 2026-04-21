#!/usr/bin/env bash
# Diverge monitor event emitter
#
# JSONL schema (one JSON object per line):
#   ts    — ISO 8601 UTC timestamp (YYYY-MM-DDTHH:MM:SSZ)
#   type  — signal | task | script | system
#   event — event name
#   data  — arbitrary JSON object (caller-supplied)
#
# Agent identity is NOT part of the base schema.
# Hook callers embed it inside data (e.g. data.to, data.owner).

diverge_emit() {
  [[ $# -lt 2 ]] && return 0
  [[ -z "${DIVERGE_MONITOR_DIR:-}" ]] && return 0

  local type="$1"
  local event="$2"
  local data="${3:-}"
  [[ -z "$data" ]] && data='{}'
  data="${data//$'\n'/}"

  (
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    printf '{"ts":"%s","type":"%s","event":"%s","data":%s}\n' \
      "$ts" "$type" "$event" "$data" \
      >> "${DIVERGE_MONITOR_DIR}/events.jsonl"
  ) 2>/dev/null || true
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  diverge_emit "$@"
fi
