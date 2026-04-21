#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────
#
# generate-launcher.sh \
#   --goal <slug>                Goal slug (directory name)
#   --approaches <a>,<b>,<c>    Comma-separated approach slugs
#   --branch-type <type>        feat|fix|refactor|chore|...
#   --context-file <path>       Grounding context file
#   --plans-dir <path>          Directory containing <approach>.md plan files
#   [--tdd]                     Enable TDD mode (Orchestrator + TDD Writer/Implementer pairs)
#
# Generates one launcher script per approach under /tmp/diverge/<goal>/.
# Each launcher embeds an init prompt built from the plan + context paths.
# Outputs the path to each generated launcher, one per line.
#
# In TDD mode, the launcher prompt uses an Orchestrator that spawns paired
# TDD Writer + Implementer agents per phase, plus a branch-isolated DA.
#
# Branch naming:
#   */work/*                 →  wj/<type>-<approach>
#   elsewhere                →  <type>/<approach>
#
# ─── Parse Args ───────────────────────────────────────────────────────

goal=""
approaches=""
branch_type=""
context_file=""
plans_dir=""
tdd_mode=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --goal)         goal="$2";         shift 2 ;;
    --approaches)   approaches="$2";   shift 2 ;;
    --branch-type)  branch_type="$2";  shift 2 ;;
    --context-file) context_file="$2"; shift 2 ;;
    --plans-dir)    plans_dir="$2";    shift 2 ;;
    --tdd)          tdd_mode=true;     shift ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Validate ─────────────────────────────────────────────────────────

missing=()
[[ -z "$goal" ]]         && missing+=("--goal")
[[ -z "$approaches" ]]   && missing+=("--approaches")
[[ -z "$branch_type" ]]  && missing+=("--branch-type")
[[ -z "$context_file" ]] && missing+=("--context-file")
[[ -z "$plans_dir" ]]    && missing+=("--plans-dir")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required args: ${missing[*]}" >&2
  exit 1
fi

if [[ ! -f "$context_file" ]]; then
  echo "Context file not found: ${context_file}" >&2
  exit 1
fi

if [[ ! -d "$plans_dir" ]]; then
  echo "Plans directory not found: ${plans_dir}" >&2
  exit 1
fi

# ─── Common Setup ────────────────────────────────────────────────────

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
base_branch=$(git branch --show-current)
output_dir="/tmp/diverge/${goal}"
mkdir -p "$output_dir"

# ─── Generate Launchers ─────────────────────────────────────────────

IFS=',' read -ra approach_list <<< "$approaches"

for approach in "${approach_list[@]}"; do
  plan_file="${plans_dir}/${approach}.md"

  if [[ ! -f "$plan_file" ]]; then
    echo "Plan file not found: ${plan_file}" >&2
    exit 1
  fi

  if [[ -n "$repo_root" && "$repo_root" == */work/* ]]; then
    branch_name="wj/${branch_type}-${approach}"
  else
    branch_name="${branch_type}/${approach}"
  fi

  # Unique team name per launcher so parallel diverge runs don't collide on
  # a shared "diverge-implement" team in CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS.
  team_suffix=$(uuidgen | tr 'A-Z' 'a-z' | tr -d '-' | cut -c1-6)
  team_name="diverge-${approach}-${team_suffix}"

  output_file="${output_dir}/${approach}.sh"

  cat > "$output_file" <<LAUNCHER_VARS
#!/usr/bin/env bash
set -euo pipefail

export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Exported so the launched agent (and any \$SHELL it spawns via Bash tool)
# inherits these in its environment. Otherwise the prompt's \${BASE_BRANCH}
# / \$DIVERGE_SCRIPTS references resolve to empty strings and the agent
# silently falls back to wrong defaults (e.g. consolidate against main).
export BASE_BRANCH="${base_branch}"
export BRANCH_NAME="${branch_name}"
export DIVERGE_SCRIPTS="\$HOME/.claude/skills/diverge/scripts"
DIVERGE_MONITOR_DIR="/tmp/diverge/${goal}/monitor"
export DIVERGE_MONITOR_DIR
DIVERGE_GOAL_SLUG="${goal}"
DIVERGE_DIRECTION="${approach}"

LAUNCHER_VARS

  # Build and inline the init prompt (no intermediate prompt file needed)
  {
    echo 'PROMPT=$(cat <<'\''PROMPT_EOF'\'''
    if [[ "$tdd_mode" == true ]]; then
      cat <<PROMPT_TEMPLATE
You are the Orchestrator for a TDD implementation team in an isolated worktree.

## Context
Read the grounding context at: ${context_file}

## Plan
Read the detailed plan at: ${plan_file}

## Script Utilities

All git and worktree operations must be performed via these scripts (never raw git/wt):

DIVERGE_SCRIPTS="\$HOME/.claude/skills/diverge/scripts"

## TDD Execution

Read the context and plan first, then execute the TDD workflow below.

### Step 1: Decompose plan into phases

Read the plan and identify all implementation phases. Use TaskCreate to create
one task per phase plus one task for "DA: Integration & Smoke Tests".

### Step 2: Create DA worktree

Create a branch-isolated worktree for the Devil's Advocate:

\`\`\`bash
DA_WT_PATH=\$("\$DIVERGE_SCRIPTS/diverge-wt-create.sh" "\${BRANCH_NAME}-tests" "\${BASE_BRANCH}")
\`\`\`

### Step 3: Spawn DA agent (Phase A — parallel with pairs)

Use TeamCreate to form team \`${team_name}\`. **Your name in this team
is \`orch\`** — pass this name to every agent you spawn so they can message you.

Spawn the DA agent with \`subagent_type: diverge-tdd-devils-advocate\`:
\`\`\`
name: da
prompt: |
  Plan file: ${plan_file}
  Context file: ${context_file}
  Worktree path: <DA_WT_PATH>
  Feature branch: \${BRANCH_NAME} (for reference only — orchestrator handles all git ops)
  Orchestrator: orch

  Start Phase A immediately: detect test conventions, write integration
  and smoke tests based on the plan. Send TESTS_WRITTEN when done.
  Then wait for MERGE_AND_VERIFY before starting Phase B.
\`\`\`

### Step 4: Spawn TDD Writer + Implementer pairs (parallel)

For each phase, spawn a PAIR of agents simultaneously.

**Naming rule:** The \`name:\` field you give each agent and the
\`Paired ...\` value in the other agent's prompt MUST be identical strings.
Decide the exact names first, then use them verbatim in both places.

**TDD Writer** (\`subagent_type: diverge-tdd-writer\`):
\`\`\`
name: tdd-<phase-slug>
prompt: |
  Phase: <phase name and full details from plan>
  Plan file: ${plan_file}
  Context file: ${context_file}
  Paired Implementer: impl-<phase-slug>
  Orchestrator: orch
\`\`\`

**Implementer** (\`subagent_type: diverge-tdd-implementer\`):
\`\`\`
name: impl-<phase-slug>
prompt: |
  Phase: <phase name and full details from plan>
  Plan file: ${plan_file}
  Context file: ${context_file}
  Paired TDD Writer: tdd-<phase-slug>
  Orchestrator: orch
\`\`\`

Spawn independent phases in parallel. Only serialize phases with true
data dependencies.

### Step 5: Handle Convention deadlocks

If a TDD Writer sends CONVENTION_DEADLOCK:
1. Read both positions
2. Make a decision based on the plan's requirements
3. Send DECISION to BOTH the TDD Writer and Implementer in that pair

### Step 6: Wait for all pairs (dual-gate synchronization)

Track three conditions:
- **ALL_IMPL_DONE**: all Implementers have sent PHASE_DONE
- **ALL_TESTS_DONE**: all TDD Writers have sent PHASE_TESTS_DONE
- **DA_TESTS_WRITTEN**: DA has sent TESTS_WRITTEN

All three must be met before proceeding. Neither side blocks the other
during the parallel phase.

### Step 7: Stage changes

When all pairs are done:
\`\`\`bash
"\$DIVERGE_SCRIPTS/diverge-wip-commit.sh" "diverge staging checkpoint"
\`\`\`

### Step 8: Trigger DA Phase B

When BOTH conditions are met:

#### Step 8a: Merge implementation into DA worktree

Before triggering Phase B, merge the feature branch into the DA worktree:

\`\`\`bash
"\$DIVERGE_SCRIPTS/diverge-merge-into-da.sh" "<DA_WT_PATH>" "\${BRANCH_NAME}"
\`\`\`

If the merge script fails (merge conflict), do NOT send MERGE_AND_VERIFY.
Instead report the conflict to the user and pause.

#### Step 8b: Signal DA

Only after the merge succeeds, send to the DA:
\`\`\`
MERGE_AND_VERIFY
\`\`\`

### Step 9: Handle DA review

**If DA reports APPROVED:**
1. Parse paths from DA's TESTS_WRITTEN message (integration: and smoke: fields)
2. Copy DA test files:
   \`\`\`bash
   "\$DIVERGE_SCRIPTS/diverge-copy-da-tests.sh" "<DA_WT_PATH>" "<WT_PATH>" <integration-path> <smoke-path>
   \`\`\`
3. Consolidate all commits into staged state:
   \`\`\`bash
   "\$DIVERGE_SCRIPTS/diverge-consolidate.sh" "\${BASE_BRANCH}"
   \`\`\`
4. Clean up DA worktree:
   \`\`\`bash
   wt -C "<DA_WT_PATH>" remove
   \`\`\`
5. Report success to the user. Final state: all changes staged, ready for user review
   and commit.

**If DA reports NEEDS_FIXES:**
1. Read the findings — filter for Critical and Important issues
2. Distribute FIX_REQUEST messages to the relevant pair agents
3. Wait for FIX_DONE from all pairs
4. Stage and commit fixes:
   \`\`\`bash
   "\$DIVERGE_SCRIPTS/diverge-wip-commit.sh" "diverge fix round N"
   \`\`\`
5. Re-merge fixes into DA worktree:
   \`\`\`bash
   "\$DIVERGE_SCRIPTS/diverge-merge-into-da.sh" "<DA_WT_PATH>" "\${BRANCH_NAME}"
   \`\`\`
6. Send FIXES_APPLIED to DA for re-verification
7. Maximum 2 fix rounds — after that, report remaining issues to user

### Step 10: Final cleanup

Always clean up the DA worktree when done:
\`\`\`bash
wt -C "<DA_WT_PATH>" remove 2>/dev/null || true
\`\`\`

## Team communication

All coordination uses SendMessage with structured signal prefixes:
CONVENTION_START, CONVENTION_AGREED, CONVENTION_DEADLOCK, DECISION,
PHASE_DONE, PHASE_TESTS_DONE, TESTS_WRITTEN, MERGE_AND_VERIFY,
REVIEW_COMPLETE, FIX_REQUEST, FIX_DONE, FIXES_APPLIED,
BLOCKED, NEEDS_CONTEXT

**CRITICAL: SendMessage \`to\` field must be the bare agent name only** (e.g.,
\`impl-phase1\`, \`da\`, \`orch\`). Never include team names, prefixes, paths,
quotes, or descriptive text — just the exact name string from the agent's
\`name:\` field.

Begin by reading the context and plan, then start execution.
PROMPT_TEMPLATE
    else
      cat <<PROMPT_TEMPLATE
You are an Implementor orchestrating plan execution in an isolated worktree.

## Context
Read the grounding context at: ${context_file}

## Plan
Read the detailed plan at: ${plan_file}

## Script Utilities

All git and worktree operations must be performed via these scripts (never raw git/wt):

DIVERGE_SCRIPTS="\$HOME/.claude/skills/diverge/scripts"

## Execution

Read the context and plan first, then decompose the plan into tasks and
a team for parallel execution.

### Task decomposition

Use TaskCreate to create one task per phase from the plan, plus one
task for "DA: Verification". Then use TeamCreate to form team
\`${team_name}\` and spawn teammates.

### Agent naming

**Your name in this team is \`orch\`.** Use short, consistent names:
- Implementers: \`impl-<phase-slug>\` (e.g., \`impl-api-routes\`)
- DA: \`da\`

Pass \`Orchestrator: orch\` to every spawned agent.

### Parallelism rules

Maximize concurrency by spawning independent teammates simultaneously.
Identify which phases have no dependencies on each other and run them
in parallel.

Only serialize phases that have true data dependencies (e.g., a phase
that modifies a file another phase reads, or a phase that depends on
the output of another).

Spawn implementers with \`subagent_type: diverge-implementer\`.

### Team communication

Teammates MUST use SendMessage to coordinate:
- Signal when a dependency is ready ("API endpoints are live, here are
  the routes: ...")
- Share interface contracts (types, schemas, function signatures) early
  so dependent work can start before the upstream phase completes
- Report blockers so the orchestrator can reassign or unblock

**CRITICAL: SendMessage \`to\` field must be the bare agent name only** (e.g.,
\`impl-phase1\`, \`da\`, \`orch\`). Never include team names, prefixes, paths,
quotes, or descriptive text — just the exact name string from the agent's
\`name:\` field.

### Verification

After all implementation phases complete, stage a checkpoint:
\`\`\`bash
"\$DIVERGE_SCRIPTS/diverge-wip-commit.sh" "diverge staging checkpoint"
\`\`\`

Then spawn a DA agent (\`subagent_type: diverge-tdd-devils-advocate\`,
name: \`da\`) to verify the implementation. The DA works in the SAME
worktree (no separate worktree needed). Its prompt should include:
- Plan file and context file paths
- Worktree path: the current working directory
- \`Orchestrator: orch\`
- Instruction: skip Phase A (no separate test writing). Go directly to
  Phase B — run existing tests, review code against the plan, and
  report REVIEW_COMPLETE.

Handle DA results (APPROVED / NEEDS_FIXES) the same as TDD mode.

### Consolidation

After DA approves (or after fix rounds), consolidate all WIP commits:
\`\`\`bash
"\$DIVERGE_SCRIPTS/diverge-consolidate.sh" "\${BASE_BRANCH}"
\`\`\`

Report success to the user. Final state: all changes staged, ready for
user review and commit.

Begin implementation immediately after reading the context and plan.
PROMPT_TEMPLATE
    fi
    echo 'PROMPT_EOF'
    echo ')'
    echo ''
    # Create worktree, resolve its path, run claude inside it, then
    # exec into user's shell so cmd+t / new tabs inherit the worktree cwd.
    if [[ "$tdd_mode" == true ]]; then
      cat <<'LAUNCHER_BODY'
wt switch --base "$BASE_BRANCH" --create --no-cd "$BRANCH_NAME"

# Resolve worktree path from wt list
WT_PATH=$(wt list --format=json | jq -r --arg b "$BRANCH_NAME" '.[] | select(.branch == $b) | .path')
if [[ -z "$WT_PATH" || ! -d "$WT_PATH" ]]; then
  echo "Error: could not resolve worktree path for branch $BRANCH_NAME" >&2
  exit 1
fi

# Clean up DA worktree on exit (TDD mode)
DA_BRANCH="${BRANCH_NAME}-tests"
cleanup_da() {
  local da_path
  da_path=$(wt list --format=json 2>/dev/null | jq -r --arg b "$DA_BRANCH" '.[] | select(.branch == $b) | .path' 2>/dev/null || true)
  if [[ -n "$da_path" && -d "$da_path" ]]; then
    wt -C "$da_path" remove 2>/dev/null || true
  fi
}
# Combined EXIT trap — cleanup_monitor is defined later in this script but
# the trap only fires at exit, by which point both functions exist.
trap '{ cleanup_monitor 2>/dev/null || true; cleanup_da 2>/dev/null || true; }' EXIT

cd "$WT_PATH"

# Rename this script's own tmux window — target $TMUX_PANE explicitly so the
# rename can't land on whichever window happens to be visible right now.
if [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]]; then
  tmux rename-window -t "$TMUX_PANE" "$BRANCH_NAME"
fi

# --- Diverge Monitor Sidecar ---
MONITOR_PID=""
MONITOR_PORT=""
start_monitor() {
  mkdir -p "$DIVERGE_MONITOR_DIR"
  touch "$DIVERGE_MONITOR_DIR/events.jsonl"

  local port_file
  port_file=$(mktemp)

  bun run "$HOME/dotfiles/agents/skills/diverge/monitor/server.ts" \
    --monitor-dir "$DIVERGE_MONITOR_DIR" \
    --goal-slug "$DIVERGE_GOAL_SLUG" \
    --direction "$DIVERGE_DIRECTION" \
    --worktree "$WT_PATH" \
    > "$port_file" 2>/dev/null &
  MONITOR_PID=$!

  local i
  for i in $(seq 1 30); do
    if grep -q '^PORT:' "$port_file" 2>/dev/null; then
      MONITOR_PORT=$(grep '^PORT:' "$port_file" | head -1 | cut -d: -f2)
      break
    fi
    sleep 0.1
  done
  rm -f "$port_file"

  if [[ -n "${MONITOR_PORT:-}" ]]; then
    echo "Monitor: http://localhost:$MONITOR_PORT"
    open "http://localhost:$MONITOR_PORT" 2>/dev/null || true
  else
    echo "Warning: monitor server did not start in time" >&2
  fi

  source "$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh" 2>/dev/null || true
  diverge_emit system run_start '{}' 2>/dev/null || true
}

cleanup_monitor() {
  [[ -n "${_MONITOR_CLEANED:-}" ]] && return 0
  _MONITOR_CLEANED=1
  source "$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh" 2>/dev/null || true
  diverge_emit system run_ended '{}' 2>/dev/null || true
  sleep 0.5
  if [[ -n "${MONITOR_PID:-}" ]]; then
    kill "$MONITOR_PID" 2>/dev/null || true
  fi
}

start_monitor
# --- End Monitor Sidecar ---

claude --permission-mode bypassPermissions "$PROMPT"

# Stay in the worktree after claude exits. cleanup_monitor is idempotent and
# runs on EXIT trap (registered at the start of this script for TDD mode, and
# just below for non-TDD mode), so monitor cleanup fires on both normal exit
# and SIGINT/SIGTERM mid-run. The plan's "frozen final state until the user
# closes the launcher shell" invariant holds because the trap fires when the
# launcher script itself exits — which is after the user's replacement shell.
"${SHELL:-/bin/bash}"
LAUNCHER_BODY
    else
      cat <<'LAUNCHER_BODY'
wt switch --base "$BASE_BRANCH" --create --no-cd "$BRANCH_NAME"

# Resolve worktree path from wt list
WT_PATH=$(wt list --format=json | jq -r --arg b "$BRANCH_NAME" '.[] | select(.branch == $b) | .path')
if [[ -z "$WT_PATH" || ! -d "$WT_PATH" ]]; then
  echo "Error: could not resolve worktree path for branch $BRANCH_NAME" >&2
  exit 1
fi

cd "$WT_PATH"

# Rename this script's own tmux window — target $TMUX_PANE explicitly so the
# rename can't land on whichever window happens to be visible right now.
if [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]]; then
  tmux rename-window -t "$TMUX_PANE" "$BRANCH_NAME"
fi

# --- Diverge Monitor Sidecar ---
MONITOR_PID=""
MONITOR_PORT=""
start_monitor() {
  mkdir -p "$DIVERGE_MONITOR_DIR"
  touch "$DIVERGE_MONITOR_DIR/events.jsonl"

  local port_file
  port_file=$(mktemp)

  bun run "$HOME/dotfiles/agents/skills/diverge/monitor/server.ts" \
    --monitor-dir "$DIVERGE_MONITOR_DIR" \
    --goal-slug "$DIVERGE_GOAL_SLUG" \
    --direction "$DIVERGE_DIRECTION" \
    --worktree "$WT_PATH" \
    > "$port_file" 2>/dev/null &
  MONITOR_PID=$!

  local i
  for i in $(seq 1 30); do
    if grep -q '^PORT:' "$port_file" 2>/dev/null; then
      MONITOR_PORT=$(grep '^PORT:' "$port_file" | head -1 | cut -d: -f2)
      break
    fi
    sleep 0.1
  done
  rm -f "$port_file"

  if [[ -n "${MONITOR_PORT:-}" ]]; then
    echo "Monitor: http://localhost:$MONITOR_PORT"
    open "http://localhost:$MONITOR_PORT" 2>/dev/null || true
  else
    echo "Warning: monitor server did not start in time" >&2
  fi

  source "$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh" 2>/dev/null || true
  diverge_emit system run_start '{}' 2>/dev/null || true
}

cleanup_monitor() {
  [[ -n "${_MONITOR_CLEANED:-}" ]] && return 0
  _MONITOR_CLEANED=1
  source "$HOME/dotfiles/agents/skills/diverge/monitor/emit.sh" 2>/dev/null || true
  diverge_emit system run_ended '{}' 2>/dev/null || true
  sleep 0.5
  if [[ -n "${MONITOR_PID:-}" ]]; then
    kill "$MONITOR_PID" 2>/dev/null || true
  fi
}

start_monitor
# Register cleanup_monitor for normal exit and abnormal signals (SIGINT,
# SIGTERM) so the background server is never orphaned mid-run.
trap cleanup_monitor EXIT
# --- End Monitor Sidecar ---

claude --permission-mode bypassPermissions "$PROMPT"

# Stay in the worktree after claude exits. cleanup_monitor is idempotent and
# runs on EXIT trap, so monitor cleanup fires on both normal exit and
# SIGINT/SIGTERM mid-run. The plan's "frozen final state until the user
# closes the launcher shell" invariant holds because the trap fires when the
# launcher script itself exits — which is after the user's replacement shell.
"${SHELL:-/bin/bash}"
LAUNCHER_BODY
    fi
  } >> "$output_file"

  chmod +x "$output_file"

  echo "$output_file"
done
