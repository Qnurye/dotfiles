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
)

source $ZSH/oh-my-zsh.sh

# Aliases
alias vim="nvim"

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
