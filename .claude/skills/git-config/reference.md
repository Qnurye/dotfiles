# Git Configuration Reference

## Key Configuration Categories

| Section | Purpose | Notable Options |
|---------|---------|-----------------|
| `[user]` | Identity | `name`, `email`, `signingkey` |
| `[core]` | Core behavior | `editor`, `pager`, `autocrlf`, `excludesFile`, `whitespace` |
| `[commit]` | Commit defaults | `gpgsign`, `template`, `verbose` |
| `[gpg]` | Signing config | `program`, `format` (openpgp/x509/ssh) |
| `[pull]` | Pull strategy | `rebase` (true/false/merges), `ff` |
| `[push]` | Push behavior | `autoSetupRemote`, `default` (simple/matching/current), `followTags` |
| `[merge]` | Merge settings | `conflictstyle` (merge/diff3/zdiff3), `ff`, `tool` |
| `[diff]` | Diff options | `algorithm` (histogram/patience/minimal/myers), `colorMoved`, `external`, `tool` |
| `[init]` | New repo defaults | `defaultBranch` |
| `[alias]` | Custom commands | Any key becomes `git <key>` |
| `[credential]` | Auth helpers | `helper` (osxkeychain/store/cache) |
| `[filter "..."]` | Clean/smudge filters | `clean`, `smudge`, `process`, `required` (used by LFS) |
| `[delta]` | Delta pager config | `navigate`, `side-by-side`, `line-numbers`, `syntax-theme` |
| `[interactive]` | Interactive mode | `diffFilter` |
| `[includeIf "..."]` | Conditional includes | `path` |

## Current Config Highlights
- GPG commit signing enabled (`commit.gpgsign = true`)
- Delta as pager with side-by-side diffs and Dracula/Nord theme
- Difftastic available via aliases (`git dft`, `git dfts`, `git dlog`)
- Git LFS configured
- Pull strategy: rebase
- Push: `autoSetupRemote = true`
- Diff algorithm: histogram
- Merge conflict style: diff3
- Editor: Zed (`zed --wait`)
