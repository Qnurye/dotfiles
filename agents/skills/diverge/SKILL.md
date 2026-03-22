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

## Phase 1: Edge Clarification (Multi-Round)

Iteratively clarify the user's goal through layered rounds until the specification is fully resolved. This phase focuses exclusively on **intent, goals, and behavior/interaction rules** — never ask about technical implementation details, architecture choices, or non-functional requirements (performance, compatibility, etc.). Technical details belong in the plans (Phase 3).

### Allowed question topics

- **User intent / goals**: "What effect do you want to achieve?", "What motivated this change?"
- **Behavior / interaction rules**: "When X happens, what should the outcome be?", "What does the user see/experience?"

### Prohibited question topics (defer to plans)

- Architecture, data structures, file organization
- Performance, scalability, compatibility constraints
- Library/framework choices, API design
- Priorities or tradeoffs between competing concerns

### Round structure

Each round follows a layered progression. The AI decides how many questions to ask per round based on the number of ambiguities found — there is no fixed limit.

**Round 1 — Scope & Goals**: Review the goal against grounded context. Ask about high-level intent, target audience, core scenarios, and desired outcomes.

**Round 2+ — Behavior & Boundaries**: Based on previous answers, probe deeper into behavioral rules, edge cases in user-facing flows, and boundary conditions. Each round focuses on new ambiguities surfaced by prior answers.

### Round execution

For each round:

1. Analyze the goal + context + all prior answers to identify remaining ambiguities
2. For each ambiguity, use `AskUserQuestion`:
   - **Single-select**: when options are mutually exclusive
   - **Multi-select**: when the user may combine options
   - The tool automatically provides an "Other" escape hatch
3. Record the user's choices

### Convergence check

After each round, evaluate: did the user's answers surface any new ambiguities or unresolved behavioral questions?

- **Yes** → begin a new round targeting those new ambiguities
- **No** → proceed to termination

### Termination: spec summary + user confirmation

When no new ambiguities remain, present a **complete specification summary** — a plain-language description of every resolved decision organized by topic. Then use `AskUserQuestion` to ask the user for final confirmation:

- "Looks complete" → proceed to Phase 2
- "I want to add/change something" → start a new round with the user's additions

### Persist decisions

Append all resolved decisions to the context file after termination:

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

### 5a. Generate all launcher scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/generate-launcher.sh \
  --goal "<goal-slug>" \
  --approaches "<slug-1>,<slug-2>,<slug-3>" \
  --branch-type "<feat|fix|refactor|chore>" \
  --context-file "<CONTEXT_FILE path>" \
  --plans-dir "/tmp/diverge/<goal-slug>/plans"
```

This generates all launchers in a single call. Each approach must have a corresponding `<slug>.md` plan file in the plans directory. The script embeds the init prompt (with context and plan paths) directly into each launcher — no intermediate prompt files needed.

### 5b. Present to user

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
