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

    __nix_up_reconcile_brew $flake_dir
    or return 1

    echo "Rebuilding system..."
    sudo darwin-rebuild switch --flake $flake_dir \
        --max-jobs auto \
        --cores 0
    or return 1

    __nix_up_record_brew $flake_dir

    # darwin-rebuild may have just installed the claude-code@latest cask.
    claude-pin

    echo ""
    echo "Checking dotfile links..."
    bash ~/dotfiles/install.sh check
    or echo "Link conflicts found — review the diffs above, merge into ~/dotfiles, then run 'bash ~/dotfiles/install.sh check' again."
end

function __nix_up_brew_state
    echo ~/.local/state/dotfiles/brew-applied-(scutil --get LocalHostName)
end

function __nix_up_brew_declared --argument-names flake_dir
    set -l host (scutil --get LocalHostName)
    nix eval --json "$flake_dir#darwinConfigurations.$host.config.homebrew" \
        --apply 'h: map (b: "brew:" + b.name) h.brews ++ map (c: "cask:" + c.name) h.casks' 2>/dev/null \
        | jq -r '.[]'
end

function __nix_up_brew_installed
    brew list --formula -1 | string replace -r '^' 'brew:'
    brew list --cask -1 | string replace -r '^' 'cask:'
end

function __nix_up_undeclare --argument-names name tags_file
    set -l before (cksum < $tags_file)
    sd -F -- "\"$name\" " '' $tags_file
    sd -F -- "\"$name\"" '' $tags_file
    test "$before" != (cksum < $tags_file)
end

# Homebrew activation is install-only, so a package uninstalled by hand comes
# back on every rebuild unless its declaration goes too. Anything a previous
# rebuild applied that is now missing was removed on purpose: settle it here.
function __nix_up_reconcile_brew --argument-names flake_dir
    set -l state (__nix_up_brew_state)
    test -f $state; or return 0

    set -l declared (__nix_up_brew_declared $flake_dir)
    if test (count $declared) -eq 0
        echo "Could not evaluate declared Homebrew packages; skipping the drift check."
        return 0
    end
    set -l applied (cat $state)
    set -l installed (__nix_up_brew_installed)

    for entry in $declared
        contains -- $entry $applied; or continue
        set -l parts (string split -m1 : $entry)
        set -l short (string split -r -m1 / $parts[2])[-1]
        contains -- "$parts[1]:$short" $installed; and continue

        echo "$parts[2] ($parts[1]) is declared but was uninstalled since the last rebuild."
        read -P "  [r]emove from tags.nix / [i]nstall again / [a]bort: " choice
        switch $choice
            case r R ''
                if __nix_up_undeclare $parts[2] $flake_dir/tags.nix
                    echo "  Removed '$parts[2]' from tags.nix"
                else
                    echo "  '$parts[2]' is not declared in tags.nix; remove it from nix/modules/darwin/homebrew.nix by hand."
                    return 1
                end
            case i I
            case '*'
                return 1
        end
    end
end

function __nix_up_record_brew --argument-names flake_dir
    set -l declared (__nix_up_brew_declared $flake_dir)
    test (count $declared) -gt 0; or return 0
    set -l state (__nix_up_brew_state)
    mkdir -p (path dirname $state)
    printf '%s\n' $declared > $state
end
