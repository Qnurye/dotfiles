---
description: Zsh shell configuration. Use when modifying, generating, or troubleshooting .zshrc, .zprofile, or .zshenv (aliases, plugins, PATH, Oh My Zsh, shell options, functions, environment variables).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Zsh Configuration

## Config Locations
- Dotfiles path: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Symlinked to: `~/.zshrc`, `~/.zprofile`, `~/.zshenv`

## File Roles

Source order: `.zshenv` -> `.zprofile` -> `.zshrc` -> `.zlogin` -> `.zlogout`

| File | Loaded for | Purpose |
|------|-----------|---------|
| `.zshenv` | All shells | Minimal env vars needed everywhere. Keep lightweight. |
| `.zprofile` | Login shells | PATH, Homebrew init. On macOS each Terminal window is a login shell. |
| `.zshrc` | Interactive shells | Aliases, plugins, prompt, completions, shell options, functions. |

## Format & Syntax
- Standard Zsh shell script syntax
- `export VAR="value"` for environment variables
- `[[ -f path ]] && source path` for conditional sourcing
- Oh My Zsh must be sourced after setting `ZSH_THEME` and `plugins`

## Instructions
1. Read the relevant config file(s) first
2. Place settings in the correct file:
   - Universal env vars -> `.zshenv`
   - Login-time PATH and Homebrew -> `.zprofile`
   - Everything else -> `.zshrc`
3. Preserve existing aliases, exports, and plugin lists
4. Oh My Zsh variables (`ZSH_THEME`, `plugins`) must be set before `source $ZSH/oh-my-zsh.sh`
5. Homebrew-installed Zsh plugins must be sourced after Oh My Zsh
6. Use conditional guards (`[[ -f ... ]]`, `command -v ...`) for optional tools
7. Group related settings with comments matching existing section pattern

## Reference
See [reference.md](reference.md) for configuration categories and Oh My Zsh details.

## Official Documentation
- Zsh startup files: https://zsh.sourceforge.io/Intro/intro_3.html
- Oh My Zsh wiki: https://github.com/ohmyzsh/ohmyzsh/wiki
- Oh My Zsh plugins: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
- Oh My Zsh themes: https://github.com/ohmyzsh/ohmyzsh/wiki/themes
