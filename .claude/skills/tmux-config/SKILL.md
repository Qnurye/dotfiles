---
description: Tmux configuration with Oh My Tmux. Use when modifying, generating, or troubleshooting tmux settings (keybindings, status bar, mouse, clipboard, pane styling, plugins, TPM, Oh My Tmux theme variables).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Tmux Configuration

## Config Locations
- Dotfiles path: `terminals/tmux/.tmux.conf.local` (user overrides)
- Symlinked to: `~/.tmux.conf.local` (via nix home-manager `dotfiles.nix`)
- Oh My Tmux base (`~/.tmux.conf`) is installed separately -- DO NOT MODIFY and not tracked in this repo
- All customization goes in `.tmux.conf.local`

## Format & Syntax
- `set -g option value` for global options
- `set -s` server, `-w` window, `-p` pane, `-a` append
- `bind key command` (prefix table), `bind -n key command` (root table, no prefix)
- Key modifiers: `C-` (Ctrl), `M-` (Alt), `S-` (Shift)
- Oh My Tmux `tmux_conf_*` variables use shell-style assignment, not `set -g`

## Instructions
1. Read `terminals/tmux/.tmux.conf.local` first
2. NEVER edit `.tmux.conf` -- it is the Oh My Tmux base
3. Use `set -g` for globals, `bind`/`unbind` for keys
4. Oh My Tmux theme variables (`tmux_conf_*`) are shell-style assignments
5. TPM plugin init (`run '~/.tmux/plugins/tpm/tpm'`) must remain the last line
6. Group settings with comment headers matching existing style
7. After changes, remind user to reload with `<prefix> r`

## Reference
See [reference.md](reference.md) for configuration categories and Oh My Tmux variables.

## Official Documentation
- tmux man page: https://man7.org/linux/man-pages/man1/tmux.1.html
- Oh My Tmux: https://github.com/gpakosz/.tmux
- TPM: https://github.com/tmux-plugins/tpm
