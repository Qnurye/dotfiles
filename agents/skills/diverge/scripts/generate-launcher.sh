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
#
# Generates one launcher script per approach under /tmp/diverge/<goal>/.
# Each launcher embeds an init prompt built from the plan + context paths.
# Outputs the path to each generated launcher, one per line.
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --goal)         goal="$2";         shift 2 ;;
    --approaches)   approaches="$2";   shift 2 ;;
    --branch-type)  branch_type="$2";  shift 2 ;;
    --context-file) context_file="$2"; shift 2 ;;
    --plans-dir)    plans_dir="$2";    shift 2 ;;
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
    echo 'PROMPT_EOF'
    echo ')'
    echo ''
    # Create worktree, resolve its path, run claude inside it, then
    # exec into user's shell so cmd+t / new tabs inherit the worktree cwd.
    cat <<'LAUNCHER_BODY'
wt switch --base "$BASE_BRANCH" --create "$BRANCH_NAME"

# Resolve worktree path from wt list
WT_PATH=$(wt list --format=json | jq -r --arg b "$BRANCH_NAME" '.[] | select(.branch == $b) | .path')
if [[ -z "$WT_PATH" || ! -d "$WT_PATH" ]]; then
  echo "Error: could not resolve worktree path for branch $BRANCH_NAME" >&2
  exit 1
fi

cd "$WT_PATH"
claude --permission-mode bypassPermissions "$PROMPT"

# Stay in the worktree after claude exits
exec "${SHELL:-/bin/bash}"
LAUNCHER_BODY
  } >> "$output_file"

  chmod +x "$output_file"

  echo "$output_file"
done
