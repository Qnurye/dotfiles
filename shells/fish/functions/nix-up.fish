function nix-up --description 'Update nix flake and rebuild darwin system'
    set -l flake_dir ~/dotfiles/nix

    echo "Updating flake inputs..."
    nix flake update --flake $flake_dir
    or return 1

    echo ""
    echo "Rebuilding system..."
    sudo darwin-rebuild switch --flake $flake_dir
end
