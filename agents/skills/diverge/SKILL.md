---
name: diverge
description: Generate multiple independent implementation plans in parallel for a given task, then review and compare them.
argument-hint: <task description>
disable-model-invocation: true
---

# Diverge — Parallel Plan Generation

Generate multiple independent plans for a task, expand each via isolated sub-agents, then review and compare.

## Input

The task description is: `$ARGUMENTS`

If no arguments provided, ask the user for a task description.

## Step 1: Generate Abstract Plans

Analyze the task and generate **as many genuinely distinct approaches as warranted** — no more, no fewer.

### Quality over quantity

- **Every plan must earn its place.** Ask yourself: "Does this approach differ in a way that would actually change implementation decisions?" If not, don't include it.
- **Avoid padding.** Don't create a plan just to fill a slot. Superficial variations (e.g., same architecture with a different library) do not count as distinct plans.
- **Typical range: 2–4 plans.** Fewer is fine if the problem is constrained; more is fine if truly warranted.

### Each plan should:

- Take a distinct architectural or strategic direction
- Be independent — no plan should depend on or reference another
- Be described in 3-5 bullet points (high-level only, no implementation details)
- Have a short descriptive name (e.g., "Event-Driven Architecture", "Monolithic Refactor")
- Have a proposed worktree branch name (e.g., `plan/event-driven`, `plan/monolithic-refactor`) — use `plan/<kebab-case-name>` convention

## Step 2: Set Up Plan Directories

Create the output directory and write each abstract plan:

```
/tmp/plans/<project>/<feat>/
├── plan-1/abstract.md
├── plan-2/abstract.md
└── ...  (as many as generated)
```

Each `abstract.md` must contain ONLY that plan's name, branch name, and bullet points. Do NOT include other plans' details.

## Step 3: Delegate to Sub-Agents

For each plan, create a task for the `plan-writer` agent. Each task should say:

> "Expand the abstract plan at `<absolute-path>/plan-N/abstract.md` into a detailed implementation plan. The original task is: <task description>"

Use **absolute paths** when delegating. Delegate all tasks **in parallel**. Each `plan-writer` sub-agent:

- Only sees its own `abstract.md` (isolated context)
- Writes `detailed-plan.md` in the same directory
- Uses Sonnet model

**Note:** Claude Code routes tasks to `plan-writer` based on its description. Phrase each task to clearly match: expanding an abstract plan into a detailed plan.

## Step 4: Review and Compare

Once all sub-agents have completed, read each `plan-N/detailed-plan.md` and present:

### Comparison Table

Dynamically size the table to the number of plans generated:

|                | Plan 1: [Name] | Plan 2: [Name] | ... |
| -------------- | -------------- | -------------- | --- |
| **Approach**   | 1-line summary | 1-line summary | ... |
| **Pros**       | ...            | ...            | ... |
| **Cons**       | ...            | ...            | ... |
| **Complexity** | low/med/high   | low/med/high   | ... |
| **Risk**       | ...            | ...            | ... |

### Recommendation

Give your recommendation with reasoning.

### Exec Commands

For each plan, output a ready-to-run command using `wtc` (alias for `wt switch --base <current_branch> -x claude --create`):

```bash
# Plan 1: [Name]
wtc plan/<branch> -- "read /tmp/plans/<project>/<feat>/plan-1/detailed-plan.md for instruction"

# Plan 2: [Name]
wtc plan/<branch> -- "read /tmp/plans/<project>/<feat>/plan-2/detailed-plan.md for instruction"

# ...
```

Always use **absolute paths** (e.g., `/tmp/plans/voyager/fix-textbox-stale/plan-1/detailed-plan.md`).

Derive `<project>` from the git repo name (e.g., `voyager`). Derive `<feat>` from the task — use a short kebab-case slug (e.g., `fix-textbox-stale`, `add-auth`).

## Step 5: Save Summary

Write the comparison, recommendation, and exec commands to `/tmp/plans/<project>/<feat>/comparison.md`.

## Notes

- Plans are fully isolated — no cross-contamination between approaches
- All artifacts saved under `/tmp/plans/` (ephemeral, cleared on reboot)
- Branch names follow `plan/<kebab-case>` convention for easy identification with `wt list`
- **Precision matters more than breadth** — fewer high-quality, distinct plans beat many similar ones
