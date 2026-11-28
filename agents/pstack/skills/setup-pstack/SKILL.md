---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes a shared local settings file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Configure pstack models

Read `~/.agents/pstack-models.md` if it exists. When migrating a Claude Code setup, preserve the user's existing role choices from `~/.claude/rules/pstack-models.md` unless they request changes. Discover the model and effort choices supported by the current client. Ask for the desired budget or role changes when the request leaves them open.

Write the selected budget and one `role: value` line per override to that file. Keep unrelated existing preferences. Supported roles are `feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`, `judgment and prose`, `swarm workers`, `arena runners`, `arena cross-judge pool` and `interrogate reviewers`. Panels accept comma-separated entries. Use `inherit-parent` for the session default. Set effort through the client's supported option. Report the changed settings.
