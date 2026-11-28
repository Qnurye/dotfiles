### Multi-PR delivery

1. Record the requested base, scope and stop point per PR. Assign one owner per PR using the configured worker CLI in a dedicated Worktrunk worktree.
2. Implement and verify each change on its own base. Use the repository's checks and record the command, result and tested SHA. The local decision log holds worktree paths and outstanding dependencies across sessions.
3. For requested delivery, follow the installed `heydeer-pr` workflow. For draft-only work, use the `pr` workflow and stop at the draft. For local work, report the diff and verification from disk.
4. Track checks and unresolved threads with the Babysit playbook. After a fix, verify the new head. Keep owners on independent PRs moving when another PR is blocked.
5. Stop each owner at the agreed milestone. For authorized merges, follow Shipping from the bottom of a stack and confirm the merged SHA on GitHub before releasing the dedicated worktree.
