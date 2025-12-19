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

# Install Oh My Zsh if not present
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

# Link ZSH configurations
info "Linking ZSH configurations..."
backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

# Link Git configuration
info "Linking Git configuration..."
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Link Tmux configuration
info "Linking Tmux configuration..."
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"

# Link Zed configuration
info "Linking Zed configuration..."
mkdir -p "$HOME/.config/zed"
backup_and_link "$DOTFILES_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"

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
echo "3. Restart your terminal or run: source ~/.zshrc"
echo ""
