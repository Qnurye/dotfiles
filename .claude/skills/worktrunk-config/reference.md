# Worktrunk Configuration Reference

## Worktree Path Template
- `worktree-path` — Jinja template for worktree location
- Variables: `{{ repo_path }}`, `{{ repo }}`, `{{ branch }}`
- Filters: `{{ branch | sanitize }}` (/ → -), `{{ branch | sanitize_db }}` (lowercase, underscores, hash suffix)
- Default: `{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}` (sibling directory)
- `~` expands to home; relative paths are relative to repo root

## Commit Settings
- `[commit]`
  - `stage` — what to stage before commit: `"all"`, `"tracked"`, `"none"`
- `[commit.generation]`
  - `command` — CLI command to generate commit messages (e.g., claude, llm, aichat, codex)
  - `template` — Jinja template for commit prompt (variables: `{{ git_diff }}`, `{{ git_diff_stat }}`, `{{ branch }}`, `{{ repo }}`, `{{ recent_commits }}`)
  - `squash-template` — template for squash commits (additional: `{{ commits }}`, `{{ target_branch }}`)

## List Settings
- `[list]`
  - `full` — show CI status and main…± diffstat columns (boolean)
  - `branches` — include branches without worktrees (boolean)
  - `remotes` — include remote-only branches (boolean)
  - `url` — URL column template (project config), e.g., `"http://localhost:{{ branch | hash_port }}"`

## Merge Settings
- `[merge]`
  - `squash` — squash commits into one (default: true)
  - `commit` — commit uncommitted changes first (default: true)
  - `rebase` — rebase onto target before merge (default: true)
  - `remove` — remove worktree after merge (default: true)
  - `verify` — run project hooks (default: true)

## Select (Picker) Settings
- `[select]`
  - `pager` — pager command with flags for diff preview (overrides git's core.pager)

## User Hooks
User hooks are defined in user config and run for all repositories. They run before project hooks and don't require approval.

```toml
# ~/.config/worktrunk/config.toml
[post-create]
setup = "echo 'Setting up worktree...'"

[pre-remove]
cleanup = "my-cleanup-script {{ worktree_path }}"
```

For per-project user hooks, use `[projects."github.com/user/repo"]` setting overrides.

## Project-Specific User Settings
- `[projects."github.com/user/repo"]` — per-project overrides
  - `approved-commands` — list of approved hook commands (auto-managed)
  - Scalar values replace global; hooks append (both global and per-project run)
  - Supports: `worktree-path`, `list.*`, `merge.*`, hook tables

## Hook Types

| Hook | Trigger | Blocking | Fail-fast |
|------|---------|----------|-----------|
| `post-create` | After worktree created | Yes | No |
| `post-start` | After worktree created (background) | No | No |
| `post-switch` | After every switch (background) | No | No |
| `pre-commit` | Before commit during merge | Yes | Yes |
| `pre-merge` | Before merge to target | Yes | Yes |
| `post-merge` | After successful merge | Yes | No |
| `pre-remove` | Before worktree deletion | Yes | Yes |
| `post-remove` | After worktree removed (background) | No | No |

Merge pipeline order: pre-commit → pre-merge → pre-remove → post-remove → post-merge

## Hook Template Variables
- `{{ repo }}` — repository directory name
- `{{ repo_path }}` — absolute path to repository root
- `{{ branch }}` — branch name
- `{{ worktree_name }}` — worktree directory name
- `{{ worktree_path }}` — absolute worktree path
- `{{ primary_worktree_path }}` — primary worktree path
- `{{ default_branch }}` — default branch name
- `{{ commit }}`, `{{ short_commit }}` — HEAD SHA (full / 7 chars)
- `{{ remote }}` — primary remote name
- `{{ remote_url }}` — remote URL
- `{{ upstream }}` — upstream tracking branch (if set)
- `{{ target }}` — target branch (merge hooks only)
- `{{ base }}` — base branch (creation hooks only)
- `{{ base_worktree_path }}` — base branch worktree (creation hooks only)

Undefined variables error — use conditionals: `{% if upstream %}...{% endif %}`

## Hook Filters & Functions
- `{{ branch | sanitize }}` — replace `/` and `\` with `-`
- `{{ branch | sanitize_db }}` — database-safe identifier with hash suffix
- `{{ branch | hash_port }}` — deterministic port 10000-19999
- `{{ worktree_path_of_branch("main") }}` — look up path of another branch's worktree

Pipe `|` has higher precedence than concatenation `~`: use `{{ (repo ~ '-' ~ branch) | hash_port }}`.

## Hook Format
```toml
# Single command
post-create = "npm install"

# Multiple named commands (run sequentially)
[pre-merge]
test = "cargo test"
lint = "cargo clippy"
```

Hooks also receive JSON context on stdin (all template variables + `hook_type` and `hook_name`).

## Hook Security
- Project hooks require approval on first run
- Approved commands saved to user config under `[projects."..."]`
- Re-approval required when command template changes
- Manage with `wt hook approvals add` / `wt hook approvals clear`
- Bypass with `--yes` (CI), skip hooks with `--no-verify`

## Environment Variables
- `WORKTRUNK_WORKTREE_PATH` — override worktree-path
- `WORKTRUNK_COMMIT__GENERATION__COMMAND` — override LLM command
- `WORKTRUNK_COMMIT__STAGE` — override stage setting
- `WORKTRUNK_CONFIG_PATH` — override user config location
- `WORKTRUNK_MAX_CONCURRENT_COMMANDS` — max parallel git commands (default: 32)
- `NO_COLOR` — disable colored output
- `CLICOLOR_FORCE` — force colored output

## Claude Code Integration
- Plugin: `worktrunk@worktrunk` in `enabledPlugins`
- Statusline: `wt list statusline --format=claude-code`
- Activity markers: set via `wt config state marker set`
- Install: `claude plugin marketplace add max-sixty/worktrunk && claude plugin install worktrunk@worktrunk`
