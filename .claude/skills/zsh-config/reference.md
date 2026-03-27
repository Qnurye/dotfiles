# Zsh Configuration Reference

## Status

Zsh config was removed from this dotfiles repo when the user migrated to Fish.
- Migration commit: `e03570a` ("restructure dirs and migrate zsh to fish")
- Previous config location: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) were dropped (see `nix/MIGRATION.md`)

## Repo Conventions for Shell Configs

If Zsh config is re-added, follow these patterns (mirroring Fish):
- Config directory: `shells/zsh/`
- Symlink registration: `nix/modules/home/dotfiles.nix`
- Package declarations: `nix/tags.nix` (for nix packages) or `nix/modules/darwin/homebrew.nix` (for non-nix)

## Key Configuration Categories (for reference)

- **PATH**: Accumulate across `.zprofile` and `.zshrc`
- **Aliases**: Define in `.zshrc`
- **Completions**: Via plugins or `compinit`
- **Shell options**: `setopt`/`unsetopt`
- **Functions**: Custom shell functions in `.zshrc`
- **Environment variables**: `export` in `.zshenv` (universal) or `.zshrc` (interactive-only)

## Previous Config (archived knowledge)

The old `.zshrc` included:
- Oh My Zsh with theme `gozilla`, plugins: `npm`, `history`, `git`, `tmux`
- Aliases: `vim` -> `nvim`, `tns` for tmux
- Homebrew plugins: zsh-syntax-highlighting, zsh-autosuggestions, autojump
- Tool hooks: fnm, direnv, wt (worktrunk)
- Environment: GPG_TTY, EDITOR/VISUAL (zed), Homebrew mirrors

All of this functionality now lives in Fish config (`shells/fish/`).
