---
description: Zed editor configuration. Use when modifying, generating, or troubleshooting Zed settings.json (themes, fonts, vim mode, LSP, AI/agent, keybindings, terminal, formatting, language overrides).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Zed Configuration

## Config Location
- Dotfiles path: `zed/settings.json`
- Symlinked to: `~/.config/zed/settings.json`
- Open in Zed: `Cmd+Alt+,`

## Format & Syntax
- JSONC (JSON with Comments) -- `//` line comments supported
- Trailing commas allowed
- Flat top-level JSON object (no root key wrapper)
- Per-project overrides: `.zed/settings.json` at project root

## Instructions
1. Read the current config at `zed/settings.json` first
2. Ensure valid JSONC syntax
3. Use valid option names per the official docs
4. Preserve existing structure and comment style
5. For language overrides: `"languages": { "LanguageName": { ... } }`
6. For LSP overrides: `"lsp": { "server_name": { "settings": { ... } } }`

## Reference
See [reference.md](reference.md) for key configuration categories and options.

## Official Documentation
- All settings: https://zed.dev/docs/reference/all-settings
- Configuring Zed: https://zed.dev/docs/configuring-zed
- Languages: https://zed.dev/docs/configuring-languages
- Key bindings: https://zed.dev/docs/key-bindings
- Agent settings: https://zed.dev/docs/ai/agent-settings
