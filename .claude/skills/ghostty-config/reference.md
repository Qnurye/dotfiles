# Ghostty Configuration Reference

## Font
- `font-family` -- font name (built-in Nerd Fonts available)
- `font-size` -- size in points
- `font-style`, `font-style-bold`, `font-style-italic`, `font-style-bold-italic` -- style overrides
- `adjust-cell-height`, `adjust-cell-width` -- fine-tune cell dimensions

## Theme & Colors
- `theme` -- named theme or `light:X,dark:Y` for auto-switching
- `background`, `foreground` -- hex colors (e.g., `#1a1b26`)
- `background-opacity` -- 0.0 to 1.0
- `background-blur` -- blur behind transparent background (boolean)
- `palette` -- override individual ANSI colors (0-255)

## Cursor
- `cursor-style` -- `block`, `bar`, or `underline`
- `cursor-style-blink` -- whether cursor blinks
- `cursor-opacity` -- 0.0 to 1.0
- `cursor-color`, `cursor-text` -- cursor and text-under-cursor colors

## Window
- `window-padding-x`, `window-padding-y` -- padding (single value or `left,right` / `top,bottom`)
- `window-padding-balance` -- auto-balance padding
- `window-vsync` -- VSync for rendering
- `window-inherit-working-directory` -- new windows inherit cwd
- `window-save-state` -- `default`, `never`, `always`
- `window-decoration` -- window decoration preference

## Keybindings
- `keybind = modifiers+key=action`
- Modifiers: `ctrl`, `alt`, `shift`, `super` (Cmd on macOS)
- `global:` prefix for system-wide hotkeys
- `text:` action sends raw bytes (e.g., `keybind = super+t=text:\x1c\x63`)
- `unconsumed:` prefix passes input through to the program

## Clipboard & Selection
- `copy-on-select` -- auto-copy selected text
- `clipboard-read`, `clipboard-write` -- OSC 52 clipboard access
- `selection-invert-fg-bg` -- invert colors for selection

## Shell Integration
- `shell-integration` -- `detect`, `bash`, `zsh`, `fish`, `elvish`, `none`
- `shell-integration-features` -- comma-separated: `cursor`, `sudo`, `title`, `no-cursor`
- `command` -- override default shell
- `confirm-close-surface` -- confirm before closing

## Scrollback
- `scrollback-limit` -- max lines in scrollback buffer
- `mouse-scroll-multiplier` -- scroll speed

## macOS-Specific
- `macos-titlebar-style` -- `native`, `hidden`, `transparent`, `tabs`
- `macos-option-as-alt` -- `left`, `right`, `true`, `false`
- `macos-window-shadow` -- window shadow

## Quick Terminal
- `quick-terminal-position` -- `top`, `bottom`, `left`, `right`, `center`
- `quick-terminal-animation-duration` -- seconds
- `quick-terminal-autohide` -- hide on focus loss

## Links & Advanced
- `link-url` -- clickable URL detection
- `image-storage-limit` -- max bytes for image protocols
