# Dotfiles - Fish Configuration
# https://github.com/Qnurye/dotfiles

# Disable the interactive shell greeting
set -g fish_greeting

# Homebrew
eval (/opt/homebrew/bin/brew shellenv)

# Nix (re-add after brew shellenv resets PATH)
fish_add_path --prepend /run/current-system/sw/bin /nix/var/nix/profiles/default/bin $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin

# Nix completions: tmux/Ghostty sessions can outlive nix-darwin activations and
# inherit a stale XDG_DATA_DIRS, leaving fish_complete_path without the nix
# vendor_completions dirs. Append them so nix-installed completions (eza, fd,
# ripgrep, ...) are reachable. Append (not prepend) so ~/.config/fish/completions
# and homebrew vendor dirs keep their priority — otherwise nix's older copies of
# tools also installed via homebrew (e.g. worktrunk) would shadow the active
# binary's matching completion file.
for nix_dir in $HOME/.nix-profile/share/fish/vendor_completions.d \
               /etc/profiles/per-user/$USER/share/fish/vendor_completions.d \
               /run/current-system/sw/share/fish/vendor_completions.d \
               /nix/var/nix/profiles/default/share/fish/vendor_completions.d
    test -d $nix_dir; and not contains -- $nix_dir $fish_complete_path
    and set -a fish_complete_path $nix_dir
end

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
set -gx EDITOR "zed --wait"
set -gx VISUAL "zed --wait"

# USTC mirror — SJTU's bottle mirror stopped syncing (404s on arm64_tahoe bottles)
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.ustc.edu.cn/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-core.git"
set -gx HOMEBREW_BOTTLE_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles"
set -gx HOMEBREW_API_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# fnm (Fast Node Manager)
command -q fnm; and fnm env --use-on-cd --log-level quiet --shell fish | source

# direnv
command -q direnv; and direnv hook fish | source

# zoxide (smarter cd — defines z, zi)
command -q zoxide; and zoxide init fish | source

# Worktrunk abbreviations
abbr -a wts 'wt switch'
abbr -a wtsc 'wt switch --create'
abbr -a wtl 'wt list'
abbr -a wtr 'wt remove'
abbr -a wtm 'wt merge'
# wt step
abbr -a wtc 'wt step commit'
abbr -a wtsq 'wt step squash'
abbr -a wtrb 'wt step rebase'
abbr -a wtsp 'wt step push'
abbr -a wtd 'wt step diff'
abbr -a wtfe 'wt step for-each'
abbr -a wtpr 'wt step prune'

# Aliases
alias vim nvim
alias tns 'tmux new-session -d -s'

# Git abbreviations (replaces omz git plugin)
# add
abbr -a ga 'git add'
abbr -a gaa 'git add --all'
abbr -a gapa 'git add --patch'
# branch
abbr -a gb 'git branch'
abbr -a gba 'git branch --all'
abbr -a gbd 'git branch --delete'
abbr -a gbD 'git branch --delete --force'
abbr -a gbr 'git branch --remote'
# checkout / switch
abbr -a gco 'git checkout'
abbr -a gcb 'git checkout -b'
abbr -a gcm 'git checkout main'
abbr -a gsw 'git switch'
abbr -a gswc 'git switch --create'
# commit
abbr -a gc 'git commit --verbose'
abbr -a gcmsg 'git commit --message'
abbr -a 'gc!' 'git commit --verbose --amend'
abbr -a gca 'git commit --verbose --all'
abbr -a 'gca!' 'git commit --verbose --all --amend'
abbr -a gcam 'git commit --all --message'
# diff
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gdca 'git diff --cached'
abbr -a gdw 'git diff --word-diff'
# fetch
abbr -a gf 'git fetch'
abbr -a gfo 'git fetch origin'
# log
abbr -a glg 'git log --oneline --graph'
abbr -a glog 'git log --oneline --decorate --graph'
abbr -a glgg 'git log --graph'
abbr -a gcount 'git shortlog --summary --numbered'
# merge
abbr -a gm 'git merge'
abbr -a gma 'git merge --abort'
# pull / push
abbr -a gl 'git pull'
abbr -a gp 'git push'
abbr -a gpf 'git push --force-with-lease'
abbr -a 'gpf!' 'git push --force'
abbr -a gpd 'git push --dry-run'
abbr -a gpsup 'git push --set-upstream origin (git branch --show-current)'
# rebase
abbr -a grb 'git rebase'
abbr -a grba 'git rebase --abort'
abbr -a grbc 'git rebase --continue'
abbr -a grbi 'git rebase --interactive'
abbr -a grbm 'git rebase main'
abbr -a grbom 'git rebase origin/main'
# reset / restore
abbr -a grh 'git reset'
abbr -a grhh 'git reset --hard'
abbr -a grhs 'git reset --soft'
abbr -a grs 'git restore'
abbr -a grst 'git restore --staged'
# remote
abbr -a gr 'git remote'
abbr -a grv 'git remote --verbose'
# show
abbr -a gsh 'git show'
# stash
abbr -a gsta 'git stash'
abbr -a gstaa 'git stash apply'
abbr -a gstd 'git stash drop'
abbr -a gstl 'git stash list'
abbr -a gstp 'git stash pop'
abbr -a gsts 'git stash show --patch'
# status
abbr -a gst 'git status'
abbr -a gss 'git status --short'
abbr -a gsb 'git status --short --branch'
# tag
abbr -a gta 'git tag --annotate'
abbr -a gtv 'git tag | sort -V'
# cherry-pick
abbr -a gcp 'git cherry-pick'
abbr -a gcpa 'git cherry-pick --abort'
abbr -a gcpc 'git cherry-pick --continue'
# worktree
abbr -a gwt 'git worktree'
abbr -a gwta 'git worktree add'
abbr -a gwtls 'git worktree list'
abbr -a gwtrm 'git worktree remove'
# misc
abbr -a gcl 'git clone --recurse-submodules'
abbr -a gbl 'git blame -w'
abbr -a grm 'git rm'
abbr -a grmc 'git rm --cached'
abbr -a grev 'git revert'
