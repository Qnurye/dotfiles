---
name: pr
description: Create a pull request for the current branch. Use when user wants to create a PR, submit changes for review, or push current work as a draft PR. Handles committing uncommitted changes, pushing to remote, and creating the PR with appropriate title and description.
---

# Create Pull Request

## Workflow

1. **Check branch** - If on `main`, read prefix from `git config user.branchprefix`. If not set, ask user for their name abbreviation and run `git config user.branchprefix <prefix>`. Create a new branch named `<prefix>-<description>`. If on another branch, verify it starts with the configured prefix.
2. **Check for uncommitted changes** - If staged, unstaged, or untracked files exist, commit them with a Conventional Commits message
3. **Review changes** - Run `git diff main...HEAD` to see all changes included in the PR
4. **Verify changes exist** - If no changes vs main, inform user and stop
5. **Push branch** - Push to origin
6. **Check existing PR** - Run `gh pr view`. If PR exists, provide URL
7. **Update PR** - If PR exists, run `gh pr edit` with new title and description
8. **Create draft PR** - Else, run `gh pr create -d` with title and description
9. **Return PR URL**

## Commit Message Format

Use Conventional Commits:

```
<type>(<optional scope>): <short description>

<optional body>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `chore`

## PR Description Format

Follow the repository's `.github/pull_request_template.md`. Structure:

```
Closes #

**Review and revise this AI-generated description before publishing and requesting reviews.**

<concise single paragraph describing the changes>

## Test plan

- <significant user scenario or edge case tested>
- <specific steps if needed to reproduce results>
```

Guidelines:

- Keep description to one paragraph unless major changes warrant a bulleted list
- Only include background/intent if clearly understood from context
- Test plan: focus on significant scenarios, not trivial cases
- Omit CI-covered items (formatting, linting, test passing)
