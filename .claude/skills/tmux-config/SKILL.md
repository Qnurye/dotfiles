---
description: Tmux configuration with Oh My Tmux. Use when modifying, generating, or troubleshooting tmux settings (keybindings, status bar, mouse, clipboard, pane styling, plugins, TPM, Oh My Tmux theme variables).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob, WebFetch
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
2. **Fetch the latest docs** before making changes — use `WebFetch` to retrieve the relevant reference:
   - tmux options: `https://raw.githubusercontent.com/tmux/tmux/master/tmux.1` (man page source)
   - Oh My Tmux variables & usage: `https://raw.githubusercontent.com/gpakosz/.tmux/master/README.md`
3. NEVER edit `.tmux.conf` -- it is the Oh My Tmux base
4. Use `set -g` for globals, `bind`/`unbind` for keys
5. Oh My Tmux theme variables (`tmux_conf_*`) are shell-style assignments
6. TPM plugin init (`run '~/.tmux/plugins/tpm/tpm'`) must remain the last line
7. Group settings with comment headers matching existing style
8. After changes, remind user to reload with `<prefix> r`

## Official Documentation
- tmux man page: https://man7.org/linux/man-pages/man1/tmux.1.html
- Oh My Tmux: https://github.com/gpakosz/.tmux
- TPM: https://github.com/tmux-plugins/tpm
