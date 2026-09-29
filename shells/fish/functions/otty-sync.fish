function otty-sync --description 'Two-way sync Otty config with ~/dotfiles; the work machine wins conflicts'
    argparse q/quiet -- $argv; or return 1

    # Otty's settings GUI rewrites config.toml in place, replacing any symlink,
    # so the file is synced by content instead of linked.
    set -l primary_host heavybowl-ii
    set -l live $HOME/.config/otty/config.toml
    set -l repo $HOME/dotfiles/terminals/otty/config.toml
    set -l state_dir $HOME/.local/state/otty-sync
    set -l base_file $state_dir/config.toml.sha256

    set -l host (scutil --get LocalHostName 2>/dev/null; or hostname -s)

    function __otty_sync_hash -a file
        test -f $file; and /usr/bin/shasum -a 256 $file | string split -f1 ' '
    end

    if test -L $live
        set -l target (readlink -f $live)
        rm -f $live
        test -f "$target"; and cp $target $live
    end

    set -l h_live (__otty_sync_hash $live)
    set -l h_repo (__otty_sync_hash $repo)
    set -l h_base
    test -f $base_file; and set h_base (cat $base_file)

    set -l direction
    if test -z "$h_live" -a -z "$h_repo"
        return 0
    else if test "$h_live" = "$h_repo"
        set direction none
    else if test -z "$h_repo"
        set direction push
    else if test -z "$h_live"
        set direction pull
    else if test "$h_repo" = "$h_base"
        set direction push
    else if test "$h_live" = "$h_base"
        set direction pull
    else if test "$host" = $primary_host
        set direction push
    else
        set direction pull
    end

    mkdir -p $state_dir (dirname $live) (dirname $repo)

    switch $direction
        case push
            cp $live $repo
            set h_repo $h_live
            set -q _flag_quiet; or echo "otty-sync: local config → dotfiles"
        case pull
            if test -n "$h_live" -a "$h_live" != "$h_base"
                cp $live $state_dir/config.toml.(date +%Y%m%d%H%M%S).bak
            end
            cp $repo $live
            set -q _flag_quiet; or echo "otty-sync: dotfiles → local config"
    end

    echo $h_repo > $base_file
    functions -e __otty_sync_hash
end
