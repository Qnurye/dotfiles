# Dotfiles - ZSH Profile
# https://github.com/Qnurye/dotfiles

# JetBrains Toolbox
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && \
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Homebrew mirrors (China)
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
