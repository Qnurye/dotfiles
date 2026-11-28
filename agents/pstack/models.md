# Local pstack workers

For delegated pstack tasks, run `~/.local/bin/pstack-worker ROLE BRIEF_FILE` from the assigned working directory. Use `--list ROLE` to list a panel and `--seat MODEL` to launch each selected seat. Give each concurrent writer its own Worktrunk worktree. Keep the exit status, output and tested head. Select one cross-judge from the pool, preferably different from the lead.

The commands below set the xhigh budget and invocation permissions per worker process.

```json
{
  "roles": {
    "feature, refactoring": [
      "claude-opus-5-5"
    ],
    "bug-fix": [
      "claude-opus-5-5"
    ],
    "perf-issue": [
      "claude-opus-5-5"
    ],
    "hillclimb": [
      "claude-opus-5-5"
    ],
    "judgment and prose": [
      "claude-opus-5-5"
    ],
    "swarm workers": [
      "claude-opus-5-5"
    ],
    "arena runners": [
      "claude-opus-5-5",
      "gpt-6.2-sol",
      "gemini-4-neon-xhigh"
    ],
    "arena cross-judge pool": [
      "gpt-6.2-sol",
      "gemini-4-neon-xhigh",
      "claude-opus-5-5"
    ],
    "interrogate reviewers": [
      "claude-opus-5-5",
      "gpt-6.2-sol",
      "gemini-4-neon-xhigh"
    ]
  },
  "commands": {
    "claude-opus-5-5": [
      "claude",
      "--model",
      "claude-opus-5-5",
      "--effort",
      "xhigh",
      "--dangerously-skip-permissions",
      "-p"
    ],
    "gpt-6.2-sol": [
      "codex",
      "exec",
      "--model",
      "gpt-6.2-sol",
      "-c",
      "model_reasoning_effort=\"xhigh\"",
      "--dangerously-bypass-approvals-and-sandbox",
      "--skip-git-repo-check",
      "-"
    ],
    "gemini-4-neon-xhigh": [
      "agy",
      "--model",
      "gemini-4-neon-xhigh",
      "--dangerously-skip-permissions",
      "-p",
      "{brief}"
    ]
  }
}
```
