# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles repository using symlink-based configuration management. The `install.sh` script symlinks config files from this repo to their expected locations in `$HOME`.

## Commands

```bash
# Full installation (Homebrew, Oh My Zsh, Oh My Tmux, symlinks, packages)
./install.sh

# Install/update Homebrew packages only
brew bundle --file=homebrew/Brewfile

# Dump current Homebrew packages to Brewfile
brew bundle dump --file=homebrew/Brewfile --force
```

## Structure

| Directory | Links to |
|-----------|----------|
| `zsh/` | `~/.zshrc`, `~/.zprofile`, `~/.zshenv` |
| `git/` | `~/.gitconfig` |
| `tmux/` | `~/.tmux.conf.local` (Oh My Tmux customization) |
| `zed/` | `~/.config/zed/settings.json` |
| `homebrew/` | Brewfile (not symlinked) |

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`
- Prefer `refactor` commit type for moving logic without changing behavior
- Use `gh` CLI for GitHub operations
