# Tmux Configuration Reference

## Key Configuration Categories

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

### Pane Styling
- `pane-border-style`, `pane-active-border-style`
- `pane-border-lines` (single/double/heavy/simple/number)

### Plugins (TPM)
- `set -g @plugin 'author/plugin-name'`
- Plugin options: `set -g @option_name 'value'`
- TPM init: `run '~/.tmux/plugins/tpm/tpm'` (must be last line)

### Misc
- `history-limit`, `escape-time`, `repeat-time`
- `focus-events on`, `allow-passthrough on`

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

### Useful shortcuts
- `<prefix> e` -- edit `.tmux.conf.local` in $EDITOR
- `<prefix> r` -- reload configuration
