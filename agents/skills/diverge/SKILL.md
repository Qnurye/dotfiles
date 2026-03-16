---
name: diverge
description: Generate multiple independent implementation plans in parallel for a given task, then review and compare them.
argument-hint: <task description>
disable-model-invocation: true
---

# Diverge — Parallel Plan Generation

Generate multiple independent plans for a task, expand each via isolated team agents, then review and compare.

## Input

The task description is: `$ARGUMENTS`

If no arguments provided, ask the user for a task description.

## Planning Lenses

Each plan is assigned a lens that constrains its architectural direction. Available lenses:

- **Simplicity-first** — Minimize moving parts. Prefer fewer files, less abstraction, direct solutions.
- **Performance-first** — Optimize for speed/efficiency. Accept more complexity if it measurably improves performance.
- **Extensibility-first** — Design for future change. Prefer abstractions, interfaces, plugin points.
- **Minimal-change** — Smallest possible diff. Reuse existing patterns, avoid refactoring.

Choose lenses that create **maximum tension** for the specific task. For a bug fix, "minimal-change" vs "simplicity-first" creates useful tension. For a new feature, "extensibility-first" vs "performance-first" is often more informative.

## Step 0: Context Grounding

### Step 0a: Gather Mechanical Context

Run the following command and capture its output as `<mechanical_context>`:

```bash
bash ~/.claude/skills/diverge/gather-context.sh
```

This script validates prerequisites (agent teams flag, git availability) and outputs: project name, branch, repo root, tech stack, directory structure, and CLAUDE.md contents. **If it exits non-zero, stop and report the error to the user.**

### Step 0b: Identify Key Files and Finalize Bundle

1. Review `<mechanical_context>` to understand the project structure and tech stack.
2. Using the task description, identify **3-5 files most relevant** to the task. Use Grep/Glob to locate candidates, then read them with the Read tool. If a file exceeds 300 lines, read only the first 100 lines and note the truncation.
3. Synthesize a **Constraints** summary from the CLAUDE.md content in `<mechanical_context>` — extract only what is relevant to this specific task.
4. Assemble the final **context bundle** by combining `<mechanical_context>` with the key files:

```markdown
<mechanical_context output>

- **Constraints:** <task-relevant summary from CLAUDE.md or "none found">

### Key Files
<file_path_1>
```<language>
<file contents (or first 100 lines if truncated)>
```
... (repeat for each key file)
```

Hold the assembled context bundle in memory — it will be injected into every team-agent prompt in Step 3.

## Step 1: Generate Abstract Plans

### Step 1a: Initial Generation

Generate exactly **2 plans**, each assigned a distinct lens from the pool. Pick lenses that create the most tension for this task.

Each plan should:
- Take a distinct architectural or strategic direction
- Be independent — no plan should depend on or reference another
- Be described in 3-5 bullet points (high-level only, no implementation details)
- Have a short descriptive name (e.g., "Event-Driven Architecture", "Monolithic Refactor")
- Have a proposed worktree branch name using `plan/<kebab-case-name>` convention
- Include a `**Lens:** <name>` field

### Step 1b: Diversity Check

Evaluate the 2 plans against this checklist:

| Question | yes=2 | partially=1 | no=0 |
|----------|-------|-------------|------|
| Do they modify the same set of files? | | | |
| Do they use the same architectural pattern? | | | |
| Would implementing Plan A produce code that looks similar to Plan B? | | | |

Sum the scores:
- **0–2:** Plans are sufficiently diverse. Proceed to Step 2.
- **3–4:** Moderate overlap. Generate **1 more** plan with an unused lens.
- **5–6:** Too similar. Generate **2 more** plans with unused lenses.

### Step 1c: Additional Plans (conditional)

If triggered by Step 1b, generate additional plans with the constraint: "This plan MUST differ from existing plans in at least one of: (a) which files it modifies, (b) the architectural pattern it uses, (c) the sequencing of implementation steps." Assign unused lenses.

### Quality Rules

- **Every plan must earn its place.** If an approach doesn't change implementation decisions, don't include it.
- **Avoid padding.** Superficial variations (e.g., same architecture with a different library) do not count as distinct.
- **Total plans: 2–4.** The adaptive check ensures this range naturally.

## Step 2: Set Up Plan Directories

Create the output directory and write each abstract plan:

```
/tmp/plans/<project>/<feat>/
├── plan-1/abstract.md
├── plan-2/abstract.md
└── ...  (as many as generated)
```

Each `abstract.md` must contain ONLY that plan's name, lens, branch name, and bullet points. Do NOT include other plans' details.

## Step 3: Delegate to Team Agents

For each plan, invoke the `Agent` tool as a **named team agent**. Fire all agents **in a single parallel batch**.

### Prompt Template

Each team agent receives a single prompt string constructed by concatenating:

```
You are a focused planning agent.

## Planning Lens: <lens_name>
<lens_description>
Your detailed plan MUST reflect this lens. When making design decisions,
consistently favor this lens's priorities. Explicitly call out where this
lens influenced your choices.

<context_bundle>

Your task:
Expand the abstract plan at `<absolute_path>/plan-N/abstract.md` into a detailed implementation plan.

The original task is: <task_description>

## Rules
- Do NOT reference or speculate about alternative approaches.
- Be specific: include file paths, function names, data structures, step-by-step instructions.
- Include potential edge cases and how to handle them.
- Estimate relative complexity per step (low/medium/high).
- The plan should be detailed enough for a coding agent to execute without ambiguity.

## Output Format
Write `detailed-plan.md` in the SAME directory as the abstract plan (`<absolute_path>/plan-N/`), using this structure:

# [Plan Name]

## Overview
One paragraph summary of the approach.

## Steps

### 1. [Step Title]
- **Complexity:** low/medium/high
- **Details:** ...
- **Files:** ...
- **Edge cases:** ...

## Dependencies
External libraries or services needed.

## Risks
What could go wrong and mitigations.
```

Where `<context_bundle>` is the full context bundle assembled in Step 0, injected verbatim.

### Invocation

Call the `Agent` tool once per plan, **all in the same message** (parallel batch), with:
- `name`: `"plan-writer-N"` (e.g., `"plan-writer-1"`, `"plan-writer-2"`)
- `prompt`: the assembled prompt string above
- `subagent_type`: `"plan-writer"`

### Isolation

Each agent only sees its own `abstract.md` path and the shared context bundle. Agents must not reference each other's paths or plans.

### Completion

Wait for **all** team agents to finish before proceeding to Step 4. If an agent fails to write `detailed-plan.md`, note the missing file during Step 4 review and flag it rather than failing.

## Step 4: Review and Compare

Once all team agents have completed, read each `plan-N/detailed-plan.md` and present:

### Comparison Table

Dynamically size the table to the number of plans generated:

|                | Plan 1: [Name] | Plan 2: [Name] | ... |
| -------------- | -------------- | -------------- | --- |
| **Lens**       | lens name      | lens name      | ... |
| **Approach**   | 1-line summary | 1-line summary | ... |
| **Pros**       | ...            | ...            | ... |
| **Cons**       | ...            | ...            | ... |
| **Complexity** | low/med/high   | low/med/high   | ... |
| **Risk**       | ...            | ...            | ... |

### Recommendation

Give your recommendation with reasoning.

### Evaluation Enhancement (optional)

Ask the user which evaluation mode they prefer:

1. **Quick score** — Structured criteria-based scoring (fast, no extra agents)
2. **Deep debate** — Adversarial advocate/critic agents per plan (thorough, spawns 2N agents)
3. **Skip** — Proceed with the comparison as-is

Default to **Skip** if the user does not choose.

#### Option 1: Quick Score

Score each plan on a 1–5 scale for:
- **Feasibility:** Can this be implemented with the current codebase and constraints?
- **Completeness:** Does the plan cover edge cases and error handling?
- **Clarity:** Could a coding agent execute this without asking questions?
- **Risk:** How well are risks identified and mitigated? (5 = low risk)

Append scores to the comparison table. Flag any plan with average below 3.0 and note its key weakness.

#### Option 2: Deep Debate

For each plan, spawn **2 team agents** in a single parallel batch:

- **Advocate** (`advocate-N`): Read the detailed plan. Write a 3-5 paragraph argument for why this plan is the best choice. Focus on strengths, alignment with constraints, implementation elegance. Write to `<path>/advocate.md`.
- **Critic** (`critic-N`): Read the detailed plan. Write a 3-5 paragraph critique identifying weaknesses, risks, hidden costs, and fragile assumptions. Be specific — reference concrete steps. Write to `<path>/critique.md`.

After all agents complete, read all `advocate.md` and `critique.md` files. Synthesize a **Debate Summary** per plan:
- **Strongest argument for:** (1-2 sentences)
- **Most concerning weakness:** (1-2 sentences)
- **Net assessment:** (your judgment weighing both sides)

**Note:** Deep debate spawns 2 agents per plan. For 4 plans, that means 8 parallel agents. Choose this only for high-stakes architectural decisions.

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

Write the comparison, recommendation, evaluation results (if any), and exec commands to `/tmp/plans/<project>/<feat>/comparison.md`.

## Notes

- Plans are fully isolated — no cross-contamination between approaches
- All artifacts saved under `/tmp/plans/` (ephemeral, cleared on reboot)
- Branch names follow `plan/<kebab-case>` convention for easy identification with `wt list`
- **Precision matters more than breadth** — fewer high-quality, distinct plans beat many similar ones
- Planning lenses ensure structural diversity by forcing different architectural priorities per plan
- `gather-context.sh` handles mechanical context gathering; LLM handles task-specific judgment (key file selection, constraint synthesis)
- Context bundle from Step 0 is passed verbatim to every team agent — this is the sole mechanism ensuring grounded, project-aware plan generation
- Evaluation enhancement (quick score / deep debate) is optional and user-selected — default is skip
- Prerequisites (agent teams flag, git) are validated by `gather-context.sh` at the start — the skill fails fast if anything is missing
