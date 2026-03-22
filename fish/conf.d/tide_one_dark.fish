# Tide prompt — Atom One Dark colors & icons
# Layout is managed by `tide configure`, this file applies colors and icons.
# Re-applied on every shell init to keep appearance consistent.
#
# Atom One Dark palette:
#   red=#E06C75 green=#98C379 yellow=#E5C07B blue=#61AFEF
#   purple=#C678DD cyan=#56B6C2 fg=#ABB2BF grey=#5C6370

# Character
set -U tide_character_color 98C379
set -U tide_character_color_failure E06C75

# OS
set -U tide_os_bg_color normal
set -U tide_os_color ABB2BF

# PWD
set -U tide_pwd_bg_color normal
set -U tide_pwd_color_anchors 61AFEF
set -U tide_pwd_color_dirs 61AFEF
set -U tide_pwd_color_truncated_dirs 5C6370

# Git
set -U tide_git_bg_color normal
set -U tide_git_bg_color_unstable normal
set -U tide_git_bg_color_urgent normal
set -U tide_git_color_branch C678DD
set -U tide_git_color_operation E5C07B
set -U tide_git_color_stash C678DD
set -U tide_git_color_staged 98C379
set -U tide_git_color_dirty E5C07B
set -U tide_git_color_untracked 56B6C2
set -U tide_git_color_upstream 98C379
set -U tide_git_icon ' '

# Status
set -U tide_status_bg_color normal
set -U tide_status_bg_color_failure normal
set -U tide_status_color 98C379
set -U tide_status_color_failure E06C75

# Command duration
set -U tide_cmd_duration_bg_color normal
set -U tide_cmd_duration_color E5C07B

# Context (user@host)
set -U tide_context_bg_color normal
set -U tide_context_color_default C678DD
set -U tide_context_color_root E06C75
set -U tide_context_color_ssh E5C07B

# Jobs
set -U tide_jobs_bg_color normal
set -U tide_jobs_color 61AFEF
set -U tide_jobs_icon ' '

# Time
set -U tide_time_bg_color normal
set -U tide_time_color 5C6370

# Node
set -U tide_node_bg_color normal
set -U tide_node_color 98C379
set -U tide_node_icon ' '

# Python
set -U tide_python_bg_color normal
set -U tide_python_color E5C07B
set -U tide_python_icon ' '

# Rust
set -U tide_rustc_bg_color normal
set -U tide_rustc_color E06C75
set -U tide_rustc_icon ' '

# Go
set -U tide_go_bg_color normal
set -U tide_go_color 56B6C2
set -U tide_go_icon ' '

# Docker
set -U tide_docker_bg_color normal
set -U tide_docker_color 61AFEF
set -U tide_docker_icon ' '

# Kubectl
set -U tide_kubectl_bg_color normal
set -U tide_kubectl_color 56B6C2
set -U tide_kubectl_icon '󱃾 '

# Direnv
set -U tide_direnv_bg_color normal
set -U tide_direnv_bg_color_denied normal
set -U tide_direnv_color E5C07B
set -U tide_direnv_color_denied E06C75
