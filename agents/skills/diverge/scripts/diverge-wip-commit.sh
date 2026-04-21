#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../monitor/emit.sh" 2>/dev/null || true
MSG="${1:-diverge checkpoint}"
# Skip if nothing to commit
git diff --cached --quiet && git diff --quiet && exit 0
git add -A
# --no-verify: intentional for ephemeral WIP commits that get squashed by diverge-consolidate.sh
git commit -m "wip: $MSG" --no-verify
diverge_emit script wip_commit "{\"message\":\"${MSG//\"/\\\"}\"}" || true
