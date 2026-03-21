# Dotfiles auto-sync (every 2 hours)
# Runs on shell startup via conf.d

function _dotfiles_conflict_check
    set -l conflict_marker "$HOME/dotfiles/.sync_conflict"
    test -f "$conflict_marker"; or return

    echo (set_color yellow)"[dotfiles]"(set_color normal)" Sync conflict detected — local and remote dotfiles have diverged."
    echo "  cd ~/dotfiles && git rebase origin/main"
end

function _dotfiles_auto_sync
    set -l DOTFILES_DIR "$HOME/dotfiles"
    set -l SYNC_MARKER "$DOTFILES_DIR/.last_sync"
    set -l SYNC_INTERVAL 7200 # 2 hours

    test -d "$DOTFILES_DIR/.git"; or return

    set -l now (date +%s)
    set -l last_sync 0
    test -f "$SYNC_MARKER"; and set last_sync (cat "$SYNC_MARKER")
    test (math $now - $last_sync) -lt $SYNC_INTERVAL; and return

    set -l git "git -C $DOTFILES_DIR"

    # Fetch remote quietly in background
    set -l fetch_marker "$DOTFILES_DIR/.last_fetch"
    if not test -f "$fetch_marker"
        fish -c "eval $git fetch --quiet 2>/dev/null; and echo $now > $fetch_marker" &
        disown
        return
    end

    # Determine local and remote state
    set -l has_local false
    set -l has_remote false

    if not eval $git diff --quiet 2>/dev/null; or not eval $git diff --cached --quiet 2>/dev/null; or test -n (eval $git ls-files --others --exclude-standard 2>/dev/null)
        set has_local true
    end

    set -l local_head (eval $git rev-parse HEAD 2>/dev/null)
    set -l remote_head (eval $git rev-parse '@{u}' 2>/dev/null)
    set -l merge_base (eval $git merge-base HEAD '@{u}' 2>/dev/null)
    if test "$local_head" != "$remote_head" -a "$remote_head" != "$merge_base"
        set has_remote true
    end

    rm -f "$fetch_marker"

    # Case 1: Nothing to do
    if test "$has_local" = false -a "$has_remote" = false
        echo $now > "$SYNC_MARKER"
        return
    end

    # Case 2: Only remote changes
    if test "$has_local" = false -a "$has_remote" = true
        fish -c "cd $DOTFILES_DIR; and git pull --rebase --quiet 2>/dev/null; and echo $now > $SYNC_MARKER" &
        disown
        return
    end

    # Case 3: Only local changes
    if test "$has_local" = true -a "$has_remote" = false
        fish -c "cd $DOTFILES_DIR; and git add -A; and git commit -m 'chore: auto sync dotfiles' --quiet 2>/dev/null; and git push --quiet 2>/dev/null; and echo $now > $SYNC_MARKER" &
        disown
        return
    end

    # Case 4: Both have changes
    fish -c "
        cd $DOTFILES_DIR
        git add -A
        git commit -m 'chore: auto sync dotfiles' --quiet 2>/dev/null
        if git rebase --quiet '@{u}' 2>/dev/null
            git push --quiet 2>/dev/null
            echo $now > $SYNC_MARKER
        else
            git rebase --abort 2>/dev/null
            echo conflict > $DOTFILES_DIR/.sync_conflict
        end
    " &
    disown
end

_dotfiles_conflict_check
_dotfiles_auto_sync
