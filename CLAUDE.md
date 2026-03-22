# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles repository using symlink-based configuration management. The `install.sh` script symlinks config files from this repo to their expected locations in `$HOME`.

## Commands

```bash
# Full installation (Homebrew, Fish, Oh My Tmux, symlinks, packages)
./install.sh

# Install specific module only
./install.sh fish
./install.sh git tmux

# Install/update Homebrew packages only
brew bundle --file=homebrew/Brewfile

# Dump current Homebrew packages to Brewfile
brew bundle dump --file=homebrew/Brewfile --force
```

## Structure

| Directory | Links to |
|-----------|----------|
| `shells/fish/` | `~/.config/fish/config.fish`, `conf.d/`, `functions/` |
| `editors/zed/` | `~/.config/zed/settings.json` |
| `terminals/ghostty/` | `~/.config/ghostty/config` |
| `terminals/tmux/` | `~/.tmux.conf.local` (Oh My Tmux customization) |
| `vcs/git/` | `~/.gitconfig`, `~/.gitignore_global`, `~/.work.gitconfig` |
| `vcs/lazygit/` | `~/Library/Application Support/lazygit/config.yml` |
| `tools/worktrunk/` | `~/.config/worktrunk/config.toml` |
| `agents/skills/` | `~/.claude/skills/*` (central hub, other agents symlink here) |
| `agents/agents/` | `~/.claude/agents/*` (Claude Code agents) |
| `homebrew/` | Brewfile (not symlinked) |
| `system/` | `/etc/` overrides (copied, not symlinked) |

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`
- Prefer `refactor` commit type for moving logic without changing behavior
- Use `gh` CLI for GitHub operations
