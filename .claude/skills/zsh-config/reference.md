# Zsh Configuration Reference

## Key Configuration Categories
- **PATH**: Accumulated across `.zprofile` (Homebrew, JetBrains) and `.zshrc` (Go, pnpm, bun, libpq)
- **Aliases**: Shell shorthand; define in `.zshrc` after Oh My Zsh sourcing
- **Plugins (Oh My Zsh)**: Listed in `plugins=()` array before `source $ZSH/oh-my-zsh.sh`
- **Plugins (Homebrew)**: Sourced manually with `[[ -f ... ]] && source ...` after Oh My Zsh
- **Theme**: Set `ZSH_THEME` before sourcing Oh My Zsh
- **Completions**: Provided by Oh My Zsh plugins and Homebrew tools
- **Shell options**: `setopt`/`unsetopt` (e.g., `setopt AUTO_CD`)
- **Functions**: Custom shell functions in `.zshrc`
- **Environment variables**: `export` in `.zshenv` (universal) or `.zshrc` (interactive-only)

## Oh My Zsh

- Install path: `$HOME/.oh-my-zsh` (set as `$ZSH`)
- **Plugins**: `plugins=()` array. Built-in: `$ZSH/plugins/`. Custom: `$ZSH_CUSTOM/plugins/`
- **Themes**: `ZSH_THEME="name"`. Built-in: `$ZSH/themes/`. Custom: `$ZSH_CUSTOM/themes/`
- **Custom directory**: `$ZSH_CUSTOM` (default `$ZSH/custom/`)
- **Plugin convention**: `<name>.plugin.zsh` inside plugin directory
- **Theme convention**: `<name>.zsh-theme` inside themes directory
- **Updates**: Auto-update via `zstyle ':omz:update'` settings

## Current Config Layout

### .zshenv
- Cargo/Rust env sourcing

### .zprofile
- Homebrew shellenv init and mirror configuration
- JetBrains Toolbox PATH

### .zshrc sections
1. **PATH** -- Go bin, pnpm, bun, libpq, local bin
2. **Oh My Zsh** -- `ZSH_THEME="gozilla"`, plugins: `npm`, `history`, `git`, `tmux`
3. **Aliases** -- `vim` -> `nvim`, `tns` for tmux, `wtc` for worktree+claude
4. **Prompt** -- Spaceship prompt options
5. **Homebrew plugins** -- zsh-syntax-highlighting, zsh-autosuggestions, autojump
6. **Tool hooks** -- fnm, direnv, wt
7. **Environment** -- GPG_TTY, EDITOR/VISUAL (zed), Homebrew mirrors
8. **Functions** -- `brew()` wrapper, `_dotfiles_auto_sync`, `y()` (yazi cd wrapper)
