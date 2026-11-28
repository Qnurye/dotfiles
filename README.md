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

Personal instructions live in `agents/AGENTS.md`. The manifest links the
Codex, Claude Code, Gemini/Antigravity, Zed and shared DeepSeek Harness
instruction files to that source. Grok Build discovers Claude's global rules.
The repository has its own `AGENTS.md` and `.agents/skills` aliases for tools
that use the shared project convention.

Custom and pstack skills are linked individually under `~/.agents/skills`,
`~/.claude/skills`, `~/.gemini/skills` and `~/.gemini/config/skills`.
The last root is shared by Antigravity App and CLI. Claude keeps its synced
skills and Codex keeps its system skills in client-owned directories.

Otty uses each client's native hook schema. Antigravity reads
`~/.gemini/config/hooks.json`. Grok loads its Otty adapter through Claude
compatibility. Codex hook trust remains local. Plugins and plugin-provided
agents use the client's native registry. Claude Markdown agent definitions
live in `agents/agents`; Codex uses TOML agent definitions.

`python3 agents/setup.py --plugins-only` applies the plugin policy to the local
clients. Claude keeps Worktrunk, Vercel, Cloudflare and Obsidian at their
configured scopes. User settings disable built-ins, subject to organization
policy. Codex keeps the two Computer Use plugins and disables other OpenAI
plugins. Grok and Antigravity retain installed exceptions. The running
DeepSeek service has its own profile.

`./install.sh agents` also cleans retired integrations, migrates old skill
directories, and installs the watcher. Migration backups are stored alongside
watcher backups.

## Agent configuration editor

Run `agent-config` to open the editor on localhost. From a new checkout, run
`./tools/agent-config/agent-config` directly. Use `--no-open` to print the local
URL, or `--port 8765` for a fixed port. Ctrl-C stops the server.

The editor indexes user-level configuration only. The dotfiles checkout’s project-scoped
agent files and plugins are excluded from the editor and its commits.
Universal shows the shared user instructions, local and Nix-provided skills,
hook adapters and agent definitions. Choose a client to edit its native
settings or create a scoped configuration. The creation dialog lists supported
destinations. Grok also reads compatible Claude files. Shared hooks target
Claude/Grok, Codex and Antigravity; Codex may require native hook approval.
Instructions, skill bodies and agent instructions use an offline WYSIWYG editor.
Hook handlers and skill metadata use forms. Plugin cards show the runtime state
and the retention and enablement controls available for each client.
Rebuild the bundled editor after dependency changes with `npm ci && npm run build`
in `tools/agent-config`. Changes to plugin policy are applied separately with **应用插件策略**.

Save with ⌘S / Ctrl-S or enable autosave. Review the complete file diffs before
committing. The editor runs `wt step commit --stage none` with a temporary
index for the selected files and retains unrelated staging in the real index.

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
