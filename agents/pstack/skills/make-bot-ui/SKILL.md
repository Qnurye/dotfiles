---
name: make-bot-ui
description: Build a local page whose controls run named actions or call an explicitly configured bot webhook.
disable-model-invocation: true
---

# Build a local action UI

Map each control to an action the user requested. Reuse the project's existing handler, task queue or CLI. Keep the action names and accepted fields explicit. Validate the input and pass CLI arguments separately from the executable.

Serve the page and action routes from the same loopback listener. For state changes accept same-origin POSTs, validate Host and Origin, and show success or failure from the handler. Verify one harmless action through the page and confirm its local result.

When the user requests an external webhook, use their configured endpoint and its documented authentication on the server. Keep credentials in the existing secret store. Enable remote access only for a requested audience using the project's authenticated access path.
