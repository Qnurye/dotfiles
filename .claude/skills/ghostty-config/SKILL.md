---
description: Ghostty terminal emulator configuration. Use when modifying, generating, or troubleshooting Ghostty config (fonts, themes, keybindings, window, cursor, clipboard, shell integration, macOS settings).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
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
2. Use valid option names per the official docs
3. Preserve existing structure and Chinese section headers
4. Group related settings under their section headers
5. Add brief inline comments for non-obvious settings (especially keybind hex sequences)
6. When adding tmux keybinds, use `text:\x1c` prefix (Ctrl-\) followed by the tmux key byte
7. Some options cannot be reloaded at runtime -- note this when relevant
8. `mouse-scroll-multiplier` supports `precision:N,discrete:N` syntax for separate trackpad/mouse values

## Reference
See [reference.md](reference.md) for key configuration categories and options.

## Official Documentation
- Config overview: https://ghostty.org/docs/config
- Full option reference: https://ghostty.org/docs/config/reference
- Keybinding reference: https://ghostty.org/docs/config/keybind/reference
- CLI docs: `ghostty +show-config --default --docs`
