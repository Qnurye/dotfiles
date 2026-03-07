---
description: Ghostty terminal emulator configuration. Use when modifying, generating, or troubleshooting Ghostty config (fonts, themes, keybindings, window, cursor, clipboard, shell integration, macOS settings).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Ghostty Configuration

## Config Location
- Dotfiles path: `ghostty/config`
- Symlinked to: `~/.config/ghostty/config`

## Format & Syntax
- `key = value` syntax (whitespace around `=` optional)
- Comments: `#` on its own line
- Keys are case-sensitive, always lowercase
- Values can be quoted or unquoted; blank value resets to default
- `config-file = /path/to/other.conf` to split configs (prefix `?` for optional)
- Light/dark variants: `theme = light:Foo,dark:Bar`

## Instructions
1. Read the current config at `ghostty/config` first
2. Use valid option names per the official docs
3. Preserve existing structure and comments (current config uses Chinese section headers)
4. Group related settings under section headers
5. Add brief inline comments for non-obvious settings (especially keybind hex sequences)
6. The current config uses tmux integration heavily, with Cmd keybinds mapped to tmux prefix sequences (`\x1c` = Ctrl-\)
7. Some options cannot be reloaded at runtime -- note this when relevant

## Reference
See [reference.md](reference.md) for key configuration categories and options.

## Official Documentation
- Config overview: https://ghostty.org/docs/config
- Full option reference: https://ghostty.org/docs/config/reference
- Keybinding reference: https://ghostty.org/docs/config/keybind/reference
- CLI docs: `ghostty +show-config --default --docs`
