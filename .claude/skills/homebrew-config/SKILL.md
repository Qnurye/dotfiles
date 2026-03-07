---
description: Homebrew Brewfile package management. Use when modifying, generating, or troubleshooting the Brewfile (adding/removing packages, taps, casks, Mac App Store apps, VS Code extensions).
user-invocable: false
allowed-tools: Read, Edit, Grep, Glob
---

# Homebrew Brewfile

## Config Location
- Dotfiles path: `homebrew/Brewfile`
- Install: `brew bundle --file=homebrew/Brewfile`
- Dump current: `brew bundle dump --file=homebrew/Brewfile --force`
- Check: `brew bundle check --file=homebrew/Brewfile`
- Cleanup unlisted: `brew bundle cleanup --file=homebrew/Brewfile`

## Format & Syntax
- Ruby-based DSL; `#` for comments
- Ruby conditionals supported (e.g., `if OS.mac?`)
- Section order: tap -> brew -> cask -> vscode -> go/cargo/uv

## Instructions
1. Read the current Brewfile first
2. Maintain alphabetical ordering within each section
3. Add taps before formulae that depend on them
4. Third-party tap formulae go after core brew entries
5. For services, use `restart_service: :changed` unless always-restart is needed
6. Never remove entries without user confirmation

## Reference
See [reference.md](reference.md) for directive syntax and options.

## Official Documentation
https://docs.brew.sh/Brew-Bundle-and-Brewfile
