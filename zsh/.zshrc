# Dotfiles - ZSH Configuration
# https://github.com/Qnurye/dotfiles

# PATH
export PATH=$HOME/go/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# GPG Agent
export GPG_TTY=$(tty)

# Theme
ZSH_THEME="gozilla"

# Plugins
plugins=(
  npm
  history
  git
  tmux
)

source $ZSH/oh-my-zsh.sh

# Aliases
alias vim="nvim"
wtc() { wt switch --base "$(git branch --show-current)" -x claude --create "$1" -- --permission-mode acceptEdits "${@:2}"; }
alias tns='tmux new-session -d -s'

# Spaceship prompt (if using)
SPACESHIP_TIME_SHOW="true"
SPACESHIP_USER_SHOW="always"
SPACESHIP_USER_COLOR="212"

# Homebrew plugins (install via: brew install zsh-syntax-highlighting zsh-autosuggestions autojump)
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/etc/profile.d/autojump.sh ]] && \
  source /opt/homebrew/etc/profile.d/autojump.sh

# fnm (Fast Node Manager)
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# direnv
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# Homebrew mirrors (China)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# Local bin
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Editor
export EDITOR="zed"
export VISUAL="zed"

# bun
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Brew hook - auto sync Brewfile after install/uninstall
brew() {
  local BREWFILE="$HOME/dotfiles/homebrew/Brewfile"
  command brew "$@"
  local ret=$?
  if [[ $ret -eq 0 && -d "$HOME/dotfiles" ]]; then
    case "$1" in
      install|uninstall|remove|rmtree|autoremove)
        echo "\n📦 Syncing Brewfile..."
        command brew bundle dump --file="$BREWFILE" --force
        if git -C "$HOME/dotfiles" diff --quiet "$BREWFILE" 2>/dev/null; then
          echo "✓ Brewfile unchanged"
        else
          echo "✓ Brewfile updated"
        fi
        ;;
    esac
  fi
  return $ret
}

# Dotfiles auto-sync (every 2 hours)
_dotfiles_auto_sync() {
  local DOTFILES_DIR="$HOME/dotfiles"
  local SYNC_MARKER="$DOTFILES_DIR/.last_sync"
  local SYNC_INTERVAL=$((2 * 60 * 60))  # 2 hours in seconds

  [[ ! -d "$DOTFILES_DIR/.git" ]] && return

  local now=$(date +%s)
  local last_sync=0
  [[ -f "$SYNC_MARKER" ]] && last_sync=$(cat "$SYNC_MARKER")

  if (( now - last_sync >= SYNC_INTERVAL )); then
    (
      cd "$DOTFILES_DIR"
      # Pull with rebase
      git pull --rebase --quiet 2>/dev/null
      # Commit if there are changes
      if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        git add -A
        git commit -m "chore: auto sync dotfiles" --quiet
      fi
      # Push if ahead of remote
      if git status | grep -q "Your branch is ahead"; then
        git push --quiet 2>/dev/null
      fi
      echo "$now" > "$SYNC_MARKER"
    ) &>/dev/null &!
  fi
}
_dotfiles_auto_sync
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# OpenClaw Completion
source "/Users/qnurye/.openclaw/completions/openclaw.zsh"
