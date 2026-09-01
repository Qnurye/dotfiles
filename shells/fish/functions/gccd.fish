function gccd --description 'git clone a repository and cd into it'
    if test (count $argv) -eq 0
        echo "gccd: usage: gccd <repository> [directory] [git clone options...]" >&2
        return 1
    end

    # git clone flags that consume the following argument
    set -l value_flags -b --branch -o --origin -u --upload-pack -c --config \
        --depth --reference --reference-if-able --separate-git-dir --template \
        --filter --shallow-since --shallow-exclude -j --jobs --bundle-uri --server-option

    set -l positional
    set -l skip false
    for arg in $argv
        if $skip
            set skip false
        else if contains -- $arg $value_flags
            set skip true
        else if not string match -q -- '-*' $arg
            set -a positional $arg
        end
    end

    if test (count $positional) -eq 0
        echo "gccd: no repository given" >&2
        return 1
    end

    set -l target $positional[2]
    if test -z "$target"
        set target (string replace -r '/+$' '' -- $positional[1] \
            | string replace -r '\.git$' '' \
            | string replace -r '^.*[/:]' '')
    end

    git clone --recurse-submodules $argv; or return $status

    if not test -d "$target"
        echo "gccd: cloned, but could not locate directory '$target'" >&2
        return 1
    end

    cd -- "$target"
end
