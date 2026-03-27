# Git Configuration Reference

## Key Configuration Categories

| Section | Purpose | Notable Options |
|---------|---------|-----------------|
| `[user]` | Identity | `name`, `email`, `signingkey` |
| `[core]` | Core behavior | `editor`, `pager`, `excludesFile` |
| `[commit]` | Commit defaults | `gpgsign` |
| `[gpg]` | Signing config | `program`, `format` (openpgp/x509/ssh) |
| `[pull]` | Pull strategy | `rebase` (true/false/merges) |
| `[push]` | Push behavior | `autoSetupRemote`, `default` (simple/matching/current) |
| `[merge]` | Merge settings | `conflictstyle` (merge/diff3/zdiff3) |
| `[diff]` | Diff options | `algorithm` (histogram/patience/minimal/myers), `colorMoved` |
| `[diff "difftastic"]` | Structural diff | `command = difft` |
| `[difftool "difftastic"]` | Difftastic tool | `cmd = difft "$LOCAL" "$REMOTE"` |
| `[difftool]` | Difftool behavior | `prompt = false` |
| `[init]` | New repo defaults | `defaultBranch` |
| `[alias]` | Custom commands | Any key becomes `git <key>` |
| `[filter "lfs"]` | Git LFS filter | `clean`, `smudge`, `process`, `required` |
| `[delta]` | Delta pager config | `navigate`, `side-by-side`, `line-numbers`, `syntax-theme` |
| `[interactive]` | Interactive mode | `diffFilter` |
| `[includeIf "..."]` | Conditional includes | `path` |
| `[gitbutler]` | GitButler settings | `aiModelProvider` |

## Current Config Highlights
- GPG commit signing enabled (`commit.gpgsign = true`, program: `/opt/homebrew/bin/gpg`, format: openpgp)
- Delta as pager with side-by-side diffs, Dracula syntax-theme and Nord-inspired color palette
- Difftastic available via aliases (`git dft`, `git dfts`, `git dlog`)
- Git LFS configured
- Pull strategy: rebase
- Push: `autoSetupRemote = true`
- Diff algorithm: histogram, `colorMoved = default`
- Merge conflict style: diff3
- Editor: Zed (`zed --wait`)
- Default branch: main

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `d` | `diff` | Delta-rendered diff |
| `ds` | `diff --staged` | Delta-rendered staged diff |
| `dw` | `diff --word-diff` | Word-level diff |
| `dft` | `difftool --tool=difftastic` | Structural diff via difftastic |
| `dfts` | `difftool --tool=difftastic --staged` | Staged structural diff |
| `dlog` | `-c diff.external=difft log -p --ext-diff` | Log with structural diffs |

## Work Config (`.work.gitconfig`)
- Included when gitdir matches `**/*work*/`
- Overrides: `user.name = Wenjie Luo`, `user.email`, `user.signingkey`
- Has its own GPG signing key

## Global Gitignore (`.gitignore_global`)
- `.worktrees/` (worktrunk worktree directories)
