# Claude Code Configuration Reference

## Settings JSON Schema

```jsonc
{
  "permissions": {
    "allow": [
      "Read",                          // Tool by name
      "Bash(git status)",              // Specific command
      "Bash(source:*)",                // Pattern (source = hook/startup)
      "mcp__serverName__toolName"      // MCP tool
    ],
    "deny": [
      "Bash(rm -rf *)"
    ],
    "ask": [
      "WebFetch"                       // Always prompt user
    ],
    "defaultMode": "default"           // "default", "bypassPermissions", "plan", "auto"
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
  "env": { "NODE_ENV": "development" },
  "statusLine": {
    "type": "command",
    "command": "echo 'status text'"    // Shown in Claude Code status bar
  },
  "enabledPlugins": {
    "plugin-name@marketplace": true    // Toggle plugins on/off
  },
  "extraKnownMarketplaces": {
    "name": {
      "source": { "source": "github", "repo": "owner/repo" }
    }
  },
  "voiceEnabled": true,
  "skipDangerousModePermissionPrompt": true
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
| UserPromptSubmit | User submits prompt | Input validation, preprocessing |

## Permissions
- Patterns: exact (`Read`), parameterized (`Bash(git *)`), MCP (`mcp__server__tool`)
- `Bash(source:*)` -- matches commands from hooks/startup, not user prompts
- Deny always wins over allow
- Scope precedence: local > project > user > managed
- `defaultMode`: controls session permission behavior globally

## Custom Slash Commands
- Project: `.claude/commands/<name>.md` -> `/project:<name>`
- Personal: `~/.claude/commands/<name>.md` -> `/user:<name>`
- `$ARGUMENTS` placeholder for user input

## Skills
- Location: `.claude/skills/<name>/SKILL.md`
- YAML frontmatter: `description`, `user-invocable`, `allowed-tools`, `disable-model-invocation`
- `reference.md` and other files for detailed content
- `$ARGUMENTS`, `$ARGUMENTS[N]`, `${CLAUDE_SKILL_DIR}` substitutions

## Agents
- Location: `~/.claude/agents/<name>.md` (user) or `.claude/agents/<name>.md` (project)
- Content: markdown prompt defining the agent's behavior
- Launch: `claude --agent <name>` or select interactively
- List: `claude agents`

## Plugins
- Install: `claude plugin install <plugin>` or `claude plugin install <plugin@marketplace>`
- List: `claude plugin list`
- Enable/Disable: `claude plugin enable|disable <plugin>`
- Marketplaces: `claude plugin marketplace` subcommands
- Update: `claude plugin update <plugin>`
