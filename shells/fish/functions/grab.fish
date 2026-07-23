function grab --description 'Capture tmux pane scrollback to a log file'
    if not set -q TMUX
        echo "grab: not inside a tmux session"
        return 1
    end

    set -l dir_name (string replace -a '/' '-' (string trim -l -c '/' $PWD))
    test -z "$dir_name"; and set dir_name "root"
    set -l timestamp (date +%Y%m%d-%H%M%S)
    set -l log_dir /tmp/logs
    set -l log_file "$log_dir/$dir_name-$timestamp.log"

    mkdir -p $log_dir
tmux capture-pane -pS - > $log_file

    echo $log_file
end
