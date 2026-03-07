---
description: Worktrunk (wt) git worktree manager configuration. Use when modifying, generating, or troubleshooting worktrunk config (worktree paths, hooks, merge settings, LLM commits, shell integration, Claude Code plugin).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Worktrunk Configuration

## Config Locations
- User config dotfiles path: `worktrunk/config.toml`
- Symlinked to: `~/.config/worktrunk/config.toml`
- Project config: `.config/wt.toml` (per-repo, committed)

## Format & Syntax
- TOML format
- Keys are kebab-case (e.g., `worktree-path`)
- Nested sections use `[section]` or `[section.subsection]` tables
- Template variables use Jinja-like `{{ variable }}` syntax
- Filters: `{{ branch | sanitize }}`, `{{ branch | sanitize_db }}`, `{{ branch | hash_port }}`
- Environment variable overrides: `WORKTRUNK_` prefix, double underscores for nesting

## Instructions
1. Read the current config at `worktrunk/config.toml` first
2. Preserve existing structure and comments
3. User config holds personal preferences (worktree paths, LLM commit settings, list/merge defaults)
4. Project config holds team-shared settings (hooks, dev server URLs, CI platform)
5. Template variables: `{{ repo }}`, `{{ branch }}`, `{{ repo_path }}`, `{{ worktree_path }}`
6. Hook types: `post-create`, `post-start`, `post-switch`, `pre-merge`, `pre-commit`, `post-merge`, `pre-remove`, `post-remove`
7. The Claude Code plugin is configured separately in `agents/claude-settings.json` under `enabledPlugins`

## Reference
See [reference.md](reference.md) for full configuration options, hook types, and template variables.

## Official Documentation
- Main docs: https://worktrunk.dev/worktrunk/
- Hooks: https://worktrunk.dev/hook/
- Claude Code integration: https://worktrunk.dev/claude-code/
- CLI help: `wt --help`, `wt config --help`
