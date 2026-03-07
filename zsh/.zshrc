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

# Brew hook - auto remove quarantine after upgrade
brew() {
  command brew "$@"
  local ret=$?
  if [[ $ret -eq 0 ]]; then
    case "$1" in
      upgrade)
        echo "\n🔓 Removing quarantine from Applications..."
        local count=0
        for app in /Applications/*.app; do
          if xattr -l "$app" 2>/dev/null | grep -q "com.apple.quarantine"; then
            xattr -rd com.apple.quarantine "$app" 2>/dev/null && ((count++))
          fi
        done
        if (( count > 0 )); then
          echo "✓ Removed quarantine from $count app(s)"
        else
          echo "✓ No quarantined apps found"
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
  (( now - last_sync < SYNC_INTERVAL )) && return

  local git="git -C $DOTFILES_DIR"

  # Fetch remote quietly in background; check result on next invocation
  local fetch_marker="$DOTFILES_DIR/.last_fetch"
  if [[ ! -f "$fetch_marker" ]]; then
    ( $git fetch --quiet 2>/dev/null && echo "$now" > "$fetch_marker" ) &!
    return
  fi

  # Determine local and remote state
  local has_local=false has_remote=false
  if ! $git diff --quiet 2>/dev/null || ! $git diff --cached --quiet 2>/dev/null || \
     [[ -n "$($git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
    has_local=true
  fi
  local local_head=$($git rev-parse HEAD 2>/dev/null)
  local remote_head=$($git rev-parse @{u} 2>/dev/null)
  local merge_base=$($git merge-base HEAD @{u} 2>/dev/null)
  if [[ "$local_head" != "$remote_head" && "$remote_head" != "$merge_base" ]]; then
    has_remote=true
  fi

  rm -f "$fetch_marker"

  # Case 1: Nothing to do
  if ! $has_local && ! $has_remote; then
    echo "$now" > "$SYNC_MARKER"
    return
  fi

  # Case 2: Only remote changes — fast-forward pull
  if ! $has_local && $has_remote; then
    ( cd "$DOTFILES_DIR" && git pull --rebase --quiet 2>/dev/null && echo "$now" > "$SYNC_MARKER" ) &!
    return
  fi

  # Case 3: Only local changes — commit and push
  if $has_local && ! $has_remote; then
    (
      cd "$DOTFILES_DIR"
      git add -A
      git commit -m "chore: auto sync dotfiles" --quiet 2>/dev/null
      git push --quiet 2>/dev/null
      echo "$now" > "$SYNC_MARKER"
    ) &!
    return
  fi

  # Case 4: Both have changes — try rebase, detect conflicts
  (
    cd "$DOTFILES_DIR"
    git add -A
    git commit -m "chore: auto sync dotfiles" --quiet 2>/dev/null

    if git rebase --quiet @{u} 2>/dev/null; then
      # No conflicts — push
      git push --quiet 2>/dev/null
      echo "$now" > "$SYNC_MARKER"
    else
      # Conflict detected — abort and leave a marker for the user
      git rebase --abort 2>/dev/null
      echo "conflict" > "$DOTFILES_DIR/.sync_conflict"
    fi
  ) &!
}

# Prompt user if a previous sync detected conflicts
_dotfiles_conflict_check() {
  local conflict_marker="$HOME/dotfiles/.sync_conflict"
  [[ ! -f "$conflict_marker" ]] && return

  echo "\033[1;33m[dotfiles]\033[0m Sync conflict detected — local and remote dotfiles have diverged."
  echo "  cd ~/dotfiles && git rebase origin/main"
  echo ""
  read -q "reply?Resolve now? [y/N] " 2>/dev/null
  echo ""
  if [[ "$reply" == "y" ]]; then
    rm -f "$conflict_marker"
    ( cd "$HOME/dotfiles" && git rebase @{u} )
  else
    echo "  Run \033[1mcd ~/dotfiles && git rebase origin/main\033[0m when ready."
  fi
}

_dotfiles_conflict_check
_dotfiles_auto_sync
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Yazi — shell wrapper (退出后自动 cd 到浏览的目录)
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# OpenClaw Completion
# source "/Users/qnurye/.openclaw/completions/openclaw.zsh"
