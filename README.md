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

# Migrate agent skills, remove retired integrations, and enable the link watcher
./install.sh agents

# Repair links once, importing replacement files back into their sources
./install.sh check

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

## Managed symlinks

`tools/symlink-guard/links.json` defines links for Nix, the installer, and the
`es.qnury.dotfiles-link-guard` LaunchAgent. The watcher polls once per second.
When an app replaces a link with a regular file, it waits for two seconds of
stable metadata, backs up the replacement and repository version, imports the
new content, and restores the link. Multiple instruction aliases are processed
oldest first. Directory replacements merge additions and edits without deleting
source-only files; unsafe type changes or embedded symlinks are left for review.
Writers that remain active longer than the settling window can still race a
repair; recovery copies remain available in the backup directory.

Backups and logs live in `~/.local/state/dotfiles-link-guard/`. The watcher uses
a lock to prevent concurrent repairs. For manual repair while it is running:

```bash
launchctl bootout --wait gui/$(id -u)/es.qnury.dotfiles-link-guard
./install.sh check
python3 tools/symlink-guard/guard.py install
```

Each client's skills root is a real directory. Custom skills are linked under
`~/.agents/skills`, `~/.claude/skills`, and `~/.gemini/skills`. Codex discovers
the shared `.agents` skills and keeps system skills in `~/.codex/skills/.system`;
Claude keeps synced skills in `~/.claude/skills/synced`.

`./install.sh agents` archives unused Claude plugins after checking known project
settings (project-enabled plugins are retained), removes CodeGraph and
Context7 integration entries, migrates the old shared directories, and installs
the watcher. It retains migration backups alongside watcher backups. Codex's new
Git guard must be reviewed and trusted in `/hooks` after restarting Codex;
the installer does not write hook trust hashes. See the
[official hooks documentation](https://learn.chatgpt.com/docs/hooks#review-and-trust-hooks).

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
