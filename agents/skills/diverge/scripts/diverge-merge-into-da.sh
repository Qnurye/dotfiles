#!/usr/bin/env bash
set -euo pipefail
DA_PATH="$1"
FEATURE_BRANCH="$2"
cd "$DA_PATH"
git fetch . "$FEATURE_BRANCH"
# --no-verify: intentional for ephemeral merge into DA worktree (gets cleaned up)
git merge FETCH_HEAD --no-verify -m "wip: merge feature for testing"
