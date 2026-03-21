function wtc --description 'Create worktree with Claude'
    wt switch --base (git branch --show-current) -x claude --create $argv[1] -- --permission-mode acceptEdits $argv[2..]
end
