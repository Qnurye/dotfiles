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

## Stage B — Translate Each Plan

For each `.md` file found in Stage A:

1. Read the file content using the Read tool.
2. Spawn an Agent subagent with `model: "haiku"` to translate the content. Use this prompt:

   ```
   Translate the following markdown from English to Simplified Chinese (zh-CN).

   Rules:
   - Preserve ALL markdown formatting exactly (headers, lists, code blocks, tables, bold, italic).
   - Do NOT translate: file paths, function names, variable names, code identifiers, command-line flags, or code inside backticks.
   - Do NOT add any preamble, explanation, or notes. Return ONLY the translated markdown.

   Content to translate:

   <paste file content here>
   ```

3. **IMPORTANT**: Spawn ALL translation agents in parallel — use a single message with multiple Agent tool calls, one per plan file. Do NOT translate sequentially.

4. Collect results: for each plan, store the original filename (without `.md` extension, used as tab label), the original EN markdown, and the CN translation.

## Stage C — Assemble and Serve

1. Copy the HTML template to the output directory:
   ```bash
   mkdir -p /tmp/view-plans-output
   cp ~/dotfiles/agents/skills/view-plans/template.html /tmp/view-plans-output/index.html
   ```

2. Build the plans JSON data structure as a string. For each plan:
   - `name`: filename without `.md`, hyphens replaced by spaces, title-cased.
   - `en`: original EN markdown content.
   - `cn`: translated CN markdown content.

   The JSON shape is: `{"plans": [{"name": "...", "en": "...", "cn": "..."}, ...]}`

3. Write the JSON to a temporary file and use `sed` to inject it into the copied HTML, replacing the `<!-- PLANS_DATA -->` placeholder:
   ```bash
   # Write the plans JSON to a temp file via Bash heredoc or Write tool
   # Then inject it into the HTML:
   sed -i '' "s|<!-- PLANS_DATA -->|<script>window.__PLANS__ = $(cat /tmp/view-plans-data.json);</script>|" /tmp/view-plans-output/index.html
   ```
   Alternatively, use a Bash script with `node -e` or `bun -e` for proper JSON escaping:
   ```bash
   bun -e "
     const data = JSON.parse(require('fs').readFileSync('/tmp/view-plans-data.json','utf8'));
     let html = require('fs').readFileSync('/tmp/view-plans-output/index.html','utf8');
     html = html.replace('<!-- PLANS_DATA -->', '<script>window.__PLANS__ = ' + JSON.stringify(data) + ';</script>');
     require('fs').writeFileSync('/tmp/view-plans-output/index.html', html);
   "
   ```
   Use the `bun -e` approach — it handles escaping correctly for markdown content with special characters.

5. Launch the Bun server in the background using the Bash tool:
   ```bash
   bun run ~/dotfiles/agents/skills/view-plans/serve.ts --dir /tmp/view-plans-output --pid-file /tmp/view-plans.pid &
   ```
   The server will print `Serving at http://localhost:<port>` to stdout. Capture the port number.

6. Open the page in the default browser:
   ```bash
   open http://localhost:<port>
   ```

7. Print to the user:
   ```
   Plans are being served at http://localhost:<port>
   Re-invoking /view-plans will automatically replace the running server.
   ```

## Notes

- All file references use absolute paths (`~/dotfiles/agents/skills/view-plans/`) since this skill may be invoked from any working directory.
- The HTML is self-contained — both EN and CN content are embedded. No runtime API calls.
- Translation uses Haiku subagents for speed and cost efficiency.
- The server uses a dynamic port (OS-assigned) and manages its lifecycle via a PID file at `/tmp/view-plans.pid`.
