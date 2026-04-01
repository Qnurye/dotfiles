function nix-up --description 'Update nix flake and rebuild darwin system'
    set -l flake_dir ~/dotfiles/nix
    set -l skip_update 0

    for arg in $argv
        switch $arg
            case --no-update -n
                set skip_update 1
        end
    end

    if test $skip_update -eq 0
        echo "Updating flake inputs..."
        nix flake update --flake $flake_dir
        or return 1
        echo ""
    end

    echo "Rebuilding system..."
    sudo darwin-rebuild switch --flake $flake_dir \
        --max-jobs auto \
        --cores 0
end
