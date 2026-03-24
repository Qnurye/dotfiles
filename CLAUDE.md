# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles repository managed by **nix-darwin + home-manager**. Packages are declared in `nix/tags.nix`, dotfile symlinks in `nix/modules/home/dotfiles.nix`. Homebrew is only used for packages not in nixpkgs (declared in `nix/modules/darwin/homebrew.nix`).

## Commands

```bash
# Bootstrap (first time on a new machine)
./install.sh nix

# Update all packages
nix-up                    # fish function: flake update + darwin-rebuild switch

# Search and install a package interactively
nix-add <query>           # fish function: search nixpkgs/casks → pick tag → rebuild

# Rebuild without updating inputs
sudo darwin-rebuild switch --flake ~/dotfiles/nix

# Setup nix.custom.conf with secrets from 1Password
fish nix/setup-nix-conf.fish
```

## Structure

| Directory | Purpose |
|-----------|---------|
| `nix/flake.nix` | Flake entry point (nixpkgs via Tsinghua mirror) |
| `nix/tags.nix` | Package registry (tag → packages + casks + deps) |
| `nix/hosts/` | Per-host config (tag selection, identity) |
| `nix/modules/darwin/` | System-level config (homebrew.nix for non-nix packages) |
| `nix/modules/home/` | home-manager config (dotfiles.nix for symlinks) |
| `nix/setup-nix-conf.fish` | Generates `/etc/nix/nix.custom.conf` with 1Password secrets |
| `shells/fish/` | `~/.config/fish/` (config, conf.d, functions, completions) |
| `editors/zed/` | `~/.config/zed/settings.json` |
| `terminals/ghostty/` | `~/.config/ghostty/config` |
| `terminals/tmux/` | `~/.tmux.conf.local` (Oh My Tmux customization) |
| `vcs/git/` | `~/.gitconfig`, `~/.gitignore_global`, `~/.work.gitconfig` |
| `vcs/lazygit/` | `~/Library/Application Support/lazygit/config.yml` |
| `tools/worktrunk/` | `~/.config/worktrunk/config.toml` |
| `agents/skills/` | `~/.claude/skills/*` (central hub, other agents symlink here) |
| `agents/agents/` | `~/.claude/agents/*` (Claude Code agents) |
| `homebrew/` | Brewfile (legacy, will be removed after cutover) |
| `system/` | `/etc/` overrides (copied, not symlinked) |

## Nix Mirrors & Secrets

- **nixpkgs**: fetched from Tsinghua mirror (`mirrors.tuna.tsinghua.edu.cn`)
- **Binary cache**: USTC mirror as primary substituter
- **GitHub API token**: stored in 1Password (`op://Personal/Nix GitHub Token/password`), deployed via `nix/setup-nix-conf.fish`
- Config lives at `/etc/nix/nix.custom.conf` (not tracked in git)

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`
- Prefer `refactor` commit type for moving logic without changing behavior
- Use `gh` CLI for GitHub operations
- **Adding packages**: edit `nix/tags.nix` or use `nix-add`, then rebuild
- **Temporary package use**: `nix shell nixpkgs#<pkg>` (no install needed)
