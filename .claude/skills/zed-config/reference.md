# Zed Configuration Reference

## Appearance
- `theme` -- `mode` (system/light/dark), `light`, `dark` keys
- `icon_theme` -- file icon theme, same mode structure
- `ui_font_size` -- UI chrome font size
- `buffer_font_family`, `buffer_font_size`, `buffer_font_weight` -- editor text font
- `experimental.theme_overrides` -- per-syntax-token overrides (font_weight, font_style)
- `unnecessary_code_fade` -- opacity for unused code (0.0-1.0)

## Editor Behavior
- `vim_mode` -- Vim keybindings (boolean)
- `soft_wrap` -- `none`, `editor_width`, `preferred_line_length`, `bounded`
- `tab_size`, `hard_tabs` -- indentation
- `autosave` -- `off`, `on_focus_change`, `on_window_change`, `{ "after_delay": { "milliseconds": N } }`
- `format_on_save` -- `on` / `off`
- `formatter` -- `auto`, `language_server`, `prettier`, `external`
- `ensure_final_newline_on_save`, `remove_trailing_whitespace_on_save`
- `cursor_shape`, `cursor_blink`, `current_line_highlight`
- `show_edit_predictions` -- show inline AI predictions (boolean)

## Tabs & Panels
- `tab_bar` -- `show`, `show_nav_history_buttons`, `show_tab_bar_buttons`
- `tabs` -- `show_diagnostics`, `file_icons`, `git_status`
- `preview_tabs` -- `enable_preview_from_file_finder`
- `project_panel` -- `button`
- `git_panel` -- `tree_view`

## Code Intelligence
- `inlay_hints` -- `enabled`, `show_type_hints`, `show_parameter_hints`
- `enable_language_server`, `lsp`, `semantic_tokens`
- `lsp_document_colors` -- how LSP colors render (`background`, `foreground`, `off`)

## LSP Overrides
- `lsp` -- keyed by server name (e.g., `"eslint"`)
- Override: `settings` object with server-specific config
- Example: `"eslint": { "settings": { "useFlatConfig": true } }`

## Language Overrides
- `languages` -- keyed by language name (e.g., `"TypeScript"`, `"C++"`, `"CSS"`)
- Override: `tab_size`, `formatter`, `format_on_save`, `show_edit_predictions`, `code_actions_on_format`

## AI / Agent
- `agent` -- agent panel configuration
  - `default_model` -- `provider`, `model`, `enable_thinking`
  - `tool_permissions` -- `default` (`allow` / `ask` / `deny`)
  - `default_profile` -- agent profile (`write`, `read`, etc.)
  - `commit_message_model` -- `provider`, `model` for git commit messages
- `edit_predictions` -- inline completions: `provider` (`copilot`, `zed`)
- `show_edit_predictions` -- toggle visibility (boolean)

## Debugger
- `debugger` -- `button` (show debug button in toolbar)

## SSH Connections
- `ssh_connections` -- array of remote SSH targets
  - `host`, `username`, `args`, `projects` (each with `paths`)

## Terminal
- `terminal` -- `font_family`, `font_size`, `line_height`, `shell`, `env`, `working_directory`

## UI Chrome
- `toolbar` -- `code_actions`, `quick_actions`, `selections_menu`
- `status_bar` -- `active_language_button`
- `scrollbar`, `minimap`, `gutter`
- `indent_guides` -- `coloring` (`fixed`, `indent_aware`), `background_coloring`
- `title_bar` -- `show_menus`, `show_sign_in`

## Workspace & Session
- `restore_on_startup` -- `last_workspace`, `last_session`, `empty_tab`, `none`
- `auto_update` -- automatic updates (boolean)
- `use_system_window_tabs`, `confirm_quit`

## Advanced
- `base_keymap` -- `VSCode`, `JetBrains`, `Sublime Text`, `Atom`, `None`
- `direnv_integration`, `node`, `proxy`
- `which_key` -- which-key overlay for Vim mode (`enabled`)
