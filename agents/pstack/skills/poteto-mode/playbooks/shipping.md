### Shipping

1. Confirm the requested PRs, target branches, permitted merge method and stop point. Read their current heads, bases, reviews and required checks with `gh`.
2. Verify each patch on the actual app or CLI from its Worktrunk worktree. Record the tested SHA and results. Use the installed `heydeer-pr` workflow for HeyDeer delivery.
3. Land an authorized stack bottom-up. Re-read the current head and base before merging. Pass the verified head to `gh pr merge --match-head-commit` and honor repository merge rules. Pause at the first unverified dependency.
4. Confirm the PR's merged state, base and merge commit with `gh pr view`. For queued merges, wait for the actual result. Retarget dependent branches to the intended base and verify the resulting heads and CI before proceeding.
5. For completed deliveries, use the local workflow's cleanup step on the matching worktree. Report the landed commits and remaining PRs.
