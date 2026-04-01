#!/usr/bin/env bash
set -euo pipefail
MSG="${1:-diverge checkpoint}"
# Skip if nothing to commit
git diff --cached --quiet && git diff --quiet && exit 0
git add -A
git commit -m "wip: $MSG" --no-verify
