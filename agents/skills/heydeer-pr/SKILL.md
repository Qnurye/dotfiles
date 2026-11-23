---
name: heydeer-pr
description: Use HeyDeer CLI when the user asks for a code review. Use the full delivery workflow when asked to take a GitHub issue or an ad hoc requirement through a draft PR, HeyDeer review and merge. A review-only request ends with the findings.
---

# HeyDeer PR

For a review request, run the CLI on the requested changes and report its findings. Fix code only if asked. For delivery, follow the stages below. An explicit stopping point such as “draft only” takes precedence.

## Open the draft early

Read the issue and its discussion, or take the requirement directly from the conversation and skip issue creation. Reconcile later clarifications with earlier decisions. Discuss a choice when it materially changes what will ship and the available context cannot settle it.

For delivery, fetch the intended PR base and create a dedicated worktree **before editing**. Run the following command from a checkout that will remain available for cleanup.

```sh
wt switch --create "$branch" --base "$base_ref" --format json
```

Use the fetched ref (e.g. `origin/release`) as `base_ref`. Record the original checkout and the absolute `path` returned by Worktrunk. Set that path as the working directory for edits, tests, commits, pushes and HeyDeer. On resumption reuse the task worktree. For an existing PR use `wt switch "pr:$number" --format json`; an existing user checkout is eligible for cleanup only if it was already dedicated to this delivery.

Once there is a first reviewable commit, push the feature branch and open a draft with `gh pr create --draft --base "$target_branch"`, or reuse its existing PR after checking its base. Capture the intended behavior, acceptance criteria and issue reference when applicable. Finish implementation and run the relevant tests in the task worktree.

## Iterate with the CLI

Run from the scoped worktree. HeyDeer sends the patch and description to its review service. The target GitHub repository needs the HeyDeer App and the user needs write access. On first use, install with `npm install -g heydeer` (Node 22+) and check `heydeer status`. If sign-in is required, the user completes `heydeer login`.

```sh
heydeer review --base "$base_ref" --json "$intent"
```

Set `base_ref` to the fetched target ref, e.g. `origin/release`. Give HeyDeer the agreed behavior, relevant constraints and issue number in `intent`. For a long brief use `--description-file "$brief"` in place of the positional argument. Keep briefs and captured JSON outside the worktree. The CLI sees branch commits and uncommitted tracked changes. Stage intended new files or use `--include-untracked` in an isolated worktree. Use `--dry-run` to inspect included and excluded paths when coverage is unclear.

1. Wait for the CLI to finish. In v0.1.8, a completed review has `status == "succeeded"` and an array at `result.publicationFindings`. Read each finding, the summary, and any open earlier concerns or coverage gaps. Exit code 0 also occurs with findings or a skipped run. Missing fields, `not_started`, failure and cancellation supply no fresh verdict.
2. Check findings against the requirement and code. Fix actionable defects, reproduce or test them, then rerun the CLI against the same target. Keep these rounds local. Pushes, GitHub comments and GitHub polling are unnecessary during this loop.
3. Advance when a completed review covers the candidate patch, reports no new actionable findings, and earlier actionable findings are accounted for. If coverage is incremental and its baseline is unknown, the base or intent changed, or the CLI skips an unchanged diff without a matching completed result, run `--full`. Check material excluded files separately and disclose any remaining gap. For a recurring false positive, retain the concrete counterexample or test. If a real issue remains and another pass cannot progress, keep the draft open and report the blocker.
4. Commit the reviewed changes, push them together, and verify the PR head matches the local commit and its diff matches what was reviewed. Recheck any intervening changes. Mark the draft ready with `gh pr ready "$pr"`.

## Finish on GitHub

Use the repository's HeyDeer PR integration for the final review. Follow the pending check to completion when available. If automatic review is skipped or fails, inspect the reason and use the supported re-run action when permitted. Diagnose an unavailable review separately from a completed decision. A CLI run cannot publish GitHub approval.

Read the current PR head, HeyDeer's latest submitted review (author, commit, state and body), open review threads and required checks. For example, start with `gh pr view "$pr" --json headRefOid,isDraft,reviews,reviewDecision,mergeStateStatus,statusCheckRollup`. Inspect inline threads and additional findings in the review body. If the PR review finds a defect, fix and test locally, run the CLI on the updated patch, push the fix batch and wait for the new head's PR review.

- **HeyDeer approves.** Verify the effective `APPROVED` review came from the repository's HeyDeer App on the current SHA. A green check, another reviewer's approval or an approval on an older SHA is insufficient for this automatic path. Proceed directly to merge once actionable findings and any required smoke test are cleared.
- **A person needs to decide.** When a completed review leaves no actionable defect but withholds approval, read its reason and the diff. Put only the consequential implicit decisions still worth confirming in one section of the PR description, preserving the author's text. For each, give the choice the code currently makes, its user-visible consequence and the specific call the reviewer should make. Omit prescribed behavior, routine implementation details and resolved findings. If there is no such decision, give the actual reason approval is missing. Leave the PR ready and unmerged for the reviewer.
- **A person needs to try it.** If a visual change or critical flow genuinely needs human smoke testing, identify the shortest action and the observable pass condition in the PR. Hold the merge even with bot approval until the result is known.

In the delivery workflow, human approval of the outstanding choices on the reviewed revision and a passing smoke test when required clear the handoff to merge. If the reviewer requests a change, implement it, run both stages of review on the new revision and reconfirm any affected decision.

For both paths, recheck the current head, required checks and branch rules. Use the repository's merge method with `gh pr merge "$pr" --match-head-commit "$sha"`. Respect the active Git guard. If it blocks the merge, give the user the PR link, reviewed SHA and exact merge command. If GitHub requires a queue, follow the entry through to `MERGED` or a concrete blocker.

## Clean up after GitHub merges

Run the bundled [cleanup helper](scripts/cleanup_after_merge.py) from the original checkout using the absolute PR URL and the recorded task worktree path. It checks GitHub, verifies the local branch, commit and worktree status, then runs `wt remove --foreground` on that path. Worktrunk handles local branch removal when it recognizes the branch as integrated.

```sh
python3 "$skill_dir/scripts/cleanup_after_merge.py" "$pr_url" "$task_worktree"
```

If handing the PR off for human review, smoke testing or a guard-required manual merge, start the same helper **once** with `--wait` before returning. Use a background job that survives the handoff, e.g. `nohup python3 "$skill_dir/scripts/cleanup_after_merge.py" --wait "$pr_url" "$task_worktree" >"$cleanup_log" 2>&1 </dev/null &`. Use an absolute per-PR log outside the task worktree. The watcher follows only this PR and exits if it closes unmerged. On resumption check the job or its log before starting another. Leave an open PR's worktree available for fixes.

Report the PR URL and merge commit on success, and whether the worktree was removed or retained and why. At a human handoff, report the pending decision or test and the cleanup log.
