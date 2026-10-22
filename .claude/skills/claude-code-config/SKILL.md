---
description: Claude Code configuration. Use when modifying CLAUDE.md instructions, settings.json, hooks, MCP servers, permissions, plugins, agents, custom slash commands, or skills.
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Claude Code Configuration

## Config Locations

| Scope | Settings JSON | Instructions |
|-------|--------------|--------------|
| User (global) | `~/.claude/settings.json` | `~/.claude/CLAUDE.md` |
| Project (shared) | `.claude/settings.json` | `CLAUDE.md` (repo root) |
| Project local | `.claude/settings.local.json` | `.claude/CLAUDE.md` |

### Dotfiles Repo Layout

Source files live in `~/dotfiles/agents/`. `tools/symlink-guard/links.json`
defines links for Nix, the installer, and the launchd watcher:

| Source | Symlink Target |
|--------|---------------|
| `agents/AGENTS.md` | `~/.claude/CLAUDE.md` (global instructions) |
| `agents/claude-settings.json` | `~/.claude/settings.json` (global settings) |
| `agents/RTK.md` | `~/.claude/RTK.md` (CLI reference; not included in shared instructions) |
| `agents/codex-hooks.json` | `~/.codex/hooks.json` |
| `agents/skills/<name>/` | Individual links under `~/.claude/skills/`, `~/.agents/skills/`, `~/.gemini/skills/` |
| `agents/agents/<name>.md` | `~/.claude/agents/<name>.md` |

Project-scoped files in dotfiles repo: `CLAUDE.md`, `.claude/settings.local.json`

Keep each client's skill root as a real directory. Claude owns
`~/.claude/skills/synced`; Codex owns `~/.codex/skills/.system` and discovers
shared custom skills under `~/.agents/skills`. Do not link entire skill roots.
The watcher imports stable replacement files into their repository source,
backs up both versions, and restores symlinks. Use `./install.sh check` to repair
links once, and `./install.sh agents` to migrate and register the watcher.

## CLAUDE.md
- Markdown instructions loaded at session start
- Include: repo overview, commands, conventions, constraints
- Subdirectory CLAUDE.md files load when Claude works there
- Press `#` during session to quick-add instructions
- `@file.md` syntax to include other files (e.g., `@RTK.md`)

## Settings JSON
- `permissions` -- tool permission rules (`allow`, `deny`, `ask`, `defaultMode`)
- `mcpServers` -- MCP server definitions (stdio, HTTP)
- `hooks` -- lifecycle event handlers (PreToolUse, PostToolUse, SessionStart, Stop, etc.)
- `env` -- environment variables for the session
- `statusLine` -- custom status line command
- `enabledPlugins` -- toggle installed plugins on/off
- `extraKnownMarketplaces` -- additional plugin marketplace sources
- `voiceEnabled` -- enable voice input
- `skipDangerousModePermissionPrompt` -- skip bypass-mode confirmation
- Deny rules always override allow rules

## Agents
- Defined as markdown files in `~/.claude/agents/` or `.claude/agents/`
- Each file: agent name derived from filename, content is the agent prompt
- Select at launch: `claude --agent <name>`
- List available: `claude agents`

## Plugins
- Managed via `claude plugin install|uninstall|enable|disable|list|update`
- Marketplaces: `claude plugin marketplace` subcommands
- Toggle in settings: `enabledPlugins` object (`"plugin@marketplace": true/false`)
- Custom marketplaces: `extraKnownMarketplaces` in settings

## Instructions
1. Read current config file(s) first
2. CLAUDE.md: clear markdown, actionable instructions, no fluff
3. settings.json: valid JSON, correct schema fields
4. Respect scope hierarchy (global vs project vs local)
5. Be conservative with broad permission patterns like `Bash(*)`
6. For MCP secrets, use env var expansion, not hardcoded values
7. In dotfiles repo, edit source files in `agents/`, not symlink targets

## Reference
See [reference.md](reference.md) for settings schema and hook events.

## Official Documentation
- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- MCP: https://docs.anthropic.com/en/docs/claude-code/mcp
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
