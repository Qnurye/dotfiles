# pnpm's own completion never offers bare `pnpm <script>`, lists every flag
# before a `-` is typed, labels each candidate "pnpm" and leaves --filter
# values empty. Keep its completion server for subcommands and flags and add
# the project-aware parts on top.
__fish_cache_sourced_completions pnpm completion fish 2>/dev/null
or pnpm completion fish 2>/dev/null | source
complete -c pnpm -e

function __pnpm_scripts -a manifest
    test -f "$manifest"
    and jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' $manifest 2>/dev/null
end

function __pnpm_workspace_packages --description 'Print name<TAB>manifest for each workspace package'
    set -l root $PWD
    while not test -f $root/pnpm-workspace.yaml
        test $root = /; and return
        set root (path dirname $root)
    end
    fd -t f -d 4 '^package\.json$' $root -X jq -r '"\(.name // empty)\t\(input_filename)"' 2>/dev/null
end

function __pnpm_complete
    set -l current (commandline -ct)
    set -l positional
    set -l filter
    set -l pending
    for token in (commandline -xpc)[2..]
        if test -n "$pending"
            test $pending = filter; and set filter $token
            set pending
            continue
        end
        switch $token
            case -F --filter
                set pending filter
            case -C --dir
                set pending dir
            case '--filter=*'
                set filter (string replace -- '--filter=' '' $token)
            case '-*'
            case '*'
                set -a positional $token
        end
    end

    if test "$pending" = filter
        __pnpm_workspace_packages | string replace -r '\t.*/([^/]+)/package\.json$' '\t$1'
        return
    end

    if string match -q -- '-*' $current
        _pnpm_completion
        return
    end

    set -l scripts
    if not set -q positional[2]
        set -l manifest package.json
        if test -n "$filter"
            set manifest (__pnpm_workspace_packages | string match -rg '^'(string escape --style=regex -- $filter)'\t(.*)')[1]
        end
        if not set -q positional[1]
            set scripts (__pnpm_scripts $manifest)
            set -q scripts[1]; and printf '%s\n' $scripts
        else if contains -- $positional[1] run run-script
            __pnpm_scripts $manifest
            return
        end
    end

    if test "$positional" = exec
        set -l bins node_modules/.bin/*
        path basename $bins
    end

    # The subcommand list is static, so skip the ~200ms node start after the first Tab.
    set -l candidates
    if set -q positional[1]
        set candidates (_pnpm_completion)
    else
        set -q __pnpm_commands; or set -g __pnpm_commands (_pnpm_completion)
        set candidates $__pnpm_commands
    end
    set -l script_names (string replace -r '\t.*' '' -- $scripts)
    for candidate in (string match -v -- '-*' $candidates)
        contains -- $candidate $script_names; or echo $candidate
    end
end

complete -c pnpm -f -a '(__pnpm_complete)'
