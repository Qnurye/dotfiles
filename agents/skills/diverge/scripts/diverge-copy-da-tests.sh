#!/usr/bin/env bash
set -euo pipefail
DA_PATH="$1"
DEST_PATH="$2"
shift 2
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
done
