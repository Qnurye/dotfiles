# eza abbreviations — replaces plttn/fish-eza aliases with auto-expanding abbrs.
# Press space after the abbr to see (and edit) the full eza command before it runs.
#
# Bases:
#   l, lg, le, lt, lc, lo, ll
# Suffixes (prepended to base flags):
#   a=--all --binary, d=--only-dirs, i=--icons, id, aa, ad, ai, aid, aad, aai, aaid
# `ll` and its suffixed variants auto-add --git inside a git work tree.

set -l std '--group --header --group-directories-first'

# base | flags appended after $std
set -l bases \
    'l   |' \
    'lg  | --long --git --git-ignore' \
    'le  | --long --extended' \
    'lt  | --tree --level' \
    'lc  | --across' \
    'lo  | --oneline'

# suffix | flags prepended before base flags
set -l suffixes \
    'a    | --all --binary' \
    'd    | --only-dirs' \
    'i    | --icons' \
    'id   | --icons --only-dirs' \
    'aa   | --all --all --binary' \
    'ad   | --all --binary --only-dirs' \
    'ai   | --all --binary --icons' \
    'aid  | --all --binary --icons --only-dirs' \
    'aad  | --all --all --binary --only-dirs' \
    'aai  | --all --all --binary --icons' \
    'aaid | --all --all --binary --icons --only-dirs'

for entry in $bases
    set -l parts (string split -m1 '|' -- $entry)
    set -l name (string trim -- $parts[1])
    set -l flags (string trim -- $parts[2])
    abbr -a $name (string trim -- "eza $std $flags")

    for sentry in $suffixes
        set -l sparts (string split -m1 '|' -- $sentry)
        set -l sname (string trim -- $sparts[1])
        set -l sflags (string trim -- $sparts[2])
        # --tree with --all --all is invalid; skip ltaa*
        string match -q 'ltaa*' "$name$sname"; and continue
        abbr -a "$name$sname" (string trim -- "eza $std $sflags $flags")
    end
end

# ll and ll<suffix>: auto-include --git inside a git work tree.
function __eza_abbr_in_git_repo
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
end

function __eza_abbr_ll
    if __eza_abbr_in_git_repo
        echo 'eza --group --header --group-directories-first --long --git'
    else
        echo 'eza --group --header --group-directories-first --long'
    end
end
abbr -a ll --function __eza_abbr_ll

for sentry in $suffixes
    set -l sparts (string split -m1 '|' -- $sentry)
    set -l sname (string trim -- $sparts[1])
    set -l sflags (string trim -- $sparts[2])
    set -l fname "__eza_abbr_ll$sname"
    set -l with_git (string trim -- "eza $std $sflags --long --git")
    set -l no_git (string trim -- "eza $std $sflags --long")
    eval "function $fname
        if __eza_abbr_in_git_repo
            echo '$with_git'
        else
            echo '$no_git'
        end
    end"
    abbr -a "ll$sname" --function $fname
end
