function nix-add --description 'Search and install nix packages or homebrew casks'
    set -l flake_dir ~/dotfiles/nix
    set -l tags_file $flake_dir/tags.nix

    if test (count $argv) -lt 1
        echo "Usage: nix-add <query>"
        echo "  Searches nixpkgs and homebrew casks, then adds to tags.nix"
        return 1
    end

    set -l query $argv[1]

    # Search both sources in parallel
    echo "Searching nixpkgs..."
    set -l nix_results (nix search nixpkgs $query 2>/dev/null | string match -r '^\* .*' | head -10)

    echo "Searching homebrew casks..."
    set -l cask_results (brew search --casks $query 2>/dev/null | head -10)

    # Display results
    set -l options
    set -l types
    set -l names

    if test (count $nix_results) -gt 0
        echo ""
        echo "── nixpkgs ──"
        set -l idx 1
        for line in $nix_results
            # Extract package name: "* legacyPackages.*.pkgname (version)"
            set -l pkg (echo $line | string replace -r '^\* legacyPackages\.\S+\.(\S+)\s.*' '$1')
            set -l desc (echo $line | string replace -r '^\* \S+\s+\(.*?\)\s*' '')
            printf "  [%d] %s%s\n" $idx $pkg (test -n "$desc"; and echo " — $desc"; or echo "")
            set -a options "nix:$pkg"
            set -a types nix
            set -a names $pkg
            set idx (math $idx + 1)
        end
    end

    if test (count $cask_results) -gt 0
        set -l idx (math (count $options) + 1)
        echo ""
        echo "── homebrew casks ──"
        for cask in $cask_results
            printf "  [%d] %s\n" $idx $cask
            set -a options "cask:$cask"
            set -a types cask
            set -a names $cask
            set idx (math $idx + 1)
        end
    end

    if test (count $options) -eq 0
        echo "No results found for '$query'"
        return 1
    end

    echo ""
    read -P "Select package number (or 'q' to quit): " choice

    if test "$choice" = q; or test -z "$choice"
        return 0
    end

    if not string match -qr '^\d+$' $choice; or test $choice -lt 1; or test $choice -gt (count $options)
        echo "Invalid selection"
        return 1
    end

    set -l selected_type $types[$choice]
    set -l selected_name $names[$choice]

    # Pick target tag
    echo ""
    set -l tags (string match -r '"[^"]+"\s*=' < $tags_file | string replace -r '\s*=.*' '' | string trim -c '"')
    echo "Available tags:"
    set -l tidx 1
    for tag in $tags
        printf "  [%d] %s\n" $tidx $tag
        set tidx (math $tidx + 1)
    end

    echo ""
    read -P "Select tag number: " tag_choice

    if not string match -qr '^\d+$' $tag_choice; or test $tag_choice -lt 1; or test $tag_choice -gt (count $tags)
        echo "Invalid selection"
        return 1
    end

    set -l target_tag $tags[$tag_choice]

    # Add to tags.nix
    if test $selected_type = nix
        # Add to packages list of the selected tag
        sed -i '' "/$target_tag.*=/,/};/ s/packages = \[/packages = [ $selected_name/" $tags_file
        echo "Added '$selected_name' to packages in '$target_tag'"
    else
        # Add to casks list of the selected tag
        sed -i '' "/$target_tag.*=/,/};/ s/casks = \[/casks = [ \"$selected_name\"/" $tags_file
        echo "Added '$selected_name' to casks in '$target_tag'"
    end

    echo ""
    read -P "Rebuild now? [y/N] " rebuild
    if test "$rebuild" = y; or test "$rebuild" = Y
        sudo darwin-rebuild switch --flake $flake_dir
    end
end
