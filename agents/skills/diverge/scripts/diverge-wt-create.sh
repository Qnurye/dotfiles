#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../monitor/emit.sh" 2>/dev/null || true
BRANCH="$1"
BASE="$2"
wt switch --create "$BRANCH" --base "$BASE" --no-cd
WT_PATH=$(wt list --format=json | jq -r --arg b "$BRANCH" \
  '.[] | select(.branch == $b) | .path')
if [[ -z "$WT_PATH" || ! -d "$WT_PATH" ]]; then
  echo "diverge-wt-create: could not resolve path for branch $BRANCH" >&2
  exit 1
fi
diverge_emit script wt_create "{\"branch\":\"$BRANCH\",\"path\":\"$WT_PATH\"}" || true
echo "$WT_PATH"
