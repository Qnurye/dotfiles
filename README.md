# dotfiles

My macOS dotfiles for quick machine setup.

## Quick Start

```bash
git clone git@github.com:Qnurye/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## What's Included

| Directory | Description |
|-----------|-------------|
| `zsh/` | ZSH configuration (`.zshrc`, `.zprofile`, `.zshenv`) |
| `git/` | Git configuration (template, needs personal info) |
| `tmux/` | Oh My Tmux configuration |
| `zed/` | Zed editor settings |
| `homebrew/` | Brewfile for package management |

## Dependencies

The install script will automatically install:
- [Homebrew](https://brew.sh/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Oh My Tmux](https://github.com/gpakosz/.tmux)

## Post-Installation

Configure Git with your personal info:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global user.signingkey "YOUR_GPG_KEY"
```

## ZSH Plugins (via Homebrew)

```bash
brew install zsh-syntax-highlighting zsh-autosuggestions autojump
```

## Fonts

The config uses [Maple Mono NF CN](https://github.com/subframe7536/maple-font). Install via:

```bash
brew install --cask font-maple-mono-nf-cn
```
