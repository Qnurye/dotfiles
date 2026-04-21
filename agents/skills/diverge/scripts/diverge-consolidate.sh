#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../monitor/emit.sh" 2>/dev/null || true
BASE_BRANCH="$1"
MERGE_BASE=$(git merge-base HEAD "$BASE_BRANCH")
if [[ -z "$MERGE_BASE" ]]; then
  echo "diverge-consolidate: could not find merge-base with $BASE_BRANCH" >&2
  exit 1
fi
git reset --soft "$MERGE_BASE"
diverge_emit script consolidate "{\"mergeBase\":\"$MERGE_BASE\"}" || true
echo "diverge-consolidate: all commits since $MERGE_BASE soft-reset to staged state"
