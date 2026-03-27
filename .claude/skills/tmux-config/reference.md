# Tmux Configuration Reference

## Current Setup Summary

- **Prefix**: `C-\` (Ctrl+Backslash) -- default `C-b` and `C-a` are unbound
- **Terminal**: Ghostty (`xterm-ghostty`) with true color and extended keys
- **Theme**: Dark (OneDark-inspired palette)
- **Mouse**: Enabled
- **Plugins**: Managed via TPM

## Key Configuration Categories

### PATH
- `set-environment -g PATH` -- ensures Homebrew paths are available inside tmux

### Prefix
- Prefix set to `C-\` via `set -g prefix 'C-\'`
- `prefix2` is unset; `C-a`, `C-b`, `C-Space` are all unbound

### Display
- `default-terminal`, `terminal-overrides`, `terminal-features` -- terminal capabilities
- `base-index`, `pane-base-index` -- numbering start
- `renumber-windows`, `automatic-rename`, `set-titles`
- `display-panes-time`, `display-time`, `status-interval`

### Status Bar
- `status-left`, `status-right`, `status-style`
- `window-status-format`, `window-status-current-format`
- `status-position` (top/bottom), `status-justify` (left/centre/right)

### Navigation & Keybindings
- `prefix` / `prefix2` -- prefix key(s)
- `mode-keys` (vi/emacs) -- copy mode key table

### Mouse
- `mouse on` -- select-pane, resize-pane, select-window, copy-mode

### Copy & Clipboard
- `set-clipboard on` -- OSC 52 passthrough
- `tmux_conf_copy_to_os_clipboard=true` (Oh My Tmux)

### Terminal & Passthrough
- `default-terminal "tmux-256color"`
- `terminal-overrides` with `Tc` (true color) for ghostty, xterm-256color, tmux-256color
- `terminal-features` with `extkeys`, `clipboard`, `ccolour`, `cstyle`, `focus`, `title` for ghostty
- `allow-passthrough on` -- allows applications to send escape sequences through tmux
- `extended-keys always` -- modern key encoding
- `set-clipboard on` -- OSC 52 clipboard integration

### Pane Styling
- `pane-border-lines simple`
- `pane-border-style "fg=#3a4150"`, `pane-active-border-style "fg=#7aa2f7"`

### Plugins (TPM)
- `set -g @plugin 'author/plugin-name'`
- Plugin options: `set -g @option_name 'value'`
- TPM init: `run '~/.tmux/plugins/tpm/tpm'` (must be last line)

### Misc
- `history-limit`, `escape-time`, `repeat-time`
- `focus-events on`

## Installed Plugins

| Plugin | Purpose |
|--------|---------|
| `tmux-plugins/tpm` | Plugin manager |
| `tmux-plugins/tmux-sensible` | Sensible defaults |
| `tmux-plugins/tmux-resurrect` | Save/restore sessions across restarts |
| `tmux-plugins/tmux-continuum` | Auto-save sessions (every 15 min), auto-restore |
| `tmux-plugins/tmux-yank` | System clipboard integration |
| `christoomey/vim-tmux-navigator` | Seamless vim/tmux pane navigation |
| `tmux-plugins/tmux-prefix-highlight` | Show prefix state in status bar |
| `sainnhe/tmux-fzf` | Fuzzy finder integration (`<prefix> F`) |
| `wfxr/tmux-fzf-url` | Open URLs from terminal output (`<prefix> u`) |

### Plugin Options

| Option | Value | Plugin |
|--------|-------|--------|
| `@continuum-restore` | `on` | tmux-continuum |
| `@continuum-save-interval` | `15` | tmux-continuum |
| `@resurrect-strategy-nvim` | `session` | tmux-resurrect |
| `@resurrect-strategy-vim` | `session` | tmux-resurrect |
| `@resurrect-capture-pane-contents` | `on` | tmux-resurrect |
| `@prefix_highlight_show_copy_mode` | `on` | tmux-prefix-highlight |
| `@tmux-fzf-launch-key` | `F` | tmux-fzf |
| `@fzf-url-bind` | `u` | tmux-fzf-url |
| `@fzf-url-open` | `open` | tmux-fzf-url |

## Custom Keybindings

| Binding | Action |
|---------|--------|
| `M-h` (no prefix) | Resize pane left 3 |
| `M-j` (no prefix) | Resize pane down 3 |
| `M-k` (no prefix) | Resize pane up 3 |
| `M-l` (no prefix) | Resize pane right 3 |
| `<prefix> X` | Kill pane (no confirmation) |
| `<prefix> Z` | Open current pane path in Zed |

## Oh My Tmux Variables

Shell-style variables set in `.tmux.conf.local` (parsed by the base config):

| Variable | Purpose |
|----------|---------|
| `tmux_conf_new_session_retain_current_path` | Keep cwd for new sessions |
| `tmux_conf_new_window_retain_current_path` | Keep cwd for new windows |
| `tmux_conf_copy_to_os_clipboard` | Copy to system clipboard |
| `tmux_conf_preserve_stock_bindings` | Keep default tmux bindings |
| `tmux_conf_theme_colour_1` ... `_17` | Theme palette (17 color slots) |
| `tmux_conf_theme_left_separator_main/sub` | Status bar separators |
| `tmux_conf_theme_right_separator_main/sub` | Status bar separators |
| `tmux_conf_theme_status_left/right` | Status bar content |
| `tmux_conf_theme_terminal_title` | Terminal title format |

### Current Theme Palette

| Slot | Hex | Role |
|------|-----|------|
| colour_1 | `#1f2329` | Dark background |
| colour_2 | `#2a2f38` | Lighter background |
| colour_3 | `#9aa4b2` | Muted foreground |
| colour_4 | `#7aa2f7` | Accent blue |
| colour_5 | `#e5c07b` | Accent yellow |
| colour_6 | `#1f2329` | Dark background (alt) |
| colour_7 | `#d0d7de` | Light foreground |
| colour_8-16 | Various | Supporting tones |
| colour_17 | `#d0d7de` | Light foreground (alt) |

### Useful Shortcuts
- `<prefix> e` -- edit `.tmux.conf.local` in $EDITOR
- `<prefix> r` -- reload configuration
