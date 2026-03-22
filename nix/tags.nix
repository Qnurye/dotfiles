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
    ];
    casks = [];
    deps = [ "base" ];
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
    packages = [ rustup ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/node" = {
    packages = [ fnm ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/python" = {
    packages = [ python3 uv ruff ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/deno" = {
    packages = [ deno ];
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
    packages = [];
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
