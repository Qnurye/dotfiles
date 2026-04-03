---
name: view-plans
description: Translate plan markdown files to Chinese and render as a tabbed HTML page with EN/CN toggle, served locally via Bun.
argument-hint: <plans-directory-path>
---

# View Plans

Translate English plan markdown files to Simplified Chinese and serve them as a tabbed HTML page with language toggle.

## Stage A — Resolve Plans Directory

1. If `$ARGUMENTS` is provided and is a non-empty string:
   - Check if it is a valid directory path using the Bash tool: `test -d "$ARGUMENTS" && echo "valid"`
   - If valid, use it as the plans directory.
   - If not valid, print: `Error: "$ARGUMENTS" is not a valid directory.` and STOP.

2. If `$ARGUMENTS` is empty or not provided:
   - Use the Bash tool to search for a plans directory from a prior diverge session: `ls -d /tmp/diverge/*/plans/ 2>/dev/null | head -1`
   - If a result is found, use it as the plans directory.
   - If no result, print: `Error: No plans directory provided. Pass a directory path as argument or run after a diverge session.` and STOP.

3. Glob `*.md` files in the resolved plans directory using the Glob tool.
   - If no `.md` files are found, print: `Error: No markdown files found in <directory>.` and STOP.

## Stage B — Translate Each Plan (File-Based)

Sub-agents read source files directly and write translations to independent output files. The main agent never reads or handles markdown content.

1. Create the CN output directory:
   ```bash
   mkdir -p /tmp/view-plans-output/cn
   ```

2. For each `.md` file found in Stage A, spawn an Agent subagent with `model: "haiku"`. Use this prompt:

   ```
   Translate a markdown file from English to Simplified Chinese (zh-CN).

   Rules:
   - Read the source file yourself using the Read tool.
   - Preserve ALL markdown formatting exactly (headers, lists, code blocks, tables, bold, italic).
   - Do NOT translate: file paths, function names, variable names, code identifiers, command-line flags, or code inside backticks.
   - Do NOT add any preamble, explanation, or notes.
   - Write ONLY the translated markdown to the output file using the Write tool. Do not output the content in your response.

   Source file: <absolute path to .md file>
   Output file: /tmp/view-plans-output/cn/<same filename>
   ```

3. **IMPORTANT**: Spawn ALL translation agents in parallel — use a single message with multiple Agent tool calls, one per plan file. Do NOT translate sequentially.

4. Wait for all agents to complete. Do NOT read their output files.

## Stage C — Assemble and Serve

1. Copy the HTML template to the output directory:
   ```bash
   cp ~/dotfiles/agents/skills/view-plans/scripts/template.html /tmp/view-plans-output/index.html
   ```

2. Run the assemble script to read all EN + CN files from disk, build JSON, and inject into HTML. The main agent does NOT read any markdown files — the script handles everything:
   ```bash
   bun run ~/dotfiles/agents/skills/view-plans/scripts/assemble.ts --plans-dir <resolved plans directory>
   ```

3. Launch the Bun server in the background using the Bash tool:
   ```bash
   bun run ~/dotfiles/agents/skills/view-plans/scripts/serve.ts --dir /tmp/view-plans-output --pid-file /tmp/view-plans.pid &
   ```
   The server will print `Serving at http://localhost:<port>` to stdout. Capture the port number.

4. Open the page in the default browser:
   ```bash
   open http://localhost:<port>
   ```

5. Print to the user:
   ```
   Plans are being served at http://localhost:<port>
   Re-invoking /view-plans will automatically replace the running server.
   ```

## Notes

- All file references use absolute paths (`~/dotfiles/agents/skills/view-plans/`) since this skill may be invoked from any working directory.
- The HTML is self-contained — both EN and CN content are embedded. No runtime API calls.
- Translation uses Haiku subagents for speed and cost efficiency.
- The server uses a dynamic port (OS-assigned) and manages its lifecycle via a PID file at `/tmp/view-plans.pid`.
