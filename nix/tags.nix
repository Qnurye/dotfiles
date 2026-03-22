{ pkgs }:

with pkgs; {
  # ── Foundation ──────────────────────────────────────────────
  "base" = {
    packages = [ git curl wget jq gnupg coreutils ];
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
      bat fd fzf ripgrep yazi neovim tmux eza zoxide tree
      lazygit direnv git-lfs delta difftastic
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

  "cli/data" = {
    packages = [ duckdb pandoc poppler typst ];
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
      "font-maple-mono-nf-cn"
      "font-symbols-only-nerd-font"
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
    casks = [ "claude" "claude-code" "codex" ];
    deps = [];
  };

  "apps/productivity" = {
    packages = [];
    casks = [ "obsidian" "1password" "1password-cli" "raycast" "craft" ];
    deps = [];
  };

  "apps/dev" = {
    packages = [];
    casks = [ "docker-desktop" ];
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
    ];
    deps = [];
  };

  # ── Work ────────────────────────────────────────────────────
  "work/base" = {
    packages = [];
    casks = [];
    deps = [ "dev/base" "apps/editors" ];
  };
}
