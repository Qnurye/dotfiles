---
description: Homebrew package management via nix-darwin. Use when modifying, generating, or troubleshooting Homebrew taps, brews, and casks declared in nix-darwin config (not a standalone Brewfile).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Homebrew via nix-darwin

## Architecture

This repo manages Homebrew **through nix-darwin**, not a standalone Brewfile.

- **Casks** are declared per-tag in `nix/tags.nix` (e.g., `casks = [ "ghostty" ];`)
- **Brews** can also be declared per-tag in `nix/tags.nix` (`brews = [ "uv" ];`) — used for fast-moving tools where stable nixpkgs lags (lazygit, jj, llama.cpp, ollama, uv, ruff, deno)
- **Taps and host-independent brews** (third-party formulae not in nixpkgs) are declared in `nix/modules/darwin/homebrew.nix`
- The resolver (`nix/lib/resolver.nix`) collects packages, casks, and brews from all active tags
- The shared host module (`nix/hosts/default.nix`) wires resolver output into `environment.systemPackages`, `homebrew.casks`, and `homebrew.brews`; per-host configs only pick tags
- Slow-moving CLI packages are nix packages in `tags.nix` `packages` lists (nixpkgs tracks the 26.05 stable release branch)

> **Legacy**: `homebrew/Brewfile` exists but is deprecated and will be removed after full nix-darwin cutover. Do not use it for new packages.

## Config Locations

| File | Purpose |
|------|---------|
| `nix/modules/darwin/homebrew.nix` | Taps, brews (third-party), onActivation settings |
| `nix/tags.nix` | Casks per tag (resolved automatically) |
| `nix/hosts/*/default.nix` | Tag selection per host; wires `resolved.casks` into `homebrew.casks` |
| `nix/lib/resolver.nix` | Tag dependency resolver (packages + casks) |
| `homebrew/Brewfile` | **Legacy** -- do not modify |

## Commands

```bash
# Rebuild (applies all homebrew changes)
sudo darwin-rebuild switch --flake ~/dotfiles/nix

# Shortcut fish function
nix-up                    # flake update + darwin-rebuild switch

# Search and add a package interactively
nix-add <query>           # search nixpkgs/casks -> pick tag -> rebuild
```

## How to Add a Homebrew Package

### Adding a cask (GUI app or font)
1. Find the appropriate tag in `nix/tags.nix` (e.g., `"apps/utils"`, `"fonts/extra"`)
2. Add the cask name to that tag's `casks` list
3. Rebuild with `darwin-rebuild switch`

### Adding a brew (CLI formula not in nixpkgs)
1. If it needs a third-party tap, add the tap to `homebrew.taps` in `nix/modules/darwin/homebrew.nix`
2. Add the formula to `homebrew.brews` in the same file
3. Rebuild with `darwin-rebuild switch`

### Adding a nix package (preferred for CLI tools)
1. Add to the appropriate tag's `packages` list in `nix/tags.nix`
2. Rebuild -- no Homebrew involvement needed

## Current onActivation Settings

```nix
onActivation = {
  cleanup = "none";    # Will switch to "zap" after migration completes
  autoUpdate = true;
  upgrade = true;
};
```

- `cleanup = "none"` prevents accidental removal during migration
- Target: `cleanup = "zap"` for fully declarative management

## Instructions
1. Always read the relevant nix files before making changes
2. Prefer nix packages over Homebrew brews whenever possible
3. Only use Homebrew for: casks (GUI apps/fonts) and brews not available in nixpkgs
4. Maintain alphabetical ordering within lists
5. Add taps before formulae that depend on them
6. Never remove entries without user confirmation

## Reference
See [reference.md](reference.md) for Brewfile directive syntax (useful for understanding `homebrew.nix` options).

## Official Documentation
- nix-darwin homebrew module: https://daiderd.com/nix-darwin/manual/index.html
- Brew Bundle: https://docs.brew.sh/Brew-Bundle-and-Brewfile
