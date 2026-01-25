#!/bin/bash
# Prism Memory Context Injection
# Loads relevant memories at session start

VAULT="$HOME/Documents/Obsidian/VerseFlow"
MEMORIES_DIR="$VAULT/02 areas/memories"

# Exit silently if vault doesn't exist
[ ! -d "$VAULT" ] && exit 0

# Get current project context
project_name=$(basename "$PWD")

echo "## Prism Memory Context"
echo ""

# 1. User preferences (always load)
if [ -d "$MEMORIES_DIR/preference" ]; then
  has_prefs=false
  for f in "$MEMORIES_DIR/preference/"*.md; do
    [ -f "$f" ] || continue
    if [ "$has_prefs" = false ]; then
      echo "### User Preferences"
      has_prefs=true
    fi
    title=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //')
    [ -n "$title" ] && echo "- $title"
  done
  [ "$has_prefs" = true ] && echo ""
fi

# 2. Project-specific memories
if [ -d "$MEMORIES_DIR/project" ]; then
  has_project=false
  for f in "$MEMORIES_DIR/project/"*.md; do
    [ -f "$f" ] || continue
    if grep -q "$project_name" "$f" 2>/dev/null; then
      if [ "$has_project" = false ]; then
        echo "### Project: $project_name"
        has_project=true
      fi
      title=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //')
      [ -n "$title" ] && echo "- $title"
    fi
  done
  [ "$has_project" = true ] && echo ""
fi

# 3. Recent technical insights
if [ -d "$MEMORIES_DIR/technical" ]; then
  has_tech=false
  count=0
  for f in $(ls -t "$MEMORIES_DIR/technical/"*.md 2>/dev/null); do
    [ -f "$f" ] || continue
    [ $count -ge 3 ] && break
    if [ "$has_tech" = false ]; then
      echo "### Recent Technical Insights"
      has_tech=true
    fi
    title=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //')
    [ -n "$title" ] && echo "- $title"
    count=$((count + 1))
  done
  [ "$has_tech" = true ] && echo ""
fi

# 4. Recent decisions
if [ -d "$MEMORIES_DIR/decision" ]; then
  has_decision=false
  count=0
  for f in $(ls -t "$MEMORIES_DIR/decision/"*.md 2>/dev/null); do
    [ -f "$f" ] || continue
    [ $count -ge 3 ] && break
    if [ "$has_decision" = false ]; then
      echo "### Recent Decisions"
      has_decision=true
    fi
    title=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //')
    [ -n "$title" ] && echo "- $title"
    count=$((count + 1))
  done
  [ "$has_decision" = true ] && echo ""
fi

echo "---"
echo "Memory vault: $MEMORIES_DIR"
echo "Use \`/remember\` to store new memories"
