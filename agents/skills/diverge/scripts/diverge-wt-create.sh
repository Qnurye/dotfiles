#!/usr/bin/env bash
set -euo pipefail
BRANCH="$1"
BASE="$2"
wt switch --create "$BRANCH" --base "$BASE" --no-cd
WT_PATH=$(wt list --format=json | jq -r --arg b "$BRANCH" \
  '.[] | select(.branch == $b) | .path')
if [[ -z "$WT_PATH" || ! -d "$WT_PATH" ]]; then
  echo "diverge-wt-create: could not resolve path for branch $BRANCH" >&2
  exit 1
fi
echo "$WT_PATH"
