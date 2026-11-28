### Babysit a GitHub PR

Use `scripts/watch-pr/watch-pr --status-only` for a snapshot. For requested monitoring, run the watcher from the scoped checkout. Read conflicts, unresolved threads, review decision and checks at the current head. Review comments from every author using [review triage](../references/review-triage.md).

For status-only or review-only work, report findings. When fixes are in scope, verify each claim against the code, fix confirmed issues, run the relevant checks and recheck the new head. Reply to threads when included in the request. Use `gh` with a body file for multiline replies. Stop at the requested milestone.
