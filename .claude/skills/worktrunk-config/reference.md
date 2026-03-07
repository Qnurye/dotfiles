# Worktrunk Configuration Reference

## Worktree Path Template
- `worktree-path` -- Jinja template for worktree location
- Variables: `{{ repo_path }}`, `{{ repo }}`, `{{ branch }}`
- Filters: `{{ branch | sanitize }}` (/ → -), `{{ branch | sanitize_db }}` (lowercase, underscores, hash suffix)
- Default: `{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}` (sibling directory)
- `~` expands to home; relative paths are relative to repo root

## Commit Settings
- `[commit]`
  - `stage` -- what to stage before commit: `"all"`, `"tracked"`, `"none"`
- `[commit.generation]`
  - `command` -- CLI command to generate commit messages (e.g., claude, codex)
  - `template` -- Jinja template for commit prompt (variables: `{{ git_diff }}`, `{{ git_diff_stat }}`, `{{ branch }}`, `{{ repo }}`, `{{ recent_commits }}`)
  - `squash-template` -- template for squash commits (additional: `{{ commits }}`, `{{ target_branch }}`)

## List Settings
- `[list]`
  - `summary` -- enable LLM branch summaries (boolean)
  - `full` -- show CI, diffstat, summaries (boolean)
  - `branches` -- include branches without worktrees (boolean)
  - `remotes` -- include remote-only branches (boolean)
  - `url` -- URL column template, e.g., `"http://localhost:{{ branch | hash_port }}"`

## Merge Settings
- `[merge]`
  - `squash` -- squash commits into one (default: true)
  - `commit` -- commit uncommitted changes first (default: true)
  - `rebase` -- rebase onto target before merge (default: true)
  - `remove` -- remove worktree after merge (default: true)
  - `verify` -- run project hooks (default: true)

## Switch Picker
- `[switch.picker]`
  - `pager` -- pager command for diff preview (overrides git's core.pager)
  - `timeout-ms` -- timeout for git commands during picker loading (default: 200)

## Project-Specific User Settings
- `[projects."github.com/user/repo"]` -- per-project overrides
  - Scalar values replace global; hooks append
  - Supports all top-level keys

## Hook Types (Project Config)

| Hook | Trigger | Blocking | Fail-fast |
|------|---------|----------|-----------|
| `post-create` | After worktree created | Yes | No |
| `post-start` | After worktree creation (background) | No | No |
| `post-switch` | After every switch (background) | No | No |
| `pre-commit` | Before merge commit | Yes | Yes |
| `pre-merge` | Before merge to target | Yes | Yes |
| `post-merge` | After successful merge | Yes | No |
| `pre-remove` | Before worktree deletion | Yes | Yes |
| `post-remove` | After worktree removed | No | No |

Merge pipeline order: pre-commit → pre-merge → pre-remove → post-remove → post-merge

## Hook Template Variables
- `{{ repo }}`, `{{ branch }}`, `{{ worktree_path }}`
- `{{ commit }}`, `{{ short_commit }}` -- HEAD SHA
- `{{ target }}` -- target branch (merge hooks)
- `{{ base }}` -- base branch (creation hooks)
- `{{ upstream }}`, `{{ default_branch }}`, `{{ remote }}`, `{{ remote_url }}`
- `{{ branch | hash_port }}` -- deterministic port 10000-19999

## Hook Format
```toml
# Single command
post-create = "npm install"

# Multiple named commands
[pre-merge]
test = "cargo test"
lint = "cargo clippy"
```

## Environment Variables
- `WORKTRUNK_WORKTREE_PATH` -- override worktree-path
- `WORKTRUNK_COMMIT__GENERATION__COMMAND` -- override LLM command
- `WORKTRUNK_COMMIT__STAGE` -- override stage setting
- `WORKTRUNK_CONFIG_PATH` -- override user config location
- `WORKTRUNK_MAX_CONCURRENT_COMMANDS` -- max parallel git commands (default: 32)
- `NO_COLOR` -- disable colored output

## Claude Code Integration
- Plugin: `worktrunk@worktrunk` in `enabledPlugins`
- Statusline: `wt list statusline --format=claude-code`
- Activity markers: set via `wt config state marker set`
- Install: `claude plugin marketplace add max-sixty/worktrunk && claude plugin install worktrunk@worktrunk`
