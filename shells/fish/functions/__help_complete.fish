# Completes subcommands and options for CLIs that ship no completion script, by
# parsing `<cmd> <subcommand chain> --help`. Only tokens already listed as
# subcommands by a parent help page are ever executed, so arbitrary arguments
# (a prompt, a path) never reach the command.
function __help_complete --description 'Complete subcommands and options parsed from --help output'
    set -l tokens (commandline -xpc)
    set -l current (commandline -ct)

    set -l cmd $tokens[1]
    set -l chain
    for token in $tokens[2..]
        string match -q -- '-*' $token; and continue
        contains -- $token (__help_complete_parse $cmd $chain | string replace -r '\t.*' ''); or break
        set -a chain $token
    end

    if string match -q -- '-*' $current
        __help_complete_parse $cmd $chain | string match -- '-*'
    else
        __help_complete_parse $cmd $chain | string match -v -- '-*'
    end
end

function __help_complete_parse
    set -l key __help_complete_cache_(string escape --style=var -- "$argv")
    if not set -q $key
        set -g $key (command $argv --help 2>&1 </dev/null | __help_complete_extract)
    end
    printf '%s\n' $$key
end

function __help_complete_extract
    set -l in_commands 0
    while read -l line
        if string match -rq '^\S.*:$|^[A-Z][A-Z ]+$' -- $line
            set in_commands 1
            string match -rqi 'option|flag|argument|example|note|usage' -- $line; and set in_commands 0
        else if string match -rq '^\s+-' -- $line
            set -l parts (string match -rg '^\s+(-\S.*?)(?: {2,}(\S.*))?$' -- $line)
            for flag in (string match -rag '(?:^|[\s,|])(--?[A-Za-z][\w-]*)' -- $parts[1])
                echo $flag\t$parts[2]
            end
        else if test $in_commands -eq 1
            set -l parts (string match -rg '^ {2}([a-z][\w:-]*(?:\|[\w:-]+)*)(?: \S.*?)?(?: {2,}(\S.*))?$' -- $line)
            or continue
            for name in (string split '|' -- $parts[1])
                echo $name\t$parts[2]
            end
        end
    end
end
