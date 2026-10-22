# RTK

Claude Code runs the RTK 1.x native `rtk hook claude` processor on `PreToolUse`.
It rewrites supported shell commands, for example `git status` to `rtk git status`.
The Git guard remains a separate hook. No shell rewrite script or hash file is
needed, and this reference is not included in shared agent instructions.

```bash
rtk --version       # Installed binary version
rtk gain            # Token savings analytics
rtk discover        # Missed savings in Claude history
rtk bypass <cmd>    # Run without filtering while tracking usage
```
