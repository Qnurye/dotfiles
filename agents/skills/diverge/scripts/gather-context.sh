#!/usr/bin/env bash
set -euo pipefail

# ─── Prereq Validation ───────────────────────────────────────────────

CLAUDE_SETTINGS_GLOBAL="${HOME}/.claude/settings.json"
CLAUDE_SETTINGS_LOCAL=".claude/settings.json"
errors=()

# 0. jq (required for all JSON checks)
if ! command -v jq &>/dev/null; then
  errors+=("jq is not installed (brew install jq)")
fi

# 1. Git repository
if ! git rev-parse --git-dir &>/dev/null; then
  errors+=("Not inside a Git repository")
fi

# 2. Agent Teams experimental flag (check global then local, local wins)
if command -v jq &>/dev/null; then
  agent_teams=""
  for settings in "$CLAUDE_SETTINGS_GLOBAL" "$CLAUDE_SETTINGS_LOCAL"; do
    if [[ -f "$settings" ]]; then
      val=$(jq -r '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS // ""' "$settings")
      if [[ -n "$val" ]]; then
        agent_teams="$val"
      fi
    fi
  done
  if [[ "$agent_teams" != "1" ]]; then
    errors+=("Agent Teams not enabled (set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in Claude settings)")
  fi
fi

# 3. Worktrunk (wt) command
if ! command -v wt &>/dev/null; then
  errors+=("wt (worktrunk) not found — required for worktree isolation")
fi

# ─── Report ───────────────────────────────────────────────────────────

if [[ ${#errors[@]} -gt 0 ]]; then
  echo "PREREQ_FAILED"
  for err in "${errors[@]}"; do
    echo "  - ${err}"
  done
  exit 1
fi

echo "PREREQ_OK"

# ─── Context Grounding ────────────────────────────────────────────────

# Ensure we search from repo root regardless of cwd
cd "$(git rev-parse --show-toplevel)"

KNOWN_DOCS=(
  "./GEMINI.md"
  "./README.md"
  "./openspec/project.md"
  "./.specify/memory/constitution.md"
)

# Collect existing docs, deduplicate by content hash
# (Uses a flat list instead of associative array for bash 3 compatibility on macOS)
seen_hashes=""
found_docs=()

for doc in "${KNOWN_DOCS[@]}"; do
  [[ -f "$doc" ]] || continue
  hash=$(shasum -a 256 "$doc" | cut -d' ' -f1)
  case "$seen_hashes" in
    *"$hash"*) ;;  # already seen
    *)
      seen_hashes="${seen_hashes} ${hash}"
      found_docs+=("$doc")
      ;;
  esac
done

# Always create context file (even if empty) so downstream phases have a valid path
mkdir -p /tmp/diverge
CONTEXT_FILE=$(mktemp "/tmp/diverge/context-XXXXXXXX")

if [[ ${#found_docs[@]} -eq 0 ]]; then
  echo "# Grounded Context" > "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  echo "_No project documents found. Context will be populated by sub-agent research._" >> "$CONTEXT_FILE"
  echo "CONTEXT_EMPTY"
  echo "CONTEXT_FILE=${CONTEXT_FILE}"
  exit 0
fi

{
  echo "# Grounded Context"
  echo ""
  echo "_Auto-gathered from project documents._"
  echo ""
  for doc in "${found_docs[@]}"; do
    echo "---"
    echo ""
    echo "## Source: ${doc}"
    echo ""
    cat "$doc"
    echo ""
  done
} > "$CONTEXT_FILE"

echo "CONTEXT_FILE=${CONTEXT_FILE}"
