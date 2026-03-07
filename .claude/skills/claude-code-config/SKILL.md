---
description: Claude Code configuration. Use when modifying CLAUDE.md instructions, settings.json, hooks, MCP servers, permissions, custom slash commands, or skills.
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

- Dotfiles repo: `CLAUDE.md`, `.claude/settings.local.json`

## CLAUDE.md
- Markdown instructions loaded at session start
- Include: repo overview, commands, conventions, constraints
- Subdirectory CLAUDE.md files load when Claude works there
- Press `#` during session to quick-add instructions

## Settings JSON
- `permissions.allow` / `permissions.deny` -- tool permission patterns
- `mcpServers` -- MCP server definitions
- `hooks` -- lifecycle event handlers (PreToolUse, PostToolUse, SessionStart, Stop, etc.)
- `env` -- environment variables for the session
- Deny rules always override allow rules

## Instructions
1. Read current config file(s) first
2. CLAUDE.md: clear markdown, actionable instructions, no fluff
3. settings.json: valid JSON, correct schema fields
4. Respect scope hierarchy (global vs project vs local)
5. Be conservative with broad permission patterns like `Bash(*)`
6. For MCP secrets, use env var expansion, not hardcoded values

## Reference
See [reference.md](reference.md) for settings schema and hook events.

## Official Documentation
- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- MCP: https://docs.anthropic.com/en/docs/claude-code/mcp
- Skills: https://code.claude.com/docs/en/skills
