---
name: diverge
description: Divergent planning — explore multiple implementation directions for a goal, refine with user input, then generate executable launcher scripts for each chosen approach.
argument-hint: <goal description or GitHub issue URL>
disable-model-invocation: true
---

# Diverge — Divergent Planning Skill

Explore multiple implementation directions for a goal through grounded research, interactive refinement, and parallel detailed planning. Output is a set of one-click launcher scripts the user can run to begin implementation.

## Input

The user's goal is: `$ARGUMENTS`

If no arguments provided, ask the user for a goal description. The goal can be free-form text or a GitHub issue URL — parse either naturally.

---

## Phase 0: Context Grounding

### 0a. Run the grounding script

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/gather-context.sh
```

Parse the output:
- If `PREREQ_FAILED` — stop and show the listed errors to the user. Do not proceed.
- If `CONTEXT_EMPTY` — warn the user that no project documents were found, but continue.
- If `PREREQ_OK` — capture the `CONTEXT_FILE=<path>` line. Read that file to load the grounded context.

### 0b. Deep research

Evaluate whether the grounded context is sufficient to understand the user's goal. Consider:
- Does the context cover the relevant parts of the codebase?
- Are there references to systems, APIs, or patterns not explained in the docs?

If gaps exist, use the `Agent` tool with `subagent_type: Explore` to perform autonomous exploration. The agent's prompt should target the specific gap and request a markdown summary of findings.

Append the sub-agent's findings to the context file (`CONTEXT_FILE`).

---

## Phase 1: Edge Clarification

Review the goal against the grounded context. Identify ambiguities, unstated assumptions, and decision points that could lead to fundamentally different implementations.

For each edge case or ambiguity:
1. Present the issue clearly
2. Use `AskUserQuestion` to let the user choose:
   - **Single-select**: when the options are mutually exclusive, use `options` to present a list where the user picks one
   - **Multi-select**: when the user may want to combine options, use `multiSelectOptions` to present a checklist
   - Always include a final option like "Other (explain)" so the user is not boxed in
3. Record the user's choice before moving to the next edge

Loop until no more edges remain. Then append all resolved decisions to the context file:

```markdown
---

## Resolved Decisions

- **<Issue 1>**: <User's choice> — <rationale if given>
- **<Issue 2>**: <User's choice>
- ...
```

---

## Slug Convention

Throughout this skill, `<goal-slug>` and `<direction-slug>` refer to URL-safe identifiers derived from the goal text and direction names. Rules:
- Lowercase, replace spaces and special characters with hyphens
- Remove consecutive hyphens, trim leading/trailing hyphens
- Truncate to 40 characters
- Generate slugs once (in this phase and Phase 2) and reuse them in all later phases

---

## Phase 2: Abstract Planning

Generate N high-level implementation directions (typically 2-4). Each direction should:
- Take a distinct architectural or strategic approach
- Be independent — no direction should reference another
- Be described in 3-5 bullet points (high-level only)
- Have a short descriptive name
- Include key tradeoffs (what you gain, what you give up)
- Include a risk assessment

### Diversity check

Ensure directions are meaningfully different. If two directions would produce similar code, similar file changes, or similar architecture — replace one. Fewer distinct directions beat many similar ones.

### User selection

Present all directions in a comparison format. Then ask the user to select one or more directions to expand into detailed plans. The user may also:
- Request modifications to a direction before selecting
- Ask for an additional direction not yet proposed
- Ask clarifying questions

---

## Phase 3: Detailed Planning

For each selected direction, create the planning infrastructure:

### 3a. Create tasks, team, and spawn writers

1. Use `TaskCreate` to create one task per selected direction, named after the direction.

2. Use `TeamCreate` to create the team (name: `diverge-planning`, description based on the goal).

3. Use the `Agent` tool to spawn each teammate into the team:
   - For each selected direction, spawn one teammate with `subagent_type: diverge-plan-writer`, `team_name: diverge-planning`, and `name: writer-<direction-slug>`

### 3b. Send assignments to diverge-plan-writers

For each spawned writer, use `SendMessage` to deliver the assignment:

```
## Your Assignment

**Context file**: <CONTEXT_FILE path>
**Direction name**: <name>
**Direction summary**:
<the 3-5 bullet points from the abstract plan>

**Original goal**: <user's goal>

**Output path**: /tmp/diverge/<goal-slug>/plans/<direction-slug>.md

Read the context file first, then write the detailed plan to the output path.
When finished, spawn a Devil's Advocate sub-agent to validate your plan internally.
```

### 3c. Internal validation

Each plan-writer handles validation autonomously by spawning its own Devil's Advocate sub-agent:
1. Writer completes the detailed plan
2. Writer spawns a `diverge-devils-advocate` sub-agent to review the plan
3. If rejected — writer revises and spawns a new DA sub-agent (up to 3 rounds)
4. If approved — writer marks their task complete

Do NOT intervene in this loop. Wait for all tasks to complete.

---

## Phase 4: Final Review

Once all diverge-plan-writer tasks are complete:

### 4a. Read all detailed plans

Read each plan from `/tmp/diverge/<goal-slug>/plans/<direction-slug>.md`.

### 4b. Cross-comparison

Present a comparison table:

| | Direction 1 | Direction 2 | ... |
|---|---|---|---|
| **Approach** | 1-line summary | 1-line summary | |
| **Pros** | ... | ... | |
| **Cons** | ... | ... | |
| **Complexity** | low/med/high | low/med/high | |
| **Risk** | ... | ... | |
| **DA verdict** | approved / approved with notes | ... | |

### 4c. Recommendation

Provide your recommendation with reasoning. If multiple directions were selected, explain which is strongest and why.

---

## Phase 5: Generate Launchers

For each detailed plan, determine the branch type from the plan content (feat/fix/refactor/chore) and generate a launcher script.

### 5a. Write the init prompt

For each plan, write a prompt file to `/tmp/diverge/<goal-slug>/prompts/<direction-slug>.md`:

```markdown
You are an Implementor orchestrating plan execution in an isolated worktree.

## Context
Read the grounding context at: <CONTEXT_FILE path>

## Plan
Read the detailed plan at: /tmp/diverge/<goal-slug>/plans/<direction-slug>.md

## Execution

Use TaskCreate to decompose the plan into phases. Use TeamCreate to form
an implementation team. Each phase becomes a task.

Your team MUST include a Devil's Advocate phase as the final task. This
phase verifies:
- All plan steps were executed correctly
- The result satisfies the original goal
- No regressions or unintended side effects

Other phases are derived from the detailed plan's phase structure. Assign
teammates to phases based on the work required.

Begin implementation immediately after reading the context and plan.
```

### 5b. Generate all launcher scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/generate-launcher.sh \
  --goal "<goal-slug>" \
  --approaches "<slug-1>,<slug-2>,<slug-3>" \
  --branch-type "<feat|fix|refactor|chore>" \
  --prompts-dir "/tmp/diverge/<goal-slug>/prompts"
```

This generates all launchers in a single call. Each approach must have a corresponding `<slug>.md` file in the prompts directory.

### 5c. Present to user

List all generated launcher scripts:

```
## Ready to execute

Run any of these to begin implementation in an isolated worktree:

  /tmp/diverge/<goal-slug>/<direction-slug>.sh

Each script:
1. Creates a new worktree branched from the current branch
2. Launches Claude Code with the full implementation prompt
3. Claude will autonomously execute the detailed plan using agent teams
```

---

## Notes

- The context file is the single shared artifact across all phases — grounding, edges, and decisions accumulate there
- Plan-writers and DA operate autonomously within their team — do not micromanage
- Launcher scripts are self-contained — no dependency on user shell config
- All artifacts live under `/tmp/diverge/` — ephemeral, cleared on reboot
- Branch naming follows repo location conventions (see `generate-launcher.sh`)
