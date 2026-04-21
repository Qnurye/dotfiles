#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../monitor/emit.sh" 2>/dev/null || true
DA_PATH="$1"
FEATURE_BRANCH="$2"
cd "$DA_PATH"
git fetch . "$FEATURE_BRANCH"
# --no-verify: intentional for ephemeral merge into DA worktree (gets cleaned up)
git merge FETCH_HEAD --no-verify -m "wip: merge feature for testing"
diverge_emit script merge_into_da "{\"daPath\":\"$DA_PATH\",\"branch\":\"$FEATURE_BRANCH\"}" || true
