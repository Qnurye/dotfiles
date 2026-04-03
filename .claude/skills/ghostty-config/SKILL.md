---
description: Ghostty terminal emulator configuration. Use when modifying, generating, or troubleshooting Ghostty config (fonts, themes, keybindings, window, cursor, clipboard, shell integration, macOS settings).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob, WebFetch
---

# Ghostty Configuration

## Config Location
- Dotfiles path: `terminals/ghostty/config`
- Symlinked to: `~/.config/ghostty/config` (via nix home-manager in `nix/modules/home/dotfiles.nix`)

## Format & Syntax
- `key = value` syntax (whitespace around `=` optional)
- Comments: `#` on its own line
- Keys are case-sensitive, always lowercase
- Values can be quoted or unquoted; blank value resets to default
- `config-file = /path/to/other.conf` to split configs (prefix `?` for optional)
- Light/dark variants: `theme = light:Foo,dark:Bar`
- Repeatable keys (e.g., `keybind`, `palette`, `font-feature`) can appear multiple times

## Current Config Characteristics
- Chinese section headers (e.g., `# ============ 字体 ============`)
- tmux integration: `command` launches tmux, Cmd keybinds send tmux prefix sequences (`\x1c` = Ctrl-\, the tmux prefix)
- macOS editing keybinds: Cmd+Left/Right for Home/End, Alt+Left/Right for word navigation
- Quick Terminal enabled with global Ctrl+` hotkey

## Instructions
1. Read the current config at `terminals/ghostty/config` first
2. **Fetch the latest docs** before making changes — use `WebFetch` to retrieve the relevant reference:
   - Config options: `https://raw.githubusercontent.com/ghostty-org/website/refs/heads/main/docs/config/reference.mdx`
   - Keybinding options: `https://raw.githubusercontent.com/ghostty-org/website/refs/heads/main/docs/config/keybind/reference.mdx`
3. Use valid option names per the fetched docs
4. Preserve existing structure and Chinese section headers
5. Group related settings under their section headers
6. Add brief inline comments for non-obvious settings (especially keybind hex sequences)
7. When adding tmux keybinds, use `text:\x1c` prefix (Ctrl-\) followed by the tmux key byte
8. Some options cannot be reloaded at runtime — note this when relevant

## Official Documentation
- Config overview: https://ghostty.org/docs/config
- Full option reference: https://raw.githubusercontent.com/ghostty-org/website/refs/heads/main/docs/config/reference.mdx
- Keybinding reference: https://raw.githubusercontent.com/ghostty-org/website/refs/heads/main/docs/config/keybind/reference.mdx
- CLI docs: `ghostty +show-config --default --docs`
