# dotfiles

My macOS dotfiles for quick machine setup.

## Quick Start

```bash
git clone git@github.com:Qnurye/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## What's Included

| Directory | Links to |
|-----------|----------|
| `zsh/` | `~/.zshrc`, `~/.zprofile`, `~/.zshenv` |
| `git/` | `~/.gitconfig`, `~/.work.gitconfig` |
| `tmux/` | `~/.tmux.conf.local` (Oh My Tmux customization) |
| `zed/` | `~/.config/zed/settings.json` |
| `agents/` | `~/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.claude/settings.json` |
| `homebrew/` | Brewfile (not symlinked) |

## Commands

```bash
# Full installation (Homebrew, Oh My Zsh, Oh My Tmux, symlinks, packages)
./install.sh

# Install/update Homebrew packages only
brew bundle --file=homebrew/Brewfile

# Dump current Homebrew packages to Brewfile
brew bundle dump --file=homebrew/Brewfile --force
```

## Dependencies

The install script will automatically install:
- [Homebrew](https://brew.sh/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Oh My Tmux](https://github.com/gpakosz/.tmux)

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`

## Post-Installation

Configure Git with your personal info:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global user.signingkey "YOUR_GPG_KEY"
```

## Fonts

The config uses [Maple Mono NF CN](https://github.com/subframe7536/maple-font). Install via:

```bash
brew install --cask font-maple-mono-nf-cn
```
