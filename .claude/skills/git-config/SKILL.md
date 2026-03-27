---
description: Git configuration. Use when modifying, generating, or troubleshooting .gitconfig (user identity, aliases, diff, merge, push, pull, GPG signing, delta pager, conditional includes, LFS).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Git Configuration

## Config Locations
- Dotfiles path: `vcs/git/.gitconfig`, `vcs/git/.work.gitconfig`, `vcs/git/.gitignore_global`
- Symlinked to: `~/.gitconfig`, `~/.work.gitconfig`, `~/.gitignore_global`
- Symlinks managed in `nix/modules/home/dotfiles.nix`
- Personal: Jaren Lo <qnurye@gmail.com>
- Work: Wenjie Luo <luowenjie@adastralab.ai> (via `includeIf "gitdir:**/*work*/"`)

## Format & Syntax
- INI-like: `[section]` or `[section "subsection"]`
- Keys: `key = value`, case-insensitive, alphanumeric + `-`
- Comments: `#` or `;`
- Booleans: `true/yes/on/1`, `false/no/off/0`

## Conditional Includes
```ini
[includeIf "gitdir:**/*work*/"]
    path = ~/.work.gitconfig
```
- `**/*work*/` matches any repo path containing "work" as a directory component
- `gitdir/i:` for case-insensitive matching
- Included path is relative to the file containing the `includeIf`

## Instructions
1. Read `vcs/git/.gitconfig` and `vcs/git/.work.gitconfig` first
2. Use correct INI section syntax
3. Work-specific settings go in `.work.gitconfig`
4. Preserve existing aliases, delta theme, and LFS config
5. Indent keys with a tab to match existing style
6. GPG signing is mandatory -- do not disable it
7. Both personal and work identities have separate GPG signing keys

## Reference
See [reference.md](reference.md) for configuration categories and options.

## Official Documentation
https://git-scm.com/docs/git-config
