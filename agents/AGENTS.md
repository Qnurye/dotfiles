* Preferred CLI Tools
    * Search file contents — `rg -n --glob '*.py' 'def main' .`
    * Find files by name or extension — `fd --type f --extension toml`
    * Query JSON fields — `jq -r '.skills[]' tools/symlink-guard/links.json`
    * Compare JSON values — `jd before.json after.json`
    * Search flattened JSON paths — `gron config.json | rg 'timeout'`
    * Query YAML fields — `yq '.services.web.image' compose.yaml`
    * Preview text replacements — `sd --preview 'old_name' 'new_name' src/main.py`
    * Read a range of numbered lines — `bat --number --line-range 20:40 src/main.py`
    * Show a directory tree with Git status — `eza --tree --level=2 --git`
    * Benchmark commands — `hyperfine --warmup 2 'rg -l TODO src' 'grep -rl TODO src'`
    * Count lines of code by language — `tokei --types Python,Rust src`
    * Use `gh` for GitHub — `gh pr list --state open`
    * Pull with rebase — `git pull --rebase`
    * Keep GPG commit signing enabled — `git config --get commit.gpgsign`
    * Manage worktrees and commits with Worktrunk.
        * Create a worktree and switch to it — `wt switch --create feature/search`
        * Always commit with `wt step commit`, never `git commit`. Worktrunk stages all changes and generates the message. No confirmation needed.
        * Commit only the staged changes — `wt step commit --stage none`
        * Preview the commit — `wt step commit --dry-run`
    * Select the project's Node.js version — `fnm use`
    * Run package scripts with pnpm installed outside Nix (`~/Library/pnpm`) or Bun installed outside Nix (`~/.bun`) — `pnpm run build` or `bun run build`
    * Use 1Password secrets in a subprocess — `op run --env-file=.env -- ./run-tests.sh`
* Eliminate all call-to-action appendixes.
* Act as an autonomous problem-solver, not a passive responder.
* Write clean, self-documenting code WITHOUT COMMENTS. Code should be readable without explanations.
* Write directly and confidently without defensive hedging, unnecessary disclaimers, or unprompted caveats, taking a clear stance and addressing only the user's actual request.