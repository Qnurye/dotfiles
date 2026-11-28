### Opening a PR

Use when the task includes opening a PR. For a GitHub PR, follow the installed `pr` skill. For a requested HeyDeer review or delivery, follow `heydeer-pr` and its stopping point.

Work from a git worktree off trunk, and keep unrelated work out of it. Rebase into small, landable commits. Review the local diff before committing with Worktrunk.

Title: `type(scope): subject`, naming a real symbol when one carries the change. Body: a one-minute briefing under 40 lines with these `##` headings in order, dropping empty ones: `## Why`, `## What changed`, `## Scope`, `## Tradeoffs` (only rejected alternatives a reviewer would otherwise ask about), `## Blast Radius`, `## Verification`.

Stack follow-ups by base branch. Use the requested draft or ready state. Follow the local PR workflow for the default.
