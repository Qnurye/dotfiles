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
| `shells/fish/` | `~/.config/fish/config.fish`, `conf.d/`, `functions/`, `fish_plugins` |
| `editors/zed/` | `~/.config/zed/settings.json` |
| `terminals/ghostty/` | `~/.config/ghostty/config` |
| `terminals/tmux/` | `~/.tmux.conf.local` (Oh My Tmux customization) |
| `vcs/git/` | `~/.gitconfig`, `~/.gitignore_global`, `~/.work.gitconfig` |
| `vcs/lazygit/` | `~/Library/Application Support/lazygit/config.yml` |
| `tools/worktrunk/` | `~/.config/worktrunk/config.toml` |
| `agents/` | `~/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.claude/settings.json`, skills, agents |
| `homebrew/` | Brewfile (not symlinked) |
| `system/` | `/etc/sudoers.d/` overrides (copied, not symlinked) |

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

## Dependencies

The install script will automatically install:
- [Homebrew](https://brew.sh/)
- [Fish shell](https://fishshell.com/) (installed via Homebrew)
- [Fisher](https://github.com/jorgebucaron/fisher) (Fish plugin manager, installed via Homebrew)
- [Oh My Tmux](https://github.com/gpakosz/.tmux)

## Conventions

- Git configuration uses conditional includes (`includeIf`) for work-specific settings in `~/.work.gitconfig`

## Post-Installation

1. Set Fish as default shell:

```bash
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)
```

2. Configure Git with your personal info:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

3. Set up GPG signing:

```bash
git config --global user.signingkey "YOUR_GPG_KEY"
```

## Upgrading from Older Install

If upgrading from a previous version that used zsh, remove old symlinks:

```bash
rm -f ~/.zshrc ~/.zprofile ~/.zshenv
```

## Fonts

The config uses [Maple Mono NF CN](https://github.com/subframe7536/maple-font). Install via:

```bash
brew install --cask font-maple-mono-nf-cn
```
