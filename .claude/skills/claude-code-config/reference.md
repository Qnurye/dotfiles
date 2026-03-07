# Claude Code Configuration Reference

## Settings JSON Schema

```jsonc
{
  "permissions": {
    "allow": [
      "Read",                          // Tool by name
      "Bash(git status)",              // Specific command
      "Bash(source:*)",                // Pattern
      "mcp__serverName__toolName"      // MCP tool
    ],
    "deny": [
      "Bash(rm -rf *)"
    ]
  },
  "mcpServers": {
    "serverName": {
      "command": "npx",
      "args": ["-y", "@org/mcp-server"],
      "env": { "API_KEY": "..." }
    }
  },
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "..." }] }],
    "PostToolUse": [{ "matcher": "Write", "hooks": [{ "type": "command", "command": "..." }] }]
  },
  "env": { "NODE_ENV": "development" }
}
```

## Hook Lifecycle Events

| Event | When | Use Case |
|-------|------|----------|
| PreToolUse | Before tool call | Allow, deny, or escalate |
| PostToolUse | After tool succeeds | Run formatters, linters |
| PostToolUseFailure | After tool fails | Error logging |
| SessionStart | Session begins | Setup tasks |
| Stop | Claude finishes responding | Validation |
| SubagentStop | Subagent finishes | Post-processing |
| ConfigChange | Config changes | Reload |
| UserPromptSubmit | User submits prompt | Input validation |

## Permissions
- Patterns: exact (`Read`), parameterized (`Bash(git *)`), MCP (`mcp__server__tool`)
- Deny always wins over allow
- Scope precedence: local > project > user > managed

## Custom Slash Commands
- Project: `.claude/commands/<name>.md` -> `/project:<name>`
- Personal: `~/.claude/commands/<name>.md` -> `/user:<name>`
- `$ARGUMENTS` placeholder for user input

## Skills
- Location: `.claude/skills/<name>/SKILL.md`
- YAML frontmatter: `description`, `user-invocable`, `allowed-tools`, `disable-model-invocation`
- `reference.md` and other files for detailed content
- `$ARGUMENTS`, `$ARGUMENTS[N]`, `${CLAUDE_SKILL_DIR}` substitutions
