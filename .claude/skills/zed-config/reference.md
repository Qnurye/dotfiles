# Zed Configuration Reference

## Appearance
- `theme` -- `mode` (system/light/dark), `light`, `dark` keys
- `icon_theme` -- file icon theme, same mode structure
- `ui_font_family`, `ui_font_size` -- UI chrome fonts
- `buffer_font_family`, `buffer_font_size`, `buffer_font_weight` -- editor text font
- `buffer_line_height` -- line spacing
- `experimental.theme_overrides` -- per-syntax-token overrides

## Editor Behavior
- `vim_mode` -- Vim keybindings (boolean)
- `soft_wrap` -- `none`, `editor_width`, `preferred_line_length`, `bounded`
- `tab_size`, `hard_tabs` -- indentation
- `autosave` -- `off`, `on_focus_change`, `on_window_change`, `{ "after_delay": { "milliseconds": N } }`
- `format_on_save` -- `on` / `off`
- `formatter` -- `auto`, `language_server`, `prettier`, `external`
- `ensure_final_newline_on_save`, `remove_trailing_whitespace_on_save`
- `cursor_shape`, `cursor_blink`, `current_line_highlight`

## Tabs & Panels
- `tab_bar` -- `show`, `show_nav_history_buttons`, `show_tab_bar_buttons`
- `tabs` -- `show_diagnostics`, `file_icons`, `git_status`
- `preview_tabs`, `project_panel`, `git_panel`

## Code Intelligence
- `completions` -- code completion behavior
- `edit_predictions` -- AI prediction provider (`copilot`, `zed`)
- `inlay_hints` -- `enabled`, `show_type_hints`, `show_parameter_hints`
- `enable_language_server`, `lsp`, `semantic_tokens`

## Language Overrides
- `languages` -- keyed by language name (e.g., `"TypeScript"`)
- Override: `tab_size`, `formatter`, `format_on_save`, `show_edit_predictions`, `code_actions_on_format`

## AI / Agent
- `agent` -- `tool_permissions`, `default_profile`, `commit_message_model`
- `edit_predictions` -- provider and model
- `disable_ai` -- kill switch for all AI features

## Terminal
- `terminal` -- `font_family`, `font_size`, `line_height`, `shell`, `env`, `working_directory`

## UI Chrome
- `toolbar` -- `code_actions`, `quick_actions`, `selections_menu`
- `status_bar`, `scrollbar`, `minimap`, `gutter`, `indent_guides`
- `title_bar` -- `show_menus`, `show_sign_in`

## Workspace & Session
- `restore_on_startup` -- `last_workspace`, `last_session`, `empty_tab`, `none`
- `auto_update`, `use_system_window_tabs`, `confirm_quit`

## Advanced
- `base_keymap` -- `VSCode`, `JetBrains`, `Sublime Text`, `Atom`, `None`
- `direnv_integration`, `node`, `proxy`
- `which_key` -- which-key overlay for Vim mode
