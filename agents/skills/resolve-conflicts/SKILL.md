---
name: resolve-conflicts
description: Resolve git merge, rebase, and cherry-pick conflicts. Use when git status shows unmerged paths, conflict markers, or user asks to fix conflicts after a failed merge/rebase/cherry-pick.
---

# Git Conflict Resolution

You are resolving git conflicts. Follow these steps carefully.

## Step 1: Assess situation

- Run `git status` to identify conflicted files and staged files.
- Determine the operation type by checking:
  - `.git/rebase-merge/` or `.git/rebase-apply/` exists → **rebase** (`git rev-parse REBASE_HEAD` for the replayed commit, `msgnum`/`end` for progress)
  - `.git/MERGE_HEAD` exists → **merge** (read it for the incoming commit hash)
  - `.git/CHERRY_PICK_HEAD` exists → **cherry-pick** (read it for the picked commit hash)

## Step 2: Understand both sides

- Run `git show <incoming-commit> --stat` and `git show <incoming-commit>` to understand the incoming commit's intent.
- For each conflicted file:
  1. **Read both versions** of the file: `git show :2:<file>` (ours) and `git show :3:<file>` (theirs).
  2. **Trace the history** from the merge base to understand what each side changed and why:
     - `git log <merge-base>..<incoming-ref> --oneline -5 -- <file>` for incoming side's changes.
     - `git log <merge-base>..HEAD --oneline -5 -- <file>` for current side's changes.
     - `git show <hash>` for every commit.

When changes are architectural, also read non-conflicted files that the conflicted code depends on to understand the surrounding architecture.

## Step 3: Design resolution strategy

Determine for each conflicted file:

- **Which architecture wins**: If one side refactored the structure, the architecture from that side should be the foundation.
- **Which content wins**: New features, bug fixes, and additions from the other side should be adapted to fit the winning architecture.
- **What needs adaptation**: Content from one side may need type changes, import updates, or API adjustments to work with the other side's architecture.

## Step 4: Resolve and verify

- Resolve files in **dependency order** (types → implementations → consumers).
- For deleted files, use `git rm <file>` to stage the deletion.
- Verify references for old type names that were renamed or removed.
- Verify import paths after file moves or renames.
- Run `git status` to confirm no unmerged paths remain.
- Run `pnpm tsc:check` to verify no type errors remain.
- Present a summary of resolutions and any concerns the user should verify.

## Resolution principles

- **Architecture over content**: When one side restructured code and the other added features, keep the structure and adapt the features.
- **Preserve semantics**: When both sides changed the same logic differently, understand _why_ each change was made before choosing.
- **Minimal blast radius**: Don't refactor unrelated code, only change what's necessary to resolve conflicts.

## Important notes

- Do **NOT** run `git add`, `git merge --continue`, `git rebase --continue`, or `git cherry-pick --continue`.
- If a conflict is too ambiguous, explain both options and ask the user.
- For binary files, ask the user which version to keep.
- If resolved code has errors unrelated to the conflict, mention them but don't fix unless asked.
