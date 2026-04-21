#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../monitor/emit.sh" 2>/dev/null || true
DA_PATH="$1"
DEST_PATH="$2"
shift 2
_copy_count=0
for rel_path in "$@"; do
  # Strip DA worktree prefix if an absolute path was passed
  rel_path="${rel_path#"$DA_PATH/"}"
  src="${DA_PATH}/${rel_path}"
  dest="${DEST_PATH}/${rel_path}"
  if [[ ! -e "$src" ]]; then
    echo "diverge-copy-da-tests: source not found: $src" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$dest")"
  cp -r "$src" "$dest"
  ((_copy_count++)) || true
done
diverge_emit script copy_da_tests "{\"fileCount\":$_copy_count}" || true
