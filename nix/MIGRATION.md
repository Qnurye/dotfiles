# Nix Migration Tracker

## Hosts

| Host | Type | Hostname | Status | Target Date |
|------|------|----------|--------|-------------|
| Personal Mac (Air) | nix-darwin | `bowl-air` | ✅ All tags active | 2026-03-23 |
| Work Mac | nix-darwin | `heavybowl-ii` | ✅ All tags active | 2026-03-23 |

## Migration Steps (per host)

### 1. Bootstrap Nix

```bash
./install.sh nix
```

- [x] bowl-air (2026-03-23)
- [x] heavybowl-ii (2026-03-23)

### 2. Verify coexistence

After `darwin-rebuild switch`, confirm:

- [x] Nix-managed packages available in `$PATH` (bowl-air, heavybowl-ii)
- [x] Homebrew packages still intact (cleanup=none) (bowl-air, heavybowl-ii)
- [x] Dotfile symlinks correct — home-manager manages all (bowl-air, heavybowl-ii)
- [x] Fish shell works normally (bowl-air, heavybowl-ii)
- [x] GPG signing works (bowl-air, heavybowl-ii)

### 3. Verify work mac

- [x] Run `./install.sh nix` on heavybowl-ii (2026-03-23)
- [x] Confirm work-specific tags resolve correctly (2026-03-23)
- [x] Adjust tag list in `nix/hosts/heavybowl-ii/default.nix` as needed (2026-03-23)

## Tag Coverage

Packages in tags vs Brewfile. Checked = in a tag, unchecked = not yet migrated.

### CLI (brew)

- [x] bat, fd, fzf, ripgrep, yazi, neovim, tmux, eza, zoxide, tree
- [x] git, curl, wget, jq, gnupg, coreutils
- [x] lazygit, direnv, git-lfs, delta, difftastic, worktrunk, pinentry_mac
- [x] gh, go, gopls, gotools, go-tools (staticcheck)
- [x] rustup, rust-analyzer, fnm, deno, python3, uv, ruff, poetry
- [x] fish
- [x] act, actionlint
- [x] ffmpeg, imagemagick, atomicparsley, jpegoptim, oxipng, pngquant, resvg, woff2, zopfli, fonttools
- [x] cloudflared, mosh, nmap, tailscale
- [x] duckdb, pandoc, poppler, typst, qpdf
- [x] llama-cpp (nixpkgs), doctl (nixpkgs)
- [x] himalaya, signal-cli
- [x] convmv, duti, unar, watch, zstd, p7zip, ttyd
- [x] automake, clang-tools, libtool, pkgconf, libev, libpq
- [x] kubectl, docker, docker-compose
- [x] ollama

Not in nixpkgs (stay in homebrew, declared in homebrew.nix brews):
- [x] cagent, docker-agent, rtk
- [ ] displayplacer, marked, neonctl, fisher
- [ ] gemini-cli

Skipped (redundant or wrong match):
- hub-tool (Docker Hub CLI, not in nixpkgs)
- vc (wrong package match)
- python@3.12, python@3.9 (covered by python3)
- ffmpeg-full, imagemagick-full (covered by ffmpeg, imagemagick)

### Casks

- [x] ghostty, zed, claude, claude-code, codex, codex-app
- [x] obsidian, 1password, 1password-cli, raycast, craft
- [x] docker-desktop, gitbutler, tower
- [x] telegram, wechat, feishu, lark, bluebubbles
- [x] vlc, qbittorrent, zotero
- [x] appcleaner, shottr, sf-symbols, corelocationcli, typeless
- [x] google-chrome, bitwarden, wpsoffice, folo, linearmouse, piclist, raindropio
- [x] font-maple-mono-nf-cn, font-symbols-only-nerd-font
- [x] font-ibm-plex-sans, font-inter, font-arvo, font-roboto, etc.
- [ ] termius
- [x] gcloud-cli

### Third-party taps (managed in homebrew.nix brews)

- [x] antoniorodr/memo/memo
- [x] benngarcia/tap/cwt
- [x] steipete/tap/* (gogcli, goplaces, imsg, peekaboo, remindctl, sag, summarize, wacli)
- [x] yakitrak/yakitrak/obsidian-cli

## Residuals to Clean Up

Packages installed on heavybowl-ii that are likely no longer needed:

- [x] `autojump` — replaced by zoxide (2026-03-23)
- [x] `zsh-autosuggestions` — using Fish, not Zsh (2026-03-23)
- [x] `zsh-syntax-highlighting` — using Fish, not Zsh (2026-03-23)
- [x] `ffmpeg-full` — redundant with ffmpeg (2026-03-23)
- [x] `imagemagick-full` — redundant with imagemagick (2026-03-23)
- [x] `hub-tool` — Docker Hub CLI, rarely used (2026-03-23)
- [x] `python@3.12`, `python@3.9` — covered by python3 (2026-03-23)
- [x] `vc` — wrong package match (2026-03-23)

Also auto-removed: 56 orphaned dependencies (llama.cpp, whisper-cpp, tesseract, etc.).

## Cutover Checklist

When all packages are in tags:

- [ ] Change `cleanup = "none"` → `cleanup = "zap"` in `nix/modules/darwin/homebrew.nix`
- [ ] Remove symlink sections from `install.sh` (now managed by home-manager)
- [ ] Simplify `install.sh` to Nix-only bootstrap
- [ ] Remove Brewfile (nix-darwin manages homebrew declaratively)

## Rollback

At any point, run `./install.sh` (without `nix`) to restore the pre-Nix Homebrew + symlink state.
