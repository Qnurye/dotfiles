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

backup_and_link() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" && ! -L "$dest" ]]; then
        warn "Backing up existing $dest to $dest.backup"
        mv "$dest" "$dest.backup"
    elif [[ -L "$dest" ]]; then
        rm "$dest"
    fi

    ln -sf "$src" "$dest"
    info "Linked $src -> $dest"
}

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Oh My Zsh if not present (legacy, kept for fallback)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Oh My Tmux if not present
if [[ ! -f "$HOME/.tmux.conf" ]] || ! grep -q "gpakosz" "$HOME/.tmux.conf" 2>/dev/null; then
    info "Installing Oh My Tmux..."
    cd "$HOME"
    git clone https://github.com/gpakosz/.tmux.git
    ln -sf .tmux/.tmux.conf
fi

# Link ZSH configurations (legacy, kept for fallback)
info "Linking ZSH configurations..."
backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

# Link Fish configurations
info "Linking Fish configurations..."
mkdir -p "$HOME/.config/fish/conf.d"
mkdir -p "$HOME/.config/fish/functions"
backup_and_link "$DOTFILES_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
for f in "$DOTFILES_DIR/fish/conf.d/"*.fish; do
    [[ -f "$f" ]] && backup_and_link "$f" "$HOME/.config/fish/conf.d/$(basename "$f")"
done
for f in "$DOTFILES_DIR/fish/functions/"*.fish; do
    [[ -f "$f" ]] && backup_and_link "$f" "$HOME/.config/fish/functions/$(basename "$f")"
done

# Link Git configuration
info "Linking Git configuration..."
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
backup_and_link "$DOTFILES_DIR/git/.work.gitconfig" "$HOME/.work.gitconfig"

# Link Tmux configuration
info "Linking Tmux configuration..."
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"

# Link Zed configuration
info "Linking Zed configuration..."
mkdir -p "$HOME/.config/zed"
backup_and_link "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"

# Link Ghostty configuration
info "Linking Ghostty configuration..."
mkdir -p "$HOME/.config/ghostty"
backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# Link Lazygit configuration
info "Linking Lazygit configuration..."
mkdir -p "$HOME/Library/Application Support/lazygit"
backup_and_link "$DOTFILES_DIR/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

# Link Worktrunk configuration
info "Linking Worktrunk configuration..."
mkdir -p "$HOME/.config/worktrunk"
backup_and_link "$DOTFILES_DIR/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"

# Link AI agent configurations
info "Linking AI agent configurations..."
backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/AGENTS.md"
backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
backup_and_link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.gemini/GEMINI.md"
mkdir -p "$HOME/.claude"
backup_and_link "$DOTFILES_DIR/agents/claude-settings.json" "$HOME/.claude/settings.json"

# Link Claude Code skills and agents
info "Linking Claude Code skills..."
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents"
for skill_dir in "$DOTFILES_DIR/agents/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    backup_and_link "$skill_dir" "$HOME/.claude/skills/$skill_name"
done
for agent_file in "$DOTFILES_DIR/agents/agents"/*.md; do
    agent_name="$(basename "$agent_file")"
    backup_and_link "$agent_file" "$HOME/.claude/agents/$agent_name"
done

# Install sudoers overrides
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

# Install Homebrew packages
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


# Post-install reminders
echo ""
echo "============================================"
echo "Installation complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Configure Git user:"
echo "   git config --global user.name 'Your Name'"
echo "   git config --global user.email 'your@email.com'"
echo ""
echo "2. If using GPG signing:"
echo "   git config --global user.signingkey 'YOUR_GPG_KEY'"
echo ""
echo "3. Set Fish as default shell:"
echo "   echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells"
echo "   chsh -s /opt/homebrew/bin/fish"
echo ""
echo "4. Or restart your terminal with: source ~/.zshrc (for zsh)"
echo ""
