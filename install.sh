#!/bin/bash
# Dotfiles Installation Script
# https://github.com/Qnurye/dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# LINK_MODE=check makes backup_and_link verify/repair instead of clobbering:
# apps that save via atomic write (temp file + rename) silently replace managed
# symlinks with regular files, so diverged content must be surfaced, not overwritten.
LINK_MODE="${LINK_MODE:-install}"
LINKS_FIXED=0
LINK_CONFLICTS=0

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [[ "$LINK_MODE" == "check" ]]; then
        check_link "$src" "$dest"
        return
    fi

    if [[ -e "$dest" && ! -L "$dest" ]]; then
        warn "Backing up existing $dest to $dest.backup"
        mv "$dest" "$dest.backup"
    elif [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    ln -sf "$src" "$dest"
    info "Linked $src -> $dest"
}

check_link() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" ]]; then
        if [[ "$(readlink "$dest")" == "$src" || "$dest" -ef "$src" ]]; then
            return
        fi
        rm "$dest"
        ln -s "$src" "$dest"
        info "Re-pointed $dest -> $src"
        LINKS_FIXED=$((LINKS_FIXED + 1))
    elif [[ ! -e "$dest" ]]; then
        ln -s "$src" "$dest"
        info "Restored missing link $dest -> $src"
        LINKS_FIXED=$((LINKS_FIXED + 1))
    elif diff -rq "$src" "$dest" &>/dev/null; then
        rm -rf "$dest"
        ln -s "$src" "$dest"
        info "Relinked $dest (was a plain copy, content unchanged)"
        LINKS_FIXED=$((LINKS_FIXED + 1))
    else
        warn "CONFLICT: $dest diverged from $src"
        warn "  review with: diff '$src' '$dest'   # merge into the repo, then re-run"
        LINK_CONFLICTS=$((LINK_CONFLICTS + 1))
    fi
}

# Install Homebrew if not present (prerequisite for everything)
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Module functions ---

install_homebrew() {
    if [[ -f "$DOTFILES_DIR/homebrew/Brewfile" ]]; then
        info "Installing Homebrew packages (this may take a while)..."
        read -p "Install all Homebrew packages? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew bundle --file="$DOTFILES_DIR/homebrew/Brewfile"
        else
            info "Skipping Homebrew packages. Run 'brew bundle --file=$DOTFILES_DIR/homebrew/Brewfile' later."
        fi
    fi
}

install_fish() {
    info "Linking Fish configurations..."
    mkdir -p "$HOME/.config/fish/conf.d"
    mkdir -p "$HOME/.config/fish/functions"
    mkdir -p "$HOME/.config/fish/completions"
    backup_and_link "$DOTFILES_DIR/shells/fish/config.fish" "$HOME/.config/fish/config.fish"
    for f in "$DOTFILES_DIR/shells/fish/conf.d/"*.fish; do
        [[ -f "$f" ]] && backup_and_link "$f" "$HOME/.config/fish/conf.d/$(basename "$f")"
    done
    for f in "$DOTFILES_DIR/shells/fish/functions/"*.fish; do
        [[ -f "$f" ]] && backup_and_link "$f" "$HOME/.config/fish/functions/$(basename "$f")"
    done
    for f in "$DOTFILES_DIR/shells/fish/completions/"*.fish; do
        [[ -f "$f" ]] && backup_and_link "$f" "$HOME/.config/fish/completions/$(basename "$f")"
    done
    backup_and_link "$DOTFILES_DIR/shells/fish/fish_plugins" "$HOME/.config/fish/fish_plugins"

    # Install Fish plugins (fisher is installed via Homebrew)
    if [[ "$LINK_MODE" != "check" ]] && command -v fish &>/dev/null && fish -c "type -q fisher" 2>/dev/null; then
        info "Installing Fish plugins..."
        fish -c "fisher update" 2>/dev/null
    fi
}

install_git() {
    info "Linking Git configuration..."
    backup_and_link "$DOTFILES_DIR/vcs/git/.gitconfig" "$HOME/.gitconfig"
    backup_and_link "$DOTFILES_DIR/vcs/git/.gitignore_global" "$HOME/.gitignore_global"
    backup_and_link "$DOTFILES_DIR/vcs/git/.work.gitconfig" "$HOME/.work.gitconfig"
}

install_tmux() {
    # Install Oh My Tmux if not present
    if [[ "$LINK_MODE" != "check" ]] && { [[ ! -f "$HOME/.tmux.conf" ]] || ! grep -q "gpakosz" "$HOME/.tmux.conf" 2>/dev/null; }; then
        info "Installing Oh My Tmux..."
        cd "$HOME"
        git clone https://github.com/gpakosz/.tmux.git
        ln -sf .tmux/.tmux.conf
        cd "$DOTFILES_DIR"
    fi

    info "Linking Tmux configuration..."
    backup_and_link "$DOTFILES_DIR/terminals/tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
}

install_zed() {
    info "Linking Zed configuration..."
    mkdir -p "$HOME/.config/zed"
    backup_and_link "$DOTFILES_DIR/editors/zed/settings.json" "$HOME/.config/zed/settings.json"
}

install_ghostty() {
    info "Linking Ghostty configuration..."
    mkdir -p "$HOME/.config/ghostty"
    backup_and_link "$DOTFILES_DIR/terminals/ghostty/config" "$HOME/.config/ghostty/config"
}

install_lazygit() {
    info "Linking Lazygit configuration..."
    mkdir -p "$HOME/Library/Application Support/lazygit"
    backup_and_link "$DOTFILES_DIR/vcs/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
}

install_worktrunk() {
    info "Linking Worktrunk configuration..."
    mkdir -p "$HOME/.config/worktrunk"
    backup_and_link "$DOTFILES_DIR/tools/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"
}

install_agents() {
    info "Linking AI agent configurations..."
    mkdir -p "$HOME/.claude" "$HOME/.gemini"
    backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/AGENTS.md"
    backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
    backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.gemini/GEMINI.md"
    backup_and_link "$DOTFILES_DIR/agents/claude-settings.json" "$HOME/.claude/settings.json"
    backup_and_link "$DOTFILES_DIR/agents/RTK.md" "$HOME/.claude/RTK.md"

    # Link Claude Code skills and agents (canonical location: ~/.claude/skills)
    info "Linking Claude Code skills and agents..."
    mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"
    for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
        [[ -d "$skill_dir" ]] || continue
        skill_name="$(basename "$skill_dir")"
        backup_and_link "$skill_dir" "$HOME/.claude/skills/$skill_name"
    done
    for agent_file in "$DOTFILES_DIR/agents/agents"/*.md; do
        [[ -f "$agent_file" ]] || continue
        agent_name="$(basename "$agent_file")"
        backup_and_link "$agent_file" "$HOME/.claude/agents/$agent_name"
    done

    # Link other agents' skills to ~/.claude/skills (central hub)
    info "Linking agent skills to central hub..."
    mkdir -p "$HOME/.agents" "$HOME/.codex"
    backup_and_link "$HOME/.claude/skills" "$HOME/.agents/skills"
    backup_and_link "$HOME/.claude/skills" "$HOME/.gemini/skills"
    backup_and_link "$HOME/.claude/skills" "$HOME/.codex/skills"
}

install_nix() {
    # Check for Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        error "Xcode Command Line Tools required. Install with: xcode-select --install"
        return 1
    fi

    # Install Nix if not present
    if ! command -v nix &>/dev/null; then
        info "Installing Nix via Determinate Systems installer..."
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
        # Source nix in current shell
        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
    fi

    # Move conflicting /etc files out of the way for nix-darwin activation
    local etc_files=(bashrc zshrc zprofile)
    for f in "${etc_files[@]}"; do
        if [[ -f "/etc/$f" && ! -f "/etc/$f.before-nix-darwin" ]]; then
            info "Backing up /etc/$f → /etc/$f.before-nix-darwin"
            sudo mv "/etc/$f" "/etc/$f.before-nix-darwin"
        fi
    done

    info "Activating nix-darwin configuration..."
    local hostname
    hostname=$(scutil --get LocalHostName 2>/dev/null || hostname -s)

    if command -v darwin-rebuild &>/dev/null; then
        sudo darwin-rebuild switch --flake "$DOTFILES_DIR/nix#$hostname"
    else
        info "First run: bootstrapping nix-darwin..."
        sudo nix run nix-darwin -- switch --flake "$DOTFILES_DIR/nix#$hostname"
    fi
}

install_system() {
    info "Installing sudoers overrides..."
    if [[ -d "$DOTFILES_DIR/system/sudoers.d" ]]; then
        for f in "$DOTFILES_DIR/system/sudoers.d"/*; do
            local_name="$(basename "$f")"
            dest="/etc/sudoers.d/$local_name"
            if ! diff -q "$f" "$dest" &>/dev/null; then
                sudo cp "$f" "$dest"
                sudo chmod 0440 "$dest"
                sudo chown root:wheel "$dest"
                info "Installed sudoers.d/$local_name"
            else
                info "sudoers.d/$local_name already up to date"
            fi
        done
    fi
}

# --- Main ---

if [[ $# -eq 0 ]]; then
    install_homebrew
    install_fish
    install_git
    install_tmux
    install_zed
    install_ghostty
    install_lazygit
    install_worktrunk
    install_agents
    install_system
    install_nix
else
    for arg in "$@"; do
        case "$arg" in
            check)
                LINK_MODE=check
                install_fish
                install_git
                install_tmux
                install_zed
                install_ghostty
                install_lazygit
                install_worktrunk
                install_agents
                ;;
            fish|git|tmux|zed|ghostty|lazygit|worktrunk|agents|system|homebrew|nix)
                "install_$arg"
                ;;
            *)
                error "Unknown module: $arg"
                echo "Available: check fish git tmux zed ghostty lazygit worktrunk agents system homebrew nix"
                exit 1
                ;;
        esac
    done
fi

if [[ "$LINK_MODE" == "check" ]]; then
    echo ""
    if [[ "$LINK_CONFLICTS" -gt 0 ]]; then
        error "Link check: $LINK_CONFLICTS conflict(s) found, $LINKS_FIXED link(s) fixed"
        exit 1
    fi
    info "Link check: all links OK ($LINKS_FIXED fixed)"
    exit 0
fi

# Post-install reminders
echo ""
echo "============================================"
echo "Installation complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Set Fish as default shell:"
echo "   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells"
echo "   chsh -s /opt/homebrew/bin/fish"
echo ""
echo "2. Configure Git user:"
echo "   git config --global user.name 'Your Name'"
echo "   git config --global user.email 'your@email.com'"
echo ""
echo "3. If using GPG signing:"
echo "   git config --global user.signingkey 'YOUR_GPG_KEY'"
echo ""
