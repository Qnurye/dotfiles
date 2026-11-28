---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes a shared local settings file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Configure pstack models

Edit the JSON block in the source of `~/.agents/pstack-models.md`. Preserve the existing roles and per-model command argument arrays unless the user requests changes. Verify a new model and its flags with the assigned CLI. The launcher feeds the brief through stdin unless a command argument is exactly `{brief}`, in which case it supplies the full text as that single argument.

Use `~/.local/bin/pstack-worker --list ROLE` to verify each changed role. Smoke-test changed routes on a harmless brief in a temporary directory. Report the models, effort and affected roles.
