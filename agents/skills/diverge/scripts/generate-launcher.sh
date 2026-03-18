#!/usr/bin/env bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────
#
# generate-launcher.sh \
#   --goal <slug>                Goal slug (directory name)
#   --approaches <a>,<b>,<c>    Comma-separated approach slugs
#   --branch-type <type>        feat|fix|refactor|chore|...
#   --prompts-dir <path>        Directory containing <approach>.md prompt files
#
# Generates one launcher script per approach under /tmp/diverge/<goal>/.
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
prompts_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --goal)        goal="$2";        shift 2 ;;
    --approaches)  approaches="$2";  shift 2 ;;
    --branch-type) branch_type="$2"; shift 2 ;;
    --prompts-dir) prompts_dir="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ─── Validate ─────────────────────────────────────────────────────────

missing=()
[[ -z "$goal" ]]        && missing+=("--goal")
[[ -z "$approaches" ]]  && missing+=("--approaches")
[[ -z "$branch_type" ]] && missing+=("--branch-type")
[[ -z "$prompts_dir" ]] && missing+=("--prompts-dir")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required args: ${missing[*]}" >&2
  exit 1
fi

if [[ ! -d "$prompts_dir" ]]; then
  echo "Prompts directory not found: ${prompts_dir}" >&2
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
  prompt_file="${prompts_dir}/${approach}.md"

  if [[ ! -f "$prompt_file" ]]; then
    echo "Prompt file not found: ${prompt_file}" >&2
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
done
