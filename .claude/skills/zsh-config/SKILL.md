---
description: Zsh shell configuration. Use when modifying, generating, or troubleshooting .zshrc, .zprofile, or .zshenv (aliases, plugins, PATH, shell options, functions, environment variables).
user-invocable: false
allowed-tools: Read, Grep, Glob
---

# Zsh Configuration

## Current Status

Zsh is NOT the active shell. The user's login shell is **Fish** (`/opt/homebrew/bin/fish`).
The previous `zsh/` directory was removed from the dotfiles repo (migrated to Fish).
Zsh is available at `/run/current-system/sw/bin/zsh` (nix-provided, v5.9) but has no managed config.

**Dangling symlinks exist** (left over from migration):
- `~/.zshrc` -> `~/dotfiles/zsh/.zshrc` (broken)
- `~/.zprofile` -> `~/dotfiles/zsh/.zprofile` (broken)
- `~/.zshenv` -> `~/dotfiles/zsh/.zshenv` (broken)

## If Re-adding Zsh Config

Follow the repo conventions:

1. **Create directory**: `shells/zsh/` (matching `shells/fish/` pattern)
2. **Register symlinks** in `nix/modules/home/dotfiles.nix`
3. **File roles** (Zsh source order: `.zshenv` -> `.zprofile` -> `.zshrc`):

| File | Loaded for | Purpose |
|------|-----------|---------|
| `.zshenv` | All shells | Minimal env vars needed everywhere. Keep lightweight. |
| `.zprofile` | Login shells | PATH, Homebrew init. On macOS each Terminal window is a login shell. |
| `.zshrc` | Interactive shells | Aliases, plugins, prompt, completions, shell options, functions. |

4. **Format**: Standard Zsh shell script syntax
   - `export VAR="value"` for environment variables
   - `[[ -f path ]] && source path` for conditional sourcing
   - Use conditional guards (`[[ -f ... ]]`, `command -v ...`) for optional tools
5. **Placement**: Universal env vars in `.zshenv`, login-time PATH in `.zprofile`, everything else in `.zshrc`

## Primary Shell

The user's primary shell is Fish. See the `fish-config` skill for active shell configuration.
Fish configs live at `shells/fish/` and are symlinked to `~/.config/fish/`.

## Reference

See [reference.md](reference.md) for Zsh configuration categories and conventions.

## Official Documentation
- Zsh startup files: https://zsh.sourceforge.io/Intro/intro_3.html
