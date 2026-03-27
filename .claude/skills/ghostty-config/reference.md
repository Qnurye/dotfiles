# Ghostty Configuration Reference

## Font & Text
- `font-family` -- primary font (supports Nerd Fonts; use `font-family-bold`, `-italic`, `-bold-italic` for overrides)
- `font-size` -- size in points
- `font-style`, `font-style-bold`, `font-style-italic`, `font-style-bold-italic` -- style name overrides
- `font-synthetic-style` -- control synthetic bold/italic (`true`, `false`, `no-bold`, `no-italic`, `no-bold-italic`)
- `font-feature` -- OpenType feature tags (repeatable)
- `font-variation` -- variable font axes (repeatable; also `-bold`, `-italic`, `-bold-italic` variants)
- `font-codepoint-map` -- map codepoint ranges to specific fonts (1.2+)
- `font-thicken` -- thicken font strokes (macOS only, boolean)
- `font-thicken-strength` -- thickening intensity 0-255 (macOS only)
- `adjust-cell-width`, `adjust-cell-height` -- fine-tune cell dimensions
- `adjust-font-baseline` -- vertical baseline offset
- `adjust-underline-position`, `adjust-underline-thickness` -- underline tuning
- `adjust-strikethrough-position`, `adjust-strikethrough-thickness` -- strikethrough tuning
- `adjust-overline-position`, `adjust-overline-thickness` -- overline tuning
- `adjust-cursor-thickness`, `adjust-cursor-height` -- cursor dimension tuning
- `adjust-box-thickness` -- box-drawing character thickness
- `grapheme-width-method` -- `legacy` or `unicode`

## Theme & Colors
- `theme` -- named theme or `light:X,dark:Y` for auto-switching
- `background`, `foreground` -- hex colors (e.g., `#1a1b26`)
- `palette` -- override ANSI colors 0-255 (repeatable, format: `N=#rrggbb`)
- `palette-generate` -- auto-generate missing palette entries (1.3+)
- `palette-harmonious` -- harmonize generated palette colors (1.3+)
- `selection-foreground`, `selection-background` -- selection highlight colors
- `search-foreground`, `search-background` -- search match colors
- `search-selected-foreground`, `search-selected-background` -- active search match colors
- `minimum-contrast` -- enforce minimum contrast ratio
- `alpha-blending` -- `native`, `linear`, `linear-corrected`

## Background & Opacity
- `background-opacity` -- 0.0 to 1.0
- `background-opacity-cells` -- apply opacity to cell backgrounds too (1.2+, boolean)
- `background-blur` -- blur behind transparent background (boolean, integer, or macOS glass effect names)
- `background-image` -- path to background image (1.2+)
- `background-image-opacity` -- image opacity 0.0-1.0 (1.2+)
- `background-image-position` -- placement (1.2+)
- `background-image-fit` -- scaling mode (1.2+)
- `background-image-repeat` -- tiling (1.2+)

## Cursor
- `cursor-style` -- `block`, `bar`, `underline`, or `block_hollow`
- `cursor-style-blink` -- whether cursor blinks (boolean)
- `cursor-opacity` -- 0.0 to 1.0
- `cursor-color`, `cursor-text` -- cursor and text-under-cursor colors
- `cursor-click-to-move` -- click to reposition cursor (requires shell integration, 1.2+)

## Window
- `window-padding-x`, `window-padding-y` -- padding (single value or `left,right` / `top,bottom`)
- `window-padding-balance` -- auto-balance padding (boolean)
- `window-padding-color` -- `background`, `extend`, `extend-always`
- `window-vsync` -- VSync for rendering (macOS only)
- `window-inherit-working-directory` -- new windows inherit cwd (boolean)
- `tab-inherit-working-directory` -- new tabs inherit cwd (boolean)
- `split-inherit-working-directory` -- new splits inherit cwd (boolean)
- `window-inherit-font-size` -- new windows inherit font size (boolean)
- `window-save-state` -- `default`, `never`, `always` (macOS only)
- `window-decoration` -- `auto`, `none`, `client`, `server`
- `window-theme` -- `auto`, `system`, `light`, `dark`, `ghostty`
- `window-colorspace` -- `srgb`, `display-p3` (macOS only)
- `window-height`, `window-width` -- initial size in grid cells
- `window-position-x`, `window-position-y` -- initial position in pixels (macOS only)
- `window-step-resize` -- snap resize to cell boundaries (macOS only, boolean)
- `window-new-tab-position` -- `current`, `end`
- `window-title-font-family` -- font for title bar (GTK only)
- `window-subtitle` -- `false` or `working-directory`
- `maximize` -- start maximized (boolean)
- `fullscreen` -- `false`, `true`, `non-native`, `non-native-visible-menu`, `non-native-padded-notch`
- `title` -- fixed window title
- `class` -- window class (Linux/X11)

## Keybindings
- `keybind = modifiers+key=action` (repeatable)
- Modifiers: `ctrl`, `alt`, `shift`, `super` (Cmd on macOS)
- Prefixes: `global:` (system-wide), `all:` (all surfaces), `unconsumed:` (pass-through), `performable:` (conditional)
- `text:` action sends raw bytes (e.g., `keybind = super+t=text:\x1c\x63`)
- Key tables: `<table>/<binding>` syntax for modal keybinds (1.3+)
- `key-remap` -- remap modifier keys (e.g., `key-remap = alt=ctrl`)

## Clipboard & Selection
- `copy-on-select` -- auto-copy selected text (boolean)
- `clipboard-read` -- OSC 52 read access: `ask`, `allow`, `deny`
- `clipboard-write` -- OSC 52 write access: `ask`, `allow`, `deny`
- `clipboard-trim-trailing-spaces` -- trim spaces on copy (boolean)
- `clipboard-paste-protection` -- warn on suspicious paste (boolean)
- `clipboard-paste-bracketed-safe` -- safe bracketed paste (boolean)
- `selection-clear-on-typing` -- clear selection when typing (1.2+, boolean)
- `selection-clear-on-copy` -- clear selection after copy (1.2+, boolean)
- `selection-word-chars` -- characters considered part of a word for double-click (1.3+)

## Shell & Command
- `command` -- shell command to run (supports `direct:` and `shell:` prefixes, 1.2+)
- `initial-command` -- one-time command run before shell
- `shell-integration` -- `detect`, `bash`, `zsh`, `fish`, `elvish`, `none`
- `shell-integration-features` -- comma-separated: `cursor`, `sudo`, `title`, `no-cursor`, `no-sudo`, `no-title`
- `confirm-close-surface` -- confirm before closing (boolean)
- `wait-after-command` -- keep surface open after command exits (boolean)
- `abnormal-command-exit-runtime` -- minimum runtime before abnormal exit warning
- `working-directory` -- `home`, `inherit`, or absolute path
- `env` -- set environment variables (repeatable, format: `KEY=VALUE`, 1.2+)
- `input` -- send initial input (`raw:` or `path:` prefix, 1.2+)

## Scrollback & Mouse
- `scrollback-limit` -- max lines in scrollback buffer
- `scrollbar` -- `system` or `never`
- `scroll-to-bottom` -- `keystroke`, `no-output`
- `mouse-scroll-multiplier` -- scroll speed (supports `precision:N,discrete:N` for trackpad vs mouse)
- `mouse-hide-while-typing` -- hide cursor when typing (boolean)
- `mouse-reporting` -- enable mouse reporting to applications (boolean)
- `mouse-shift-capture` -- `true`, `false`, `always`, `never`
- `focus-follows-mouse` -- focus on hover (boolean)

## Splits
- `split-divider-color` -- color of split dividers (1.1+)
- `split-preserve-zoom` -- preserve zoom state on navigation (1.3+)
- `unfocused-split-opacity` -- dim unfocused splits (0.0-1.0)
- `unfocused-split-fill` -- fill color for unfocused splits

## Notifications
- `notify-on-command-finish` -- `never`, `unfocused`, `always` (1.3+)
- `notify-on-command-finish-action` -- `bell`, `notify` (1.3+)
- `notify-on-command-finish-after` -- duration threshold (1.3+)

## Resize Overlay
- `resize-overlay` -- `always`, `never`, `after-first`
- `resize-overlay-position` -- `center`, `top-left`, `top-center`, etc.
- `resize-overlay-duration` -- display duration

## Links
- `link-url` -- clickable URL detection (boolean)
- `link-previews` -- `true`, `false`, `osc8` (1.2+)

## macOS-Specific
- `macos-titlebar-style` -- `native`, `hidden`, `transparent`, `tabs`
- `macos-option-as-alt` -- `left`, `right`, `true`, `false`
- `macos-window-shadow` -- window shadow (boolean)

## Quick Terminal
- `quick-terminal-position` -- `top`, `bottom`, `left`, `right`, `center`
- `quick-terminal-animation-duration` -- seconds
- `quick-terminal-autohide` -- hide on focus loss (boolean)

## Advanced
- `image-storage-limit` -- max bytes for inline image protocols
- `title-report` -- allow applications to query window title
- `config-file` -- include another config file (prefix `?` for optional)
