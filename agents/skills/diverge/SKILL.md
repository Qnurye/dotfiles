---
name: diverge
description: Divergent planning — explore multiple implementation directions for a goal, refine with user input, then generate executable launcher scripts for each chosen approach.
argument-hint: <goal description or GitHub issue URL>
---

# Diverge — Divergent Planning Skill

Explore multiple implementation directions for a goal through grounded research, interactive refinement, and parallel detailed planning. Output is a set of one-click launcher scripts the user can run to begin implementation.

## Input

The user's goal is: `$ARGUMENTS`

If no arguments provided, ask the user for a goal description. The goal can be free-form text or a GitHub issue URL — parse either naturally.

---

## State Machine

Every phase has an explicit entry condition and exit gate. Do not advance to the next state until the exit gate is satisfied. When advancing, print the gate check visibly.

```
┌─────────────────────────────────────────────────────────┐
│  State          Entry requires       Exit gate           │
├─────────────────────────────────────────────────────────┤
│  GROUNDING      script exits OK      context file exists │
│  CLARIFYING     context file exists  spec auditor PASS   │
│  ABSTRACTING    spec auditor PASS    user selects ≥1 dir │
│  PLANNING       user selected dirs   all tasks complete  │
│  REVIEWING      all tasks complete   comparison presented │
│  LAUNCHING      comparison presented launchers generated  │
└─────────────────────────────────────────────────────────┘
```

Transition format — every phase boundary must print:

> ✓ Exit gate satisfied: [condition]. Advancing to [STATE].

---

## Phase 0: Context Grounding

**Entry requires:** Skill invoked with a goal (from `$ARGUMENTS` or user prompt).
**Exit gate:** Context file exists at the path returned by `gather-context.sh`.
**Prohibited in this phase:**
- Do not ask clarifying questions about the goal
- Do not propose directions or architecture
- Do not skip the grounding script

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

> ✓ Exit gate satisfied: context file exists. Advancing to CLARIFYING.

---

## Phase 1: Edge Clarification

**Entry requires:** Context file exists and was read in Phase 0.
**Exit gate:** Spec auditor returns PASS (or user explicitly overrides after 3 failed audits).
**Prohibited in this phase:**
- Do not discuss architecture, data structures, or implementation approach
- Do not ask more than one question per message
- Do not propose directions or plans
- Do not advance to Phase 2 until exit gate is satisfied

Iteratively clarify the user's goal until the specification is fully resolved. This phase focuses exclusively on **intent, goals, and behavior/interaction rules** — never ask about technical implementation details, architecture choices, or non-functional requirements (performance, compatibility, etc.). Technical details belong in the plans (Phase 3).

### Topic boundaries

**Allowed** (intent & behavior):
- **Purpose**: What problem does this solve? What motivated this change?
- **Constraints**: What limits exist? What must NOT change?
- **Success criteria**: How do you know it's done? What does the user see/experience?
- **Behavioral rules**: When X happens, what should the outcome be?

**Prohibited** (defer to Phase 3 plans):
- Architecture, data structures, file organization
- Performance, scalability, compatibility constraints
- Library/framework choices, API design
- Priorities or tradeoffs between competing concerns

### Step 1: Scope assessment

Before asking detailed questions, review the goal against grounded context and assess scope:

- Does the goal describe **multiple independent subsystems**? If so, flag it and propose decomposition into sub-goals. Use `AskUserQuestion` to confirm the decomposition or let the user adjust.
- Is the goal **already narrow enough**? Proceed directly to questioning.

If decomposed, run the remaining steps of Phase 1 for each sub-goal independently, then merge the resolved decisions into a single context file.

### Step 2: Structured questioning (one at a time)

Ask clarifying questions **one per message**. This keeps the conversation natural and avoids overwhelming the user. Prefer **multiple-choice** (single-select or multi-select via `AskUserQuestion`) whenever reasonable options can be enumerated — fall back to open-ended only when the answer space is too large to enumerate.

Progress through three focus areas in order. Within each area, ask as many questions as needed before moving on — but skip questions whose answers are already clear from the grounded context.

**Focus 1 — Purpose & Goals**: Why does this change exist? Who benefits? What are the core scenarios?

**Focus 2 — Constraints & Boundaries**: What must remain unchanged? What is explicitly out of scope? Are there behavioral invariants?

**Focus 3 — Success Criteria & Edge Cases**: How does the user know it worked? What happens in boundary conditions? What does failure look like?

After each answer, evaluate whether it surfaces new ambiguities. If it does, follow up immediately (still one question at a time) before moving to the next focus area.

### Step 3: Convergence check

After all three focus areas have been covered and no new ambiguities remain, advance to the spec audit (Step 4). If the user's latest answer opens a new thread, continue questioning before summarizing.

### Step 4: Spec audit (sub-agent)

Before presenting the summary to the user, persist the current resolved decisions to the context file, then spawn a `diverge-spec-auditor` agent to independently evaluate readiness:

```
Agent(subagent_type: diverge-spec-auditor, prompt: """
Context file: <CONTEXT_FILE path>
Original goal: <user's goal>
""")
```

- If `PASS` → ✓ Exit gate satisfied: spec auditor PASS. Proceed to Step 5.
- If `FAIL` → use the auditor's suggested questions to ask the user for clarification (one at a time, per Step 2 rules), then re-run Step 4.

Up to 3 audit rounds. If still failing after 3, present the remaining gaps to the user and let them decide whether to override (exit gate satisfied by explicit user override) or continue clarifying.

### Step 5: Spec summary + user confirmation

Present a **complete specification summary** — a plain-language description of every resolved decision organized by focus area (Purpose, Constraints, Success Criteria). Then use `AskUserQuestion` to confirm:

- "Looks complete" → ✓ Exit gate satisfied: spec auditor PASS + user confirms spec. Advancing to ABSTRACTING.
- "I want to add/change something" → return to Step 2 with the user's additions, then re-run Steps 3-5

### Persist decisions

Append all resolved decisions to the context file after confirmation:

```markdown
---

## Resolved Decisions

### Purpose & Goals
- **<Decision>**: <User's choice> — <rationale if given>

### Constraints & Boundaries
- **<Decision>**: <User's choice>

### Success Criteria
- **<Decision>**: <User's choice>
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

**Entry requires:** Spec auditor PASS (or user override) and user confirmed the spec summary.
**Exit gate:** User selects ≥1 direction to expand into detailed plans.
**Prohibited in this phase:**
- Do not write detailed implementation plans (that's Phase 3)
- Do not generate launcher scripts
- Do not spawn plan-writer agents

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

Once the user selects ≥1 direction:

> ✓ Exit gate satisfied: user selected directions. Advancing to PLANNING.

---

## Phase 3: Detailed Planning

**Entry requires:** User selected ≥1 direction in Phase 2.
**Exit gate:** All plan-writer tasks reach `completed` status.
**Prohibited in this phase:**
- Do not intervene in plan-writer / DA validation loops
- Do not cancel tasks preemptively
- Do not generate launcher scripts
- Do not present cross-comparison (that's Phase 4)

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

Do NOT intervene in this loop.

### Waiting for plan-writers

Do NOT check in or message plan-writers. Wait for all tasks to reach `completed` status. If a task is still `in_progress` for an unexpectedly long time, check its output with `TaskOutput` before taking any action. Never cancel a task preemptively.

> ✓ Exit gate satisfied: all plan-writer tasks completed. Advancing to REVIEWING.

---

## Phase 4: Final Review

**Entry requires:** All plan-writer tasks completed (all plans written and DA-approved).
**Exit gate:** Cross-comparison and recommendation presented to the user.
**Prohibited in this phase:**
- Do not modify plans
- Do not generate launcher scripts yet
- Do not skip the cross-comparison table
- Do not ask the user to pick which plans to launch — every detailed plan gets a launcher in Phase 5

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

Do not ask the user to choose — every plan in `/tmp/diverge/<goal-slug>/plans/` gets a launcher. Then immediately:

> ✓ Exit gate satisfied: comparison and recommendation presented. Advancing to LAUNCHING.

---

## Phase 5: Generate Launchers

**Entry requires:** Phase 4 cross-comparison and recommendation presented.
**Exit gate:** All launcher scripts generated and presented to the user.
**Prohibited in this phase:**
- Do not modify plans
- Do not re-run clarification or planning phases
- Do not execute the launcher scripts (user does that)

For each detailed plan, determine the branch type from the plan content (feat/fix/refactor/chore) and generate a launcher script.

### 5a. Ask about TDD mode

Use `AskUserQuestion` to ask the user:

```
Should this plan use TDD mode?
```

With options:
- **Yes** — each phase gets a paired TDD Writer + Implementer, DA writes integration tests independently
- **No** — standard single-implementor mode

Record the user's choice for the next step.

### 5b. Generate all launcher scripts

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/generate-launcher.sh \
  --goal "<goal-slug>" \
  --approaches "<slug-1>,<slug-2>,<slug-3>" \
  --branch-type "<feat|fix|refactor|chore>" \
  --context-file "<CONTEXT_FILE path>" \
  --plans-dir "/tmp/diverge/<goal-slug>/plans" \
  # Add --tdd flag only if user chose TDD mode in 5a
```

If the user chose TDD mode in step 5a, append `--tdd` to the command.

This generates all launchers in a single call. Each approach must have a corresponding `<slug>.md` plan file in the plans directory. The script embeds the init prompt (with context and plan paths) directly into each launcher — no intermediate prompt files needed.

### 5c. Present to user

List all generated launcher scripts with the workspace path for plan review:

```
## Ready to execute

Workspace: /tmp/diverge/<goal-slug>/
Plans are at: /tmp/diverge/<goal-slug>/plans/

Run any of these to begin implementation in an isolated worktree:

  /tmp/diverge/<goal-slug>/<direction-slug>.sh

Each script:
1. Creates a new worktree branched from the current branch
2. Launches Claude Code with the full implementation prompt
3. After Claude exits, your terminal stays in the worktree directory
```

If TDD mode was selected, also note:
```
TDD mode enabled — each phase spawns a TDD Writer + Implementer pair.
DA writes integration tests in a separate worktree for unbiased verification.
```

> ✓ Exit gate satisfied: launchers generated and presented. Skill complete.

---

## Notes

- The context file is the single shared artifact across all phases — grounding, edges, and decisions accumulate there
- Plan-writers and DA operate autonomously within their team — do not micromanage
- Launcher scripts are self-contained — no dependency on user shell config
- All artifacts live under `/tmp/diverge/` — ephemeral, cleared on reboot
- Branch naming follows repo location conventions (see `generate-launcher.sh`)
