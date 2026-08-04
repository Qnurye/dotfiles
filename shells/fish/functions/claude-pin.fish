function claude-pin --description 'Hardlink the Claude Code CLI onto a version-free path so macOS TCC grants survive upgrades'
    # macOS keys TCC entries for bare (non-bundle) executables on the absolute path.
    # The cask lives at Caskroom/claude-code@latest/<version>/claude, so every upgrade
    # reads as a brand-new program and re-triggers every permission prompt. Hardlinking
    # the fresh binary onto a path with no version in it keeps the TCC subject stable;
    # the stored code requirement (com.anthropic.claude-code / OU=Q6L2SF6YDW) is
    # version-independent, so the existing grants keep matching.
    set -l pin_dir $HOME/.local/libexec/claude-code
    set -l pin $pin_dir/claude
    set -l brew_link /opt/homebrew/bin/claude

    if not test -e $brew_link
        echo "claude-pin: $brew_link missing — is the claude-code@latest cask installed?" >&2
        return 1
    end

    set -l src (readlink -f $brew_link)

    # Absolute path: nix's coreutils stat shadows BSD stat and reads -f as --file-system
    if test -e $pin; and test (/usr/bin/stat -f %i $pin) -eq (/usr/bin/stat -f %i $src)
        return 0
    end

    mkdir -p $pin_dir; or return 1

    if not ln -f $src $pin 2>/dev/null
        cp -f $src $pin; or return 1
    end

    # Assert the exact identity TCC will re-check on every launch — if this ever stops
    # matching, the grants are lost regardless and pinning a foreign binary would be worse
    set -l req 'identifier "com.anthropic.claude-code" and anchor apple generic and certificate leaf[subject.OU] = Q6L2SF6YDW'
    if not codesign --verify --strict -R=$req $pin 2>/dev/null
        echo "claude-pin: $pin failed signature/identity check — leaving it in place, expect a permission prompt" >&2
        return 1
    end

    # stderr: config.fish calls this on every shell, and a stray stdout line would
    # contaminate command substitutions in scripts that spawn fish
    echo "claude-pin: pinned "(basename (dirname $src))" → $pin" >&2
end
