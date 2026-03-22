function brew --description 'Brew wrapper with auto quarantine removal'
    command brew $argv
    set -l ret $status
    if test $ret -eq 0
        switch $argv[1]
            case upgrade
                echo ""
                echo "🔓 Removing quarantine from Applications..."
                set -l count 0
                for app in /Applications/*.app
                    if xattr -l "$app" 2>/dev/null | grep -q "com.apple.quarantine"
                        xattr -rd com.apple.quarantine "$app" 2>/dev/null; and set count (math $count + 1)
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
