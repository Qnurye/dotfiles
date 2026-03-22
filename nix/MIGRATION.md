# Nix Migration Tracker

## Hosts

| Host | Type | Hostname | Status | Target Date |
|------|------|----------|--------|-------------|
| Personal Mac (Air) | nix-darwin | `bowl-air` | ✅ Coexistence verified | 2026-03-23 |
| Work Mac | nix-darwin | `heavybowl-ii` | Pending | 2026-03-24 |

## Migration Steps (per host)

### 1. Bootstrap Nix

```bash
./install.sh nix
```

- [x] bowl-air (2026-03-23)
- [ ] work mac

### 2. Verify coexistence

After `darwin-rebuild switch`, confirm:

- [x] Nix-managed packages available in `$PATH` (bowl-air)
- [x] Homebrew packages still intact (cleanup=none) (bowl-air)
- [x] Dotfile symlinks correct — home-manager manages all (bowl-air)
- [x] Fish shell works normally (bowl-air)
- [x] GPG signing works (bowl-air)

### 3. Verify work mac

- [ ] Run `./install.sh nix` on heavybowl-ii
- [ ] Confirm work-specific tags resolve correctly
- [ ] Adjust tag list in `nix/hosts/heavybowl-ii/default.nix` as needed

## Tag Coverage

Packages in tags vs Brewfile. Checked = in a tag, unchecked = not yet migrated.

### CLI (brew)

- [x] bat, fd, fzf, ripgrep, yazi, neovim, tmux, eza, zoxide, tree
- [x] git, curl, wget, jq, gnupg, coreutils
- [x] lazygit, direnv, git-lfs, delta, difftastic
- [x] gh, go, gopls, gotools, go-tools (staticcheck)
- [x] rustup, fnm, deno, python3, uv, ruff
- [x] fish
- [ ] act, actionlint
- [ ] atomicparsley, automake
- [ ] cagent, clang-format, cloudflared, convmv
- [ ] displayplacer, docker, docker-compose, duckdb, duti
- [ ] ffmpeg, fonttools
- [ ] gemini-cli
- [ ] himalaya, hub-tool
- [ ] imagemagick, jpegoptim
- [ ] kubernetes-cli
- [ ] libev, libpq, libtool
- [ ] marked, mosh
- [ ] neonctl, nmap
- [ ] ollama, oxipng
- [ ] pandoc, pinentry-mac, pkgconf, pngquant, poetry, poppler
- [ ] python@3.12, python@3.9
- [ ] resvg, sevenzip, signal-cli
- [ ] tailscale, ttyd, typst
- [ ] unar, watch, woff2, worktrunk, zopfli, zstd

### Casks

- [x] ghostty, zed, claude, claude-code, codex
- [x] obsidian, 1password, 1password-cli, raycast, craft
- [x] docker-desktop
- [x] telegram, wechat, feishu, lark, bluebubbles
- [x] vlc, qbittorrent, zotero
- [x] appcleaner, shottr, sf-symbols, corelocationcli, typeless
- [x] google-chrome, bitwarden, wpsoffice, folo
- [x] font-maple-mono-nf-cn, font-symbols-only-nerd-font
- [x] font-ibm-plex-sans, font-inter, font-arvo, font-roboto, etc.
- [ ] termius

### Third-party taps (managed in homebrew.nix brews)

- [x] antoniorodr/memo/memo
- [x] benngarcia/tap/cwt
- [x] steipete/tap/* (gogcli, goplaces, imsg, peekaboo, remindctl, sag, summarize, wacli)
- [x] yakitrak/yakitrak/obsidian-cli

## Cutover Checklist

When all packages are in tags:

- [ ] Change `cleanup = "none"` → `cleanup = "zap"` in `nix/modules/darwin/homebrew.nix`
- [ ] Remove symlink sections from `install.sh` (now managed by home-manager)
- [ ] Simplify `install.sh` to Nix-only bootstrap
- [ ] Remove Brewfile (nix-darwin manages homebrew declaratively)

## Rollback

At any point, run `./install.sh` (without `nix`) to restore the pre-Nix Homebrew + symlink state.
