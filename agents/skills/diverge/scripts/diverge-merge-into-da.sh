#!/usr/bin/env bash
set -euo pipefail
DA_PATH="$1"
FEATURE_BRANCH="$2"
cd "$DA_PATH"
git fetch . "$FEATURE_BRANCH"
git merge FETCH_HEAD --no-verify -m "wip: merge feature for testing"
