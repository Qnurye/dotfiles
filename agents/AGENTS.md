---
aliases: []
created_at: 2026-01-25T15:52:32+08:00
tags: []
updated_at: 2026-01-25T15:52:32+08:00
---
# User Preferences

## Personal
- User Jaren Lo dislikes honorifics (敬语) and prefers to be addressed as '你' instead of '您'.

## Prism Memory Layer

VerseFlow serves as persistent memory for Prism across all projects.

**Memory Location**: `~/Documents/Obsidian/VerseFlow/02 areas/memories/`

**Memory Types**:
- `preference/` — User preferences and conventions
- `technical/` — Technical insights and learnings
- `decision/` — Decision rationale and context
- `project/` — Project-specific knowledge
- `pattern/` — Cross-project reusable patterns

**Usage**:
- Store: Use `/remember` or say "记住这个"
- Search: `grep -r "<keyword>" ~/Documents/Obsidian/VerseFlow/02\ areas/memories/`
- Dashboard: `02 areas/memories/index.md`

**Proactive Memory**: When discovering valuable insights, store immediately and notify user.

## Git & Version Control
- Prefer 'refactor' commit types for moving logic without changing behavior.
- Prefer `gh` CLI to access GitHub.
- Git pull strategy: rebase.
- GPG signing enabled for commits.

## Development Environment

### System
- macOS on Apple Silicon (ARM64)
- Shell: Zsh with Oh My Zsh

### Languages & Runtimes
- Python 3 (via Homebrew)
- Node.js (via FNM, with pnpm as preferred package manager)
- Go, Rust, Deno also available

### Editors
- Primary: Zed, Cursor
- Terminal: Neovim (`vim` is aliased to `nvim`)

### Package Managers
- Homebrew for system packages (auto-syncs Brewfile after install/uninstall)
- pnpm for Node.js projects
- Bun available as alternative

## Project Structure
- Personal projects: `~/Projects/`
- Work projects: `~/work/` (uses separate Git identity: Wenjie Luo)
- Dotfiles: `~/dotfiles/` (all configs managed via symlinks)

## Tool Preferences
- Use `jq` for JSON processing
- Docker and kubectl available for containerization
- 1Password CLI for secrets management
