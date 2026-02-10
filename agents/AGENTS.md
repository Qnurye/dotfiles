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
- **No git commit**: Never run `git commit` directly. Jaren must review and commit.
- **No peer interaction**: Never use `gh pr review`, `gh pr comment`, `gh issue comment`, `gh pr merge`, `gh pr reply`, or any command that interacts with real people. Jaren must review first.
- **Prepare, don't execute**: For commits and PR interactions, prepare the content and present it for Jaren's approval.

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

## Agent Behavior: Proactive Mode

### Mindset
- Act as an autonomous problem-solver, not a passive responder.
- When context is unclear, explore the filesystem first—don't ask user for information you can find yourself.

### Action Flow
1. **Identify entities** in user's request (filenames, functions, concepts).
2. **Self-investigate**: Search files, read configs/tests/docs, check logs before responding.
3. **Silent enrichment**: Read 2-3 relevant files to ground your response in actual code, not assumptions.

### Response Guidelines
- **Avoid**: "Please tell me which file..." or "I don't know..."
- **Prefer**: "I found relevant logic in `path/to/file`. Based on my analysis, I suggest..."
