# User Preferences

## Personal
- User Jaren Lo dislikes honorifics (敬语) and prefers to be addressed as '你' instead of '您'.
- INFP, feels more comfortable with selectable choices.

## Git & Version Control
- Prefer 'refactor' commit types for moving logic without changing behavior.
- Prefer `gh` CLI to access GitHub.
- Git pull strategy: rebase.
- GPG signing enabled for commits.
- **No git commit**: Never run `git commit` directly. Jaren must review and commit.
- **No peer interaction**: Never use `gh pr review`, `gh pr comment`, `gh issue comment`, `gh pr merge`, `gh pr reply`, or any command that interacts with real people. Jaren must review first.
- **Prepare, don't execute**: For commits and PR interactions, prepare the content and present it for Jaren's approval.

## Development Environment

### Languages & Runtimes
- Deno, Bun, Node.js, Go, Rust

### Editors
- Primary: Zed
- Terminal: Neovim

### Package Managers
- Homebrew for system packages
- pnpm for Node.js projects
- Bun available as alternative

## Project Structure
- Personal projects: `~/repositories/personal`
- Work projects: `~/repositories/work` (uses separate Git identity: Wenjie Luo)
- Dotfiles: `~/dotfiles/` (all configs managed via symlinks)

## Tool Preferences
- Use `jq` for JSON processing
- Docker and kubectl available for containerization
- 1Password CLI for secrets management

## Agent Behavior: Proactive Mode

### Mindset
- Act as an autonomous problem-solver, not a passive responder.
- When context is unclear, explore the filesystem first—don't ask user for information you can find yourself.

### Action Flow
1. **Identify entities** in user's request (filenames, functions, concepts).
2. **Load skills**: If the task matches an available skill's trigger condition, invoke the Skill tool BEFORE generating any response. This is mandatory, not optional.
3. **Self-investigate**: Search files, read configs/tests/docs, check logs before responding.
4. **Silent enrichment**: Read 2-3 relevant files to ground your response in actual code, not assumptions.

### Response Guidelines
- **Avoid**: "Please tell me which file..." or "I don't know..."
- **Prefer**: "I found relevant logic in `path/to/file`. Based on my analysis, I suggest..."

@RTK.md
