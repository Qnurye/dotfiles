#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────
#
# migrate-sessions.sh \
#   --worktree-path <path>    Absolute path to the worktree being removed
#   --main-path <path>        Absolute path to the main/primary worktree
#
# Migrates Claude Code sessions from a worktree's project directory to
# the main repo's project directory, so `claude --resume` works after
# the worktree is deleted.
#
# Operations:
#   1. Rewrites `cwd` in session JSONL files (worktree path → main path)
#   2. Moves JSONL files + subdirs to the main project directory
#   3. Patches `history.jsonl` entries for affected sessions
#   4. Removes the now-empty worktree project directory
#
# Exit codes:
#   0  Sessions migrated (or none found)
#   1  Invalid arguments or missing dependencies
#
# ─── Parse Args ───────────────────────────────────────────────────────

wt_path=""
main_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree-path) wt_path="$2";  shift 2 ;;
    --main-path)     main_path="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Validate ─────────────────────────────────────────────────────────

missing=()
[[ -z "$wt_path" ]]  && missing+=("--worktree-path")
[[ -z "$main_path" ]] && missing+=("--main-path")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required args: ${missing[*]}" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required but not installed" >&2
  exit 1
fi

# Normalize: strip trailing slashes
wt_path="${wt_path%/}"
main_path="${main_path%/}"

if [[ "$wt_path" == "$main_path" ]]; then
  echo "Worktree path equals main path, nothing to migrate"
  exit 0
fi

# ─── Derive Claude Project Keys ──────────────────────────────────────
# Claude Code encodes project paths by replacing / and . with -
# e.g. /Users/foo/repo/.worktrees/feat → -Users-foo-repo--worktrees-feat

path_to_key() {
  printf '%s' "$1" | tr '/.' '-'
}

CLAUDE_DIR="${HOME}/.claude"
wt_key=$(path_to_key "$wt_path")
main_key=$(path_to_key "$main_path")

wt_project_dir="${CLAUDE_DIR}/projects/${wt_key}"
main_project_dir="${CLAUDE_DIR}/projects/${main_key}"

if [[ ! -d "$wt_project_dir" ]]; then
  echo "No Claude sessions found for worktree"
  exit 0
fi

# ─── Collect Session Files ────────────────────────────────────────────

shopt -s nullglob
jsonl_files=("${wt_project_dir}"/*.jsonl)
shopt -u nullglob

if [[ ${#jsonl_files[@]} -eq 0 ]]; then
  echo "No session files to migrate"
  exit 0
fi

# ─── Migrate ──────────────────────────────────────────────────────────

mkdir -p "$main_project_dir"

migrated=0
session_ids=()

for jsonl in "${jsonl_files[@]}"; do
  filename=$(basename "$jsonl")
  session_id="${filename%.jsonl}"
  session_ids+=("$session_id")

  # Rewrite cwd field in every JSONL line
  tmp="${jsonl}.migrating"
  jq -c --arg old "$wt_path" --arg new "$main_path" '
    if .cwd == $old then .cwd = $new else . end
  ' "$jsonl" > "$tmp"

  mv "$tmp" "${main_project_dir}/${filename}"
  rm "$jsonl"
  migrated=$((migrated + 1))
done

# Move session subdirectories (if any)
shopt -s nullglob
for subdir in "${wt_project_dir}"/*/; do
  dirname=$(basename "$subdir")
  if [[ ! -d "${main_project_dir}/${dirname}" ]]; then
    mv "$subdir" "${main_project_dir}/${dirname}"
  fi
done
shopt -u nullglob

# ─── Patch history.jsonl ─────────────────────────────────────────────

history_file="${CLAUDE_DIR}/history.jsonl"

if [[ -f "$history_file" && ${#session_ids[@]} -gt 0 ]]; then
  # Build a jq filter that matches any of the migrated session IDs
  ids_json=$(printf '%s\n' "${session_ids[@]}" | jq -R . | jq -sc .)

  tmp_history="${history_file}.migrating"
  jq -c --arg old "$wt_path" --arg new "$main_path" --argjson ids "$ids_json" '
    if .project == $old and (.sessionId as $sid | $ids | index($sid) != null)
    then .project = $new
    else . end
  ' "$history_file" > "$tmp_history"

  mv "$tmp_history" "$history_file"
fi

# ─── Cleanup ─────────────────────────────────────────────────────────

# Remove worktree project dir if empty (ignore memory/ which belongs to worktree)
rmdir "$wt_project_dir" 2>/dev/null || true

echo "MIGRATED ${migrated} sessions from ${wt_key} → ${main_key}"
