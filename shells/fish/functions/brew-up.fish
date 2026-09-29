function brew-up --description 'Upgrade Homebrew formulae and casks without their own updater'
    brew update --quiet
    or return 1

    # Casks marked auto_updates are skipped (no --greedy): their apps update themselves.
    brew upgrade
    or return 1

    # The claude-code@latest cask moves to a new versioned Caskroom path on upgrade.
    claude-pin
end
