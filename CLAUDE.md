# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles repository managed by **nix-darwin + home-manager**. Packages are declared in `nix/tags.nix`, dotfile symlinks in `nix/modules/home/dotfiles.nix`. Homebrew is used for casks (via nix-darwin) and third-party tap brews not available in nixpkgs (declared in `nix/modules/darwin/homebrew.nix`).

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

## Key Files

| Path | Purpose |
|------|---------|
| `nix/tags.nix` | Package registry (tag → packages + casks + deps) |
| `nix/hosts/<hostname>/` | Per-host tag selection and identity |
| `nix/modules/home/dotfiles.nix` | All dotfile symlinks (source of truth for what's managed) |
| `nix/modules/darwin/homebrew.nix` | Third-party taps and brews not in nixpkgs |
| `agents/agents/` | Claude Code agent definitions (diverge team) |
| `agents/skills/` | Skill definitions (symlinked to `~/.claude/skills/`) |
| `homebrew/Brewfile` | Legacy — not used by nix-darwin, pending removal |

## Nix Mirrors & Secrets

- **Binary caches**: NJU → SJTU → USTC mirror proxies, `cache.nixos.org` as fallback (TUNA is not used — it does not serve darwin paths)
- **GitHub API token**: stored in 1Password (`op://Personal/Nix GitHub Token/password`), deployed via `nix/setup-nix-conf.fish`
- Config lives at `/etc/nix/nix.custom.conf` (not tracked in git)

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`
- Prefer `refactor` commit type for moving logic without changing behavior
- Use `gh` CLI for GitHub operations
- **Adding packages**: edit `nix/tags.nix` or use `nix-add`, then rebuild
- **Temporary package use**: `nix shell nixpkgs#<pkg>` (no install needed)
