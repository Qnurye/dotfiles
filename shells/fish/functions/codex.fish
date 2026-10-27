function codex --wraps codex --description 'Run Codex without sandboxing or approval prompts'
    command codex \
        --config 'approval_policy="never"' \
        --config 'sandbox_mode="danger-full-access"' \
        $argv
end
