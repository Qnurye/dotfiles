# Diverge Signal Protocol

Canonical signal definitions for all diverge agent communication. Every signal
uses SCREAMING_SNAKE_CASE. Agents must follow the exact schemas below.

---

### PHASE_DONE
- **Sender:** Implementer / TDD-Implementer
- **Receiver:** Orchestrator
- **Trigger:** All phase work complete, all tests passing, self-review done
- **Required fields:**
  - `Phase`: string — phase name from the plan
  - `Tests`: string — `<pass>/<total>` (or `Unit tests: <pass>/<total>` for TDD)
  - `Files changed`: list — files created or modified
  - `Status`: enum — `DONE | DONE_WITH_CONCERNS`
- **Optional fields:**
  - `Concerns`: string — specific issues with file:line references (required when Status is DONE_WITH_CONCERNS)
- **Prohibited:** Must not include test code. Must not claim DONE if any test is failing.

**Wire format:**
```
PHASE_DONE:
Phase: <phase name>
Tests: <pass>/<total>
Files changed: <list>
Status: DONE | DONE_WITH_CONCERNS
Concerns: <if any>
```

---

### PHASE_TESTS_DONE
- **Sender:** TDD-Writer
- **Receiver:** Orchestrator
- **Trigger:** All unit tests written after CONVENTION_AGREED, self-review done
- **Required fields:**
  - `Phase`: string — phase name
  - `Test files`: list — paths to test files written
  - `Test count`: number — total test cases
  - `Edge cases covered`: string — summary of edge cases from Convention
- **Optional fields:** none
- **Prohibited:** Must not include implementation code. Must not be sent before CONVENTION_AGREED.

**Wire format:**
```
PHASE_TESTS_DONE:
Phase: <phase name>
Test files: <list of test files written>
Test count: <number of test cases>
Edge cases covered: <summary>
```

---

### TESTS_WRITTEN
- **Sender:** TDD-DA (Devil's Advocate)
- **Receiver:** Orchestrator
- **Trigger:** Integration and smoke tests written in DA worktree (Phase A complete)
- **Required fields:**
  - `integration`: string — path to integration test files
  - `smoke`: string — path to smoke/e2e test files
  - `config_changes`: string — test config files created/modified, or `"none"`
  - `test_count`: number — total test cases written
- **Optional fields:** none
- **Prohibited:** Must not reference implementation code. Tests must be based on plan and context only.

**Wire format:**
```
TESTS_WRITTEN:
integration: <path to integration test directory/files>
smoke: <path to smoke/e2e test directory/files>
config_changes: <list of any test config files created or modified, or "none">
test_count: <number of test cases written>
```

---

### BLOCKED
- **Sender:** Any implementer (Implementer, TDD-Writer, TDD-Implementer, TDD-DA)
- **Receiver:** Orchestrator
- **Trigger:** Cannot proceed without external input — architectural decision, missing context, or unexpected state
- **Required fields:**
  - `Phase`: string — phase name
  - `Issue`: string — what you're stuck on
  - `Tried`: string — what you attempted before escalating
  - `Need`: string — what kind of help (more context, a decision, task split)
- **Optional fields:** none
- **Prohibited:** Must not include a proposed solution without supporting evidence. Must not be used to avoid difficult work.

**Wire format:**
```
BLOCKED:
Phase: <phase name>
Issue: <what you're stuck on>
Tried: <what you attempted>
Need: <what kind of help — more context, a decision, task split>
```

---

### NEEDS_CONTEXT
- **Sender:** Any implementer (Implementer, TDD-Writer, TDD-Implementer, TDD-DA)
- **Receiver:** Orchestrator
- **Trigger:** Missing specific information needed to continue — less severe than BLOCKED
- **Required fields:**
  - `Phase`: string — phase name
  - `Question`: string — specific question
  - `Why`: string — why this information is needed to proceed
- **Optional fields:** none
- **Prohibited:** Must not ask questions answerable from the plan or context file. Read both first.

**Wire format:**
```
NEEDS_CONTEXT:
Phase: <phase name>
Question: <specific question>
Why: <why you need this to proceed>
```

---

### CONVENTION_START
- **Sender:** TDD-Writer
- **Receiver:** TDD-Implementer (paired)
- **Trigger:** Plan and context read, ready to propose interfaces for the phase
- **Required fields:**
  - `Phase`: string — phase name
  - `Proposed interfaces`: list — function/method signatures, data structures, module boundaries
  - `Boundary conditions I plan to test`: list — edge cases to cover
- **Optional fields:** none
- **Prohibited:** Must not include implementation suggestions. Must not propose interfaces for phases other than the assigned one.

**Wire format:**
```
CONVENTION_START:
Phase: <your phase name>

Proposed interfaces:
- <function/method signatures>
- <data structures and types>
- <module boundaries>

Boundary conditions I plan to test:
- <edge case 1>
- <edge case 2>
```

---

### CONVENTION_REVIEW
- **Sender:** TDD-Implementer
- **Receiver:** TDD-Writer (paired)
- **Trigger:** Received CONVENTION_START or CONVENTION_ROUND_2, reviewed proposals
- **Required fields:**
  - `Agreed`: string — what works as proposed
  - `Suggested changes`: string — what needs adjustment and why
  - `Missing`: string — anything the Writer missed
- **Optional fields:** none
- **Prohibited:** Must not propose entirely new interfaces unrelated to the Writer's proposal. Must not skip review by sending CONVENTION_AGREED without evaluating.

**Wire format:**
```
CONVENTION_REVIEW:
Agreed: <what works>
Suggested changes: <what needs adjustment and why>
Missing: <anything the TDD Writer missed>
```

---

### CONVENTION_ROUND_2
- **Sender:** TDD-Writer
- **Receiver:** TDD-Implementer (paired)
- **Trigger:** Received CONVENTION_REVIEW, incorporated feedback
- **Required fields:**
  - `Adjusted interfaces`: list — changes based on Implementer feedback
  - `Additional edge cases`: list — new cases from discussion
- **Optional fields:** none
- **Prohibited:** Must not ignore Implementer feedback. Must not introduce unrelated interface changes.

**Wire format:**
```
CONVENTION_ROUND_2:
Adjusted interfaces:
- <changes based on feedback>

Additional edge cases:
- <new cases from discussion>

Do you agree? Reply CONVENTION_AGREED if yes.
```

---

### CONVENTION_AGREED
- **Sender:** TDD-Writer or TDD-Implementer (either party)
- **Receiver:** Counterpart (the paired agent)
- **Trigger:** All interface proposals are acceptable — no further negotiation needed
- **Required fields:** none (signal name alone is sufficient)
- **Optional fields:**
  - Inline confirmation text after the signal name
- **Prohibited:** Must not be sent if any unresolved disagreement exists. Ends negotiation immediately — no further Convention rounds after this signal.

**Wire format:**
```
CONVENTION_AGREED
```

---

### CONVENTION_DEADLOCK
- **Sender:** TDD-Writer
- **Receiver:** Orchestrator
- **Trigger:** 3 Convention rounds exhausted without CONVENTION_AGREED
- **Required fields:**
  - `Phase`: string — phase name
  - `Issue`: string — what cannot be agreed on
  - `TDD Writer position`: string — Writer's stance and reasoning
  - `Implementer position`: string — Implementer's stance and reasoning
- **Optional fields:** none
- **Prohibited:** Must not be sent before completing 3 rounds. Must not be sent to the Implementer.

**Wire format:**
```
CONVENTION_DEADLOCK:
Phase: <phase name>
Issue: <what you can't agree on>
TDD Writer position: <your stance and reasoning>
Implementer position: <their stance and reasoning>
Please decide.
```

---

### MERGE_AND_VERIFY
- **Sender:** Orchestrator
- **Receiver:** TDD-DA
- **Trigger:** All implementation pairs done, feature branch merged into DA worktree
- **Required fields:** none (signal name alone is sufficient — the Orchestrator has already performed the merge)
- **Optional fields:**
  - Context about what was merged
- **Prohibited:** Must not be sent before all implementation pairs report PHASE_DONE. DA must not self-trigger this.

**Wire format:**
```
MERGE_AND_VERIFY
```

---

### FIXES_APPLIED
- **Sender:** Orchestrator
- **Receiver:** TDD-DA
- **Trigger:** Fix round complete, updated code re-merged into DA worktree
- **Required fields:** none (signal name alone — Orchestrator has already re-merged)
- **Optional fields:**
  - Summary of fixes applied
- **Prohibited:** Must not be sent before all relevant FIX_DONE signals received.

**Wire format:**
```
FIXES_APPLIED: re-merge and verify
```

---

### TEST_FEEDBACK
- **Sender:** TDD-Implementer
- **Receiver:** TDD-Writer (paired)
- **Trigger:** Unit tests fail and root cause is in the test, not the implementation
- **Required fields:**
  - `Test`: string — name of the failing test
  - `Issue`: string — what's wrong with the test
  - `Evidence`: string — why this is a test issue, not an implementation bug
- **Optional fields:**
  - `Suggested fix`: string — optional fix suggestion
- **Prohibited:** Must not be used to avoid fixing real implementation bugs. Must include evidence.

**Wire format:**
```
TEST_FEEDBACK:
Test: <test name>
Issue: <what's wrong>
Evidence: <why this is a test issue, not an implementation bug>
Suggested fix: <optional>
```

---

### FIX_REQUEST
- **Sender:** Orchestrator
- **Receiver:** Implementer / TDD-Implementer
- **Trigger:** DA review found issues that need fixing in this implementer's phase
- **Required fields:**
  - Issue details — what to fix, with file:line references from DA findings
- **Optional fields:**
  - Severity from DA report
- **Prohibited:** Must not include fixes for phases owned by other implementers.

**Wire format:**
```
FIX_REQUEST:
<issue details from DA findings>
```

---

### FIX_DONE
- **Sender:** Implementer / TDD-Implementer
- **Receiver:** Orchestrator
- **Trigger:** Fix request addressed, tests re-run and passing
- **Required fields:**
  - Description of what was fixed
- **Optional fields:**
  - Files changed
- **Prohibited:** Must not claim done if tests are failing after the fix.

**Wire format:**
```
FIX_DONE: <what you fixed>
```

---

### REVIEW_COMPLETE
- **Sender:** TDD-DA
- **Receiver:** Orchestrator
- **Trigger:** Phase B verification done — all tests run, code review complete
- **Required fields:**
  - Status (inline after colon): enum — `APPROVED | NEEDS_FIXES`
  - `Test results`: string — `<pass>/<total> passing`
- **Optional fields (required when NEEDS_FIXES):**
  - `Findings`: list — categorized as `[Critical]`, `[Important]`, or `[Minor]` with file:line references
  - `Failed tests`: list — test name and failure reason
- **Optional fields (when APPROVED):**
  - `Review`: string — confirmation note
- **Prohibited:** Must not approve with any failing test. Status appears inline after the colon (`REVIEW_COMPLETE: APPROVED`), not inside the body.

**Wire format (APPROVED):**
```
REVIEW_COMPLETE: APPROVED
Test results: <pass>/<total> passing
Review: No issues found.
```

**Wire format (NEEDS_FIXES):**
```
REVIEW_COMPLETE: NEEDS_FIXES
Test results: <pass>/<total> passing (<fail> failures)

Findings:
- [Critical] <issue description, file:line reference>
- [Important] <issue description>
- [Minor] <issue description>

Failed tests:
- <test name>: <failure reason>
```

---

### DECISION
- **Sender:** Orchestrator
- **Receiver:** TDD-Writer (after CONVENTION_DEADLOCK)
- **Trigger:** Orchestrator received CONVENTION_DEADLOCK and made a ruling
- **Required fields:**
  - The decision and reasoning
- **Optional fields:** none
- **Prohibited:** Must not be sent without a preceding CONVENTION_DEADLOCK. Must not leave the decision ambiguous.

**Wire format:**
```
DECISION:
<resolved interface decision>
```
