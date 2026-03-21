# Dotfiles - Fish Configuration
# https://github.com/Qnurye/dotfiles

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# PATH
fish_add_path $HOME/go/bin
fish_add_path /opt/homebrew/opt/libpq/bin

# JetBrains Toolbox
test -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"; and fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# pnpm
set -gx PNPM_HOME "$HOME/Library/pnpm"
fish_add_path $PNPM_HOME

# bun
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path $BUN_INSTALL/bin

# Cargo/Rust
test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"

# Local bin
test -f "$HOME/.local/bin/env.fish"; and source "$HOME/.local/bin/env.fish"

# GPG
set -gx GPG_TTY (tty)

# Editor
set -gx EDITOR zed
set -gx VISUAL zed

# Homebrew mirrors (China)
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.ustc.edu.cn/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-core.git"
set -gx HOMEBREW_BOTTLE_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles"
set -gx HOMEBREW_API_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# fnm (Fast Node Manager)
command -q fnm; and fnm env --use-on-cd --shell fish | source

# direnv
command -q direnv; and direnv hook fish | source

# autojump
test -f /opt/homebrew/share/autojump/autojump.fish; and source /opt/homebrew/share/autojump/autojump.fish

# worktrunk
command -q wt; and command wt config shell init fish | source

# Aliases
alias vim nvim
alias tns 'tmux new-session -d -s'

# Git abbreviations (replaces omz git plugin)
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gco 'git checkout'
abbr -a gd 'git diff'
abbr -a gl 'git pull'
abbr -a gp 'git push'
abbr -a gst 'git status'
abbr -a gb 'git branch'
abbr -a glg 'git log --oneline --graph'
abbr -a glog 'git log --oneline --decorate --graph'
