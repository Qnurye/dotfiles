{ pkgs }:

with pkgs; {
  # ── Foundation ──────────────────────────────────────────────
  "base" = {
    packages = [ git curl wget jq gnupg coreutils nix-output-monitor ];
    casks = [];
    deps = [];
  };

  # ── Shell ───────────────────────────────────────────────────
  "shell/fish" = {
    packages = [ fish ];  # TODO: fisher is not in nixpkgs (installed via fish plugin manager)
    casks = [];
    deps = [ "base" ];
  };

  # ── CLI Tools ───────────────────────────────────────────────
  "cli/tools" = {
    packages = [
      aria2
      bat fd fzf ripgrep yazi neovim tmux eza zoxide tree
      lazygit (direnv.overrideAttrs (old: { env = (old.env or {}) // { CGO_ENABLED = 1; }; })) git-lfs delta difftastic jujutsu
      worktrunk pinentry_mac
    ];
    casks = [];
    deps = [ "base" ];
  };

  "cli/ci" = {
    packages = [ act actionlint ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "cli/media" = {
    packages = [
      ffmpeg imagemagick atomicparsley jpegoptim
      oxipng pngquant resvg woff2 zopfli
      python3Packages.fonttools
    ];
    casks = [];
    deps = [];
  };

  "cli/net" = {
    packages = [ cloudflared mosh nmap tailscale ];
    casks = [];
    deps = [];
  };

  "cli/ai" = {
    packages = [ llama-cpp ];
    casks = [];
    deps = [];
  };

  "cli/data" = {
    packages = [ duckdb pandoc poppler typst qpdf ];
    casks = [];
    deps = [];
  };

  "cli/mail" = {
    packages = [ himalaya signal-cli ];
    casks = [];
    deps = [];
  };

  "cli/misc" = {
    packages = [ convmv duti unar watch zstd p7zip ttyd ];
    casks = [];
    deps = [];
  };

  # ── Development: Base ───────────────────────────────────────
  "dev/base" = {
    packages = [ gh ];
    casks = [];
    deps = [ "base" "cli/tools" ];
  };

  "dev/go" = {
    packages = [ go gopls gotools go-tools ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/rust" = {
    packages = [ rustup rust-analyzer ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/node" = {
    packages = [ fnm ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/python" = {
    packages = [ python3 uv ruff poetry ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/deno" = {
    packages = [ deno ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/c" = {
    packages = [ automake clang-tools libtool pkgconf libev libpq ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/k8s" = {
    packages = [ kubectl ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/docker" = {
    packages = [ docker docker-compose ];
    casks = [];
    deps = [ "dev/base" ];
  };

  # ── Fonts ───────────────────────────────────────────────────
  "fonts/base" = {
    packages = [];
    casks = [
      "font-commit-mono"
      "font-commit-mono-nerd-font"
      "font-maple-mono-nf-cn"
      "font-symbols-only-nerd-font"
      "font-ibm-plex-mono"
    ];
    deps = [];
  };

  "fonts/extra" = {
    packages = [];
    casks = [
      "font-ibm-plex-sans"
      "font-ibm-plex-sans-sc"
      "font-inter"
      "font-arvo"
      "font-baskervville"
      "font-crimson-pro"
      "font-eb-garamond"
      "font-genryumin"
      "font-lxgw-neoxihei"
      "font-lxgw-neozhisong"
      "font-merriweather"
      "font-nunito"
      "font-nunito-sans"
      "font-roboto"
      "font-sf-pro"
    ];
    deps = [ "fonts/base" ];
  };

  # ── Apps ────────────────────────────────────────────────────
  "apps/editors" = {
    packages = [];
    casks = [ "zed" ];
    deps = [ "cli/tools" ];
  };

  "apps/terminal" = {
    packages = [];
    casks = [ "ghostty" ];
    deps = [];
  };

  "apps/llm" = {
    packages = [ ollama ];
    casks = [ "claude" "claude-code@latest" "codex" "codex-app" ];
    deps = [];
  };

  "apps/productivity" = {
    packages = [];
    casks = [ "obsidian" "1password" "1password-cli" "raycast" "craft" ];
    deps = [];
  };

  "apps/dev" = {
    packages = [];
    casks = [ "docker-desktop" "gitbutler" "tower" ];
    deps = [ "dev/base" ];
  };

  "apps/social" = {
    packages = [];
    casks = [ "telegram" "wechat" "feishu" "lark" "bluebubbles" ];
    deps = [];
  };

  "apps/media" = {
    packages = [];
    casks = [ "vlc" "qbittorrent" "zotero" ];
    deps = [];
  };

  "apps/utils" = {
    packages = [];
    casks = [
      "appcleaner" "shottr" "sf-symbols" "corelocationcli"
      "typeless" "google-chrome" "bitwarden" "wpsoffice" "folo"
      "linearmouse" "piclist" "raindropio"
    ];
    deps = [];
  };

  # ── Work ────────────────────────────────────────────────────
  "work/base" = {
    packages = [];
    casks = [];
    deps = [ "dev/base" "apps/editors" ];
  };

  "work/cloud" = {
    packages = [ doctl ];
    casks = [ "gcloud-cli" ];
    deps = [ "work/base" ];
  };
}
