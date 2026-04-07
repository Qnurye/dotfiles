function brew --description 'Brew wrapper: aria2 pre-fetch + quarantine removal'

    # ── Aria2 pre-fetch ──────────────────────────────────────────
    switch $argv[1]
        case install upgrade
            if not command -q aria2c
                echo "⚠ aria2c not found — using default curl for downloads"
            else
                # Determine target packages
                set -l packages
                set -l use_cask 0

                for arg in $argv[2..]
                    if test "$arg" = --cask
                        set use_cask 1
                    else if not string match -q -- '-*' $arg
                        set -a packages $arg
                    end
                end

                # brew upgrade with no args → fetch outdated list
                if test "$argv[1]" = upgrade -a (count $packages) -eq 0
                    if test $use_cask -eq 1
                        set packages (brew outdated --cask --quiet 2>/dev/null)
                    else
                        set packages (brew outdated --quiet 2>/dev/null)
                        # Also include outdated casks (upgrade without --cask upgrades both)
                        set -a packages (brew outdated --cask --quiet 2>/dev/null)
                    end
                end

                # Detect bottle platform prefix once
                if test (uname -m) = arm64
                    set -l plat_filter '^arm64_'
                else
                    set -l plat_filter '^(ventura|sonoma|sequoia|monterey)'
                end

                for pkg in $packages
                    set -l cache_path ''
                    set -l url ''
                    set -l is_cask $use_cask

                    if test $is_cask -eq 1
                        # Explicit --cask: resolve as cask
                        set cache_path (brew --cache --cask $pkg 2>/dev/null)
                        set url (brew info --json=v2 --cask $pkg 2>/dev/null \
                                 | jq -r '.casks[0].url // empty')
                    else
                        # Try formula first
                        set cache_path (brew --cache $pkg 2>/dev/null)
                        set url (brew info --json=v2 $pkg 2>/dev/null \
                                 | jq -r --arg f "$plat_filter" \
                                     '(.formulae[0].bottle.stable.files // {})
                                      | to_entries[]
                                      | select(.key | test($f))
                                      | .value.url' \
                                 | head -1)

                        # Fallback: try as cask if formula URL is empty
                        if test -z "$url"
                            set cache_path (brew --cache --cask $pkg 2>/dev/null)
                            set url (brew info --json=v2 --cask $pkg 2>/dev/null \
                                     | jq -r '.casks[0].url // empty')
                            set is_cask 1
                        end
                    end

                    # Normalize cache path — strip .aria2/.incomplete suffix
                    set cache_path (string replace -r '\.(aria2|incomplete)$' '' $cache_path)

                    # Skip if already cached or URL unresolvable
                    if test -z "$cache_path" -o -z "$url"
                        continue
                    end
                    # Clean up stale partial downloads
                    rm -f "$cache_path.aria2" "$cache_path.incomplete"
                    if test -e "$cache_path"
                        continue
                    end

                    # Rewrite bottle URL to SJTU mirror
                    if test -n "$HOMEBREW_BOTTLE_DOMAIN"; and test $is_cask -eq 0
                        set url (string replace 'https://ghcr.io/v2/homebrew' "$HOMEBREW_BOTTLE_DOMAIN" $url)
                    end

                    echo ""
                    echo "⬇ Pre-fetching $pkg via aria2..."
                    mkdir -p (dirname $cache_path)
                    aria2c \
                        --max-connection-per-server=16 \
                        --split=16 \
                        --min-split-size=1M \
                        --allow-overwrite=false \
                        --auto-file-renaming=false \
                        --console-log-level=warn \
                        --summary-interval=0 \
                        --download-result=hide \
                        --user-agent='Homebrew/4.0 (Macintosh; Intel Mac OS X) curl/8.7.1' \
                        --dir=(dirname $cache_path) \
                        --out=(basename $cache_path) \
                        $url
                    or echo "⚠ aria2 failed for $pkg — brew will retry with curl"
                end
            end
    end

    # ── Delegate to real brew ────────────────────────────────────
    command brew $argv
    set -l ret $status

    # ── Post-install quarantine removal ─────────────────────────
    if test $ret -eq 0
        switch $argv[1]
            case upgrade
                echo ""
                echo "🔓 Removing quarantine from Applications..."
                set -l count 0
                for app in /Applications/*.app
                    if xattr -l "$app" 2>/dev/null | grep -q "com.apple.quarantine"
                        xattr -rd com.apple.quarantine "$app" 2>/dev/null
                        and set count (math $count + 1)
                    end
                end
                if test $count -gt 0
                    echo "✓ Removed quarantine from $count app(s)"
                else
                    echo "✓ No quarantined apps found"
                end
        end
    end

    return $ret
end
