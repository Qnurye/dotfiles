function _dotfiles_rebase_resolve --description 'Finish a stuck auto-sync rebase when only Otty config conflicts; the work machine wins'
    set -l primary_host heavybowl-ii
    set -l host (scutil --get LocalHostName 2>/dev/null; or hostname -s)

    # During a rebase "ours" is upstream and "theirs" is the local commit being replayed.
    set -l side --ours
    test "$host" = $primary_host; and set side --theirs

    for i in (seq 50)
        test -d (git rev-parse --git-path rebase-merge); or test -d (git rev-parse --git-path rebase-apply)
        or return 0

        set -l conflicts (git diff --name-only --diff-filter=U)
        if test -z "$conflicts"
            git rebase --skip >/dev/null 2>&1
            continue
        end

        for file in $conflicts
            string match -q 'terminals/otty/*' -- $file; or return 1
        end

        git checkout $side -- $conflicts; and git add -- $conflicts; or return 1
        git -c core.editor=true rebase --continue >/dev/null 2>&1
    end
    return 1
end
