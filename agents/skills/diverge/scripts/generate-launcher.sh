#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────
#
# generate-launcher.sh \
#   --goal <slug>           Goal slug (directory name)
#   --approach <slug>       Approach slug (script name)
#   --branch-type <type>    feat|fix|refactor|chore|...
#   --prompt-file <path>    File containing the full init prompt
#
# Outputs the path to the generated launcher script.
#
# Branch naming:
#   */work/*                 →  wj/<type>-<approach>
#   elsewhere                →  <type>/<approach>
#
# ─── Parse Args ───────────────────────────────────────────────────────

goal=""
approach=""
branch_type=""
prompt_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --goal)        goal="$2";        shift 2 ;;
    --approach)    approach="$2";    shift 2 ;;
    --branch-type) branch_type="$2"; shift 2 ;;
    --prompt-file) prompt_file="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Validate ─────────────────────────────────────────────────────────

missing=()
[[ -z "$goal" ]]        && missing+=("--goal")
[[ -z "$approach" ]]    && missing+=("--approach")
[[ -z "$branch_type" ]] && missing+=("--branch-type")
[[ -z "$prompt_file" ]] && missing+=("--prompt-file")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required args: ${missing[*]}" >&2
  exit 1
fi

if [[ ! -f "$prompt_file" ]]; then
  echo "Prompt file not found: ${prompt_file}" >&2
  exit 1
fi

# ─── Branch Name ──────────────────────────────────────────────────────

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [[ -n "$repo_root" && "$repo_root" == */work/* ]]; then
  branch_name="wj/${branch_type}-${approach}"
else
  branch_name="${branch_type}/${approach}"
fi

# Capture base branch at generation time
base_branch=$(git branch --show-current)

# ─── Generate Launcher ───────────────────────────────────────────────

output_dir="/tmp/diverge/${goal}"
mkdir -p "$output_dir"

output_file="${output_dir}/${approach}.sh"

# Build launcher script — use file copy for prompt to avoid shell expansion issues
cat > "$output_file" <<LAUNCHER_VARS
#!/usr/bin/env bash
set -euo pipefail

export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

BASE_BRANCH="${base_branch}"
BRANCH_NAME="${branch_name}"

LAUNCHER_VARS

# Append the prompt via quoted heredoc (no variable expansion)
{
  echo 'PROMPT=$(cat <<'\''PROMPT_EOF'\'''
  cat "$prompt_file"
  echo 'PROMPT_EOF'
  echo ')'
  echo ''
  echo 'wt switch --base "$BASE_BRANCH" -x claude --create "$BRANCH_NAME" -- --permission-mode bypassPermissions "$PROMPT"'
} >> "$output_file"

chmod +x "$output_file"

echo "$output_file"
