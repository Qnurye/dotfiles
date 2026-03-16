#!/bin/bash
# gather-context.sh — validates prerequisites and outputs structured project context as markdown
# Used by the diverge skill to pre-gather mechanical context before LLM enrichment.
# Exit code 0 = success, non-zero = prerequisite failure (message on stderr).

set -euo pipefail

# --- Prerequisites ---
errors=()

if [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" != "1" ]; then
  errors+=("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set to 1 — team agents will not work. Set it in claude-settings.json env.")
fi

if ! command -v git &>/dev/null; then
  errors+=("git is not available on PATH.")
fi

if [ ${#errors[@]} -gt 0 ]; then
  echo "## Prerequisite Check Failed" >&2
  for err in "${errors[@]}"; do
    echo "- $err" >&2
  done
  exit 1
fi

# --- Context Gathering ---
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
PROJECT=$(basename "$REPO_ROOT")

# Tech stack detection
TECH_STACK=""
[ -f "$REPO_ROOT/package.json" ] && TECH_STACK="$TECH_STACK, Node.js"
[ -f "$REPO_ROOT/pnpm-lock.yaml" ] && TECH_STACK="$TECH_STACK (pnpm)"
[ -f "$REPO_ROOT/yarn.lock" ] && TECH_STACK="$TECH_STACK (yarn)"
[ -f "$REPO_ROOT/go.mod" ] && TECH_STACK="$TECH_STACK, Go"
[ -f "$REPO_ROOT/Cargo.toml" ] && TECH_STACK="$TECH_STACK, Rust"
[ -f "$REPO_ROOT/pyproject.toml" ] && TECH_STACK="$TECH_STACK, Python"
[ -f "$REPO_ROOT/requirements.txt" ] && TECH_STACK="$TECH_STACK, Python"
[ -f "$REPO_ROOT/deno.json" ] && TECH_STACK="$TECH_STACK, Deno"
[ -f "$REPO_ROOT/Gemfile" ] && TECH_STACK="$TECH_STACK, Ruby"
[ -f "$REPO_ROOT/build.gradle" ] || [ -f "$REPO_ROOT/build.gradle.kts" ] && TECH_STACK="$TECH_STACK, Java/Kotlin"
[ -f "$REPO_ROOT/Makefile" ] && TECH_STACK="$TECH_STACK, Make"
TECH_STACK="${TECH_STACK#, }" # trim leading comma+space
[ -z "$TECH_STACK" ] && TECH_STACK="unknown"

# Directory tree (depth 2, excluding noise)
TREE=$(find "$REPO_ROOT" -maxdepth 2 \
  -not -path '*/.git/*' -not -path '*/.git' \
  -not -path '*/node_modules/*' \
  -not -path '*/vendor/*' \
  -not -path '*/.worktrees/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/target/*' \
  | sed "s|^$REPO_ROOT/||" | sort | head -80)

# CLAUDE.md content
CLAUDE_MD=""
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
  CLAUDE_MD=$(head -200 "$REPO_ROOT/CLAUDE.md")
fi

cat <<CONTEXT
## Project Context (auto-gathered)
- **Project:** $PROJECT
- **Branch:** $BRANCH
- **Root:** $REPO_ROOT
- **Tech stack:** $TECH_STACK

### Directory Structure
\`\`\`
$TREE
\`\`\`
CONTEXT

if [ -n "$CLAUDE_MD" ]; then
cat <<CONSTRAINTS

### CLAUDE.md
$CLAUDE_MD
CONSTRAINTS
fi
