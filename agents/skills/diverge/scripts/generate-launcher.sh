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

  output_file="${output_dir}/${approach}.sh"

  cat > "$output_file" <<LAUNCHER_VARS
#!/usr/bin/env bash
set -euo pipefail

export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

BASE_BRANCH="${base_branch}"
BRANCH_NAME="${branch_name}"

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

## TDD Execution

Read the context and plan first, then execute the TDD workflow below.

### Step 1: Decompose plan into phases

Read the plan and identify all implementation phases. Use TaskCreate to create
one task per phase plus one task for "DA: Integration & Smoke Tests".

### Step 2: Create DA worktree

Create a branch-isolated worktree for the Devil's Advocate:

\`\`\`bash
wt switch --create "\${BRANCH_NAME}-tests" --base "\${BASE_BRANCH}" --no-cd

DA_WT_PATH=\$(wt list --format=json | jq -r --arg b "\${BRANCH_NAME}-tests" \\
  '.[] | select(.branch == \$b) | .path')
\`\`\`

### Step 3: Spawn DA agent (Phase A — parallel with pairs)

Use TeamCreate to form team "diverge-implement-<goal-slug>".

Spawn the DA agent with \`subagent_type: diverge-tdd-devils-advocate\`:
\`\`\`
name: diverge-da-<goal-slug>
prompt: |
  Plan file: ${plan_file}
  Context file: ${context_file}
  Worktree path: <DA_WT_PATH>
  Feature branch: \${BRANCH_NAME}
  Orchestrator: <your agent name>

  Start Phase A immediately: detect test conventions, write integration
  and smoke tests based on the plan. Send TESTS_WRITTEN when done.
  Then wait for MERGE_AND_VERIFY before starting Phase B.
\`\`\`

### Step 4: Spawn TDD Writer + Implementer pairs (parallel)

For each phase, spawn a PAIR of agents simultaneously:

**TDD Writer** (\`subagent_type: diverge-tdd-writer\`):
\`\`\`
name: diverge-tdd-<phase-slug>
prompt: |
  Phase: <phase name and full details from plan>
  Plan file: ${plan_file}
  Context file: ${context_file}
  Paired Implementer: diverge-impl-<phase-slug>
  Orchestrator: <your agent name>
\`\`\`

**Implementer** (\`subagent_type: diverge-tdd-implementer\`):
\`\`\`
name: diverge-impl-<phase-slug>
prompt: |
  Phase: <phase name and full details from plan>
  Plan file: ${plan_file}
  Context file: ${context_file}
  Paired TDD Writer: diverge-tdd-<phase-slug>
  Orchestrator: <your agent name>
\`\`\`

Spawn independent phases in parallel. Only serialize phases with true
data dependencies.

### Step 5: Handle Convention deadlocks

If a TDD Writer sends CONVENTION_DEADLOCK:
1. Read both positions
2. Make a decision based on the plan's requirements
3. Send DECISION to BOTH the TDD Writer and Implementer in that pair

### Step 6: Wait for all pairs (dual-gate synchronization)

Track two conditions:
- **ALL_PAIRS_DONE**: all Implementers have sent PHASE_DONE
- **TESTS_WRITTEN**: DA has sent TESTS_WRITTEN

Both must be met before proceeding. Neither side blocks the other during
the parallel phase.

### Step 7: Stage changes

When all pairs are done:
\`\`\`bash
git add -A && git commit -m "wip: diverge staging checkpoint" --no-verify
\`\`\`

### Step 8: Trigger DA Phase B

When BOTH conditions are met, send to the DA:
\`\`\`
MERGE_AND_VERIFY
\`\`\`

### Step 9: Handle DA review

**If DA reports APPROVED:**
1. Copy DA's test files from the tests worktree to this worktree
   (use the paths from DA's TESTS_WRITTEN message)
2. Clean up: \`wt -C "<DA_WT_PATH>" remove\`
3. Report success to the user

**If DA reports NEEDS_FIXES:**
1. Read the findings — filter for Critical and Important issues
2. Distribute FIX_REQUEST messages to the relevant pair agents
3. Wait for FIX_DONE from all pairs
4. Re-stage: \`git add -A && git commit -m "wip: diverge fix round N" --no-verify\`
5. Send FIXES_APPLIED to DA for re-verification
6. Maximum 2 fix rounds — after that, report remaining issues to user

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

Begin by reading the context and plan, then start execution.
PROMPT_TEMPLATE
    else
      cat <<PROMPT_TEMPLATE
You are an Implementor orchestrating plan execution in an isolated worktree.

## Context
Read the grounding context at: ${context_file}

## Plan
Read the detailed plan at: ${plan_file}

## Execution

Read the context and plan first, then decompose the plan into tasks and
a team for parallel execution.

### Task decomposition

Use TaskCreate to create one task per phase from the plan. Then use
TeamCreate to form the implementation team and spawn teammates.

### Parallelism rules

Maximize concurrency by spawning independent teammates simultaneously.
Identify which phases have no dependencies on each other and run them
in parallel.

Only serialize phases that have true data dependencies (e.g., a phase
that modifies a file another phase reads, or a phase that depends on
the output of another).

### Team communication

Teammates MUST use SendMessage to coordinate:
- Signal when a dependency is ready ("API endpoints are live, here are
  the routes: ...")
- Share interface contracts (types, schemas, function signatures) early
  so dependent work can start before the upstream phase completes
- Report blockers so the orchestrator can reassign or unblock

### Verification

The final task is ALWAYS a Devil's Advocate phase. It runs only after
all other tasks complete and verifies:
- All plan steps were executed correctly
- The result satisfies the original goal
- No regressions or unintended side effects

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
trap cleanup_da EXIT

cd "$WT_PATH"

# Rename tmux window to the plan slug (no-op outside tmux)
if [[ -n "${TMUX:-}" ]]; then
  tmux rename-window "$BRANCH_NAME"
fi

claude --permission-mode bypassPermissions "$PROMPT"

# Stay in the worktree after claude exits
exec "${SHELL:-/bin/bash}"
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

# Rename tmux window to the plan slug (no-op outside tmux)
if [[ -n "${TMUX:-}" ]]; then
  tmux rename-window "$BRANCH_NAME"
fi

claude --permission-mode bypassPermissions "$PROMPT"

# Stay in the worktree after claude exits
exec "${SHELL:-/bin/bash}"
LAUNCHER_BODY
    fi
  } >> "$output_file"

  chmod +x "$output_file"

  echo "$output_file"
done
