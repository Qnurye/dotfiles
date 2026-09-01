---
description: Fish shell configuration. Use when modifying, generating, or troubleshooting Fish config (config.fish, conf.d/, functions/, fish_plugins, Fisher plugins, PATH, environment variables, abbreviations, aliases).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Fish Shell Configuration

## File Layout

| File / Directory | Purpose |
|---|---|
| `~/.config/fish/config.fish` | Main config, sourced on every shell start |
| `~/.config/fish/conf.d/` | Auto-sourced snippets (alphabetical order, before config.fish) |
| `~/.config/fish/functions/` | Lazy-loaded functions (one function per file, filename = function name) |
| `~/.config/fish/fish_plugins` | Fisher plugin manifest (one plugin per line) |
| `~/.config/fish/completions/` | Custom tab completions |

All files are symlinked from `shells/fish/` in the dotfiles repo via nix home-manager (`nix/modules/home/dotfiles.nix`).

## Variable Scopes

| Scope | Flag | Persists? | Visible to child? | Use case |
|---|---|---|---|---|
| Universal | `-U` | Yes (across sessions) | Yes | Prompt colors, rarely-changed settings |
| Global | `-g` | No (current session) | Yes | Session-wide state |
| Local | `-l` | No (current block) | No | Temporary/loop variables |
| Export | `-x` | — | Yes (to child processes) | Environment variables |

Common combinations:
- `set -gx VAR value` — global + exported (env var for current session)
- `set -U VAR value` — universal (persists, use sparingly, mainly for prompt themes)
- `set -l VAR value` — block-scoped temporary

## PATH Management

```fish
# Preferred: fish_add_path (idempotent, prepends to PATH)
fish_add_path $HOME/go/bin
fish_add_path /opt/homebrew/opt/libpq/bin

# Conditional path addition
test -d "$HOME/some/dir"; and fish_add_path "$HOME/some/dir"

# Environment variable + path (e.g., pnpm, bun)
set -gx PNPM_HOME "$HOME/Library/pnpm"
fish_add_path $PNPM_HOME
```

Do NOT use `set PATH $PATH /new/path` — use `fish_add_path` instead.

## Abbreviations vs Aliases

```fish
# Abbreviations (preferred): expand inline when typed, visible in history as full command
abbr -a gst 'git status'
abbr -a gp 'git push'

# Aliases: wrapper functions, use for commands needing logic
alias vim nvim
alias tns 'tmux new-session -d -s'
```

Prefer `abbr` over `alias` for simple command shortcuts — abbreviations expand so the actual command appears in history and can be edited before running.

## Conditional Tool Initialization

```fish
# Pattern: check command exists before init
command -q fnm; and fnm env --use-on-cd --log-level quiet --shell fish | source
command -q direnv; and direnv hook fish | source

# Pattern: source file if it exists
test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"
test -f "$HOME/.local/bin/env.fish"; and source "$HOME/.local/bin/env.fish"
```

## conf.d/ Auto-Sourcing

Files in `conf.d/` are sourced **alphabetically before config.fish**. Use for:
- Self-contained feature modules (e.g., `dotfiles_sync.fish`, `tide_one_dark.fish`)
- Plugin configuration that should load early
- Functions that need to run on every shell init (define in the snippet itself)

## Fisher Plugin Management

Fisher is the plugin manager. Plugins are listed in `~/.config/fish/fish_plugins`.

```fish
# Install a plugin
fisher install jorgebucaran/autopair.fish

# Update all plugins
fisher update

# Remove a plugin
fisher remove jethrokuan/z

# Install from fish_plugins manifest (after fresh setup)
fisher update
```

### fish_plugins format

One plugin per line, `owner/repo` or `owner/repo@branch`:

```
IlanCosman/tide@v6
patrickf1/fzf.fish
jethrokuan/z
jorgebucaran/autopair.fish
meaningful-ooo/sponge
```

## This Repo's Patterns

### Homebrew + Nix PATH ordering

Homebrew init must come first, then Nix paths are re-prepended so nix-managed binaries take priority:

```fish
# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# Nix (re-add after brew shellenv resets PATH)
fish_add_path --prepend /run/current-system/sw/bin /nix/var/nix/profiles/default/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin
```

### Additional PATH entries

```fish
fish_add_path $HOME/go/bin
fish_add_path /opt/homebrew/opt/libpq/bin
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"; and fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

set -gx PNPM_HOME "$HOME/Library/pnpm"
fish_add_path $PNPM_HOME

set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path $BUN_INSTALL/bin
```

### Homebrew mirror configuration (China)

```fish
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.ustc.edu.cn/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-core.git"
set -gx HOMEBREW_BOTTLE_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles"
set -gx HOMEBREW_API_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles/api"
```

### Editor and GPG

```fish
set -gx EDITOR zed
set -gx VISUAL zed
set -gx GPG_TTY (tty)
```

### Custom functions in this repo

| Function | File | Description |
|---|---|---|
| `brew` | `functions/brew.fish` | Wraps `brew install`/`upgrade` with aria2 multi-connection pre-fetching and post-upgrade quarantine removal |
| `nix-up` | `functions/nix-up.fish` | Updates nix flake inputs and rebuilds darwin system (`--no-update` / `-n` to skip flake update) |
| `nix-add` | `functions/nix-add.fish` | Interactive search across nixpkgs and homebrew casks, adds selection to `tags.nix` and optionally rebuilds |
| `gccd` | `functions/gccd.fish` | `git clone --recurse-submodules` then `cd` into the cloned directory (derived from the URL, or the explicit destination argument) |
| `y` | `functions/y.fish` | Wraps `yazi` file manager with automatic `cd` to last visited directory on exit |
| `wt` | `functions/wt.fish` | Lazy-load stub for worktrunk: sources shell integration on first use, then re-dispatches |

### Custom completions

| File | Description |
|---|---|
| `completions/wt.fish` | Dynamic completions for worktrunk, delegates to the `wt` binary |
| `completions/gccd.fish` | Wraps `git clone` completions for `gccd` |

### Abbreviations

The config defines abbreviations for:

- **Worktrunk** (`wts`, `wtsc`, `wtl`, `wtr`, `wtm`, `wtc`, `wtsq`, `wtrb`, `wtsp`, `wtd`, `wtfe`, `wtpr`)
- **Git** — extensive set mirroring omz git plugin (`ga`, `gaa`, `gc`, `gd`, `gl`, `gp`, `gst`, `grb`, `gco`, `gsw`, etc.)

All abbreviations are defined in `config.fish`.

### conf.d/ snippets

| File | Description |
|---|---|
| `dotfiles_sync.fish` | Auto-syncs the dotfiles repo every 2 hours (fetch, pull --rebase, commit+push), with conflict detection and lock-file protection |
| `tide_one_dark.fish` | Applies Atom One Dark color palette to Tide prompt via universal variables (re-applied on every shell init) |

### Prompt theme

Uses Tide prompt (`IlanCosman/tide@v6`) with Atom One Dark colors configured via universal variables in `conf.d/tide_one_dark.fish`. Covers: character, PWD, git, status, cmd_duration, context, jobs, time, and language indicators (node, python, rust, go, docker, kubectl, direnv).

## Troubleshooting

```fish
# Debug fish startup
fish --debug='*' --debug-output=/tmp/fish-debug.log

# Check where a command comes from
type -a <command>

# List all abbreviations
abbr --list

# List all functions (including lazy-loaded)
functions

# Check completion paths
echo $fish_complete_path

# Reload config without restarting
source ~/.config/fish/config.fish

# Check if a command is available
command -q <command>; and echo "found"; or echo "not found"

# Profile startup time
fish --profile-startup=/tmp/fish-startup.prof -c exit
cat /tmp/fish-startup.prof
```
