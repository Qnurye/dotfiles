### Worktree cleanup

1. Inventory exact paths with `git worktree list --porcelain` and `scripts/worktree-audit.sh -b <base> <repo>`. Record the requested inclusions and exclusions. Inspect tracked, untracked and ignored files for data the user may want.
2. Check processes and open files using the candidate, local session activity, branch ownership, and current GitHub PR state where relevant. An unavailable activity or PR check leaves usage unverified. Give each candidate a verdict and the reason.
3. For approved idle worktrees use Worktrunk from a surviving checkout. Use `wt remove --no-delete-branch <branch>` when cleanup covers the worktree alone. Recheck the worktree list, retained branches, and reclaimed space. Treat simulator, cache and branch deletion as separate requests.
