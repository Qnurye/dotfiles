{ pkgs }:

{
  # ── Foundation ──────────────────────────────────────────────
  "base" = {
    packages = with pkgs; [ git curl wget jq gnupg coreutils nix-output-monitor ];
    casks = [];
    deps = [];
  };

  # ── Shell ───────────────────────────────────────────────────
  "shell/fish" = {
    packages = [ pkgs.fish ];  # TODO: fisher is not in nixpkgs (installed via fish plugin manager)
    casks = [];
    deps = [ "base" ];
  };

  # ── CLI Tools ───────────────────────────────────────────────
  "cli/tools" = {
    packages = with pkgs; [
      aria2
      bat fd fzf ripgrep yazi neovim tmux eza zoxide tree
      (direnv.overrideAttrs (old: { env = (old.env or {}) // { CGO_ENABLED = 1; }; })) git-lfs delta difftastic
      worktrunk pinentry_mac
      # Structured-data & code-mod toolbelt — see ~/.claude/CLAUDE.md "Preferred CLI Tools"
      yq-go jd-diff-patch dasel ast-grep sd gron
      hyperfine tokei git-absorb
    ];
    casks = [];
    # Fast-moving tools: nixpkgs stable lags — track latest via brew
    brews = [ "lazygit" "jj" ];
    deps = [ "base" ];
  };

  "cli/ci" = {
    packages = with pkgs; [ act actionlint ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "cli/media" = {
    packages = with pkgs; [
      ffmpeg imagemagick atomicparsley jpegoptim
      oxipng pngquant resvg woff2 zopfli
      python3Packages.fonttools
    ];
    casks = [];
    deps = [];
  };

  "cli/net" = {
    packages = with pkgs; [ cloudflared mosh nmap tailscale xh ];
    casks = [];
    deps = [];
  };

  "cli/ai" = {
    packages = [];
    casks = [];
    brews = [ "llama.cpp" ];
    deps = [];
  };

  "cli/data" = {
    packages = with pkgs; [ duckdb pandoc poppler typst qpdf miller ];
    casks = [];
    deps = [];
  };

  "cli/mail" = {
    packages = with pkgs; [ himalaya signal-cli ];
    casks = [];
    deps = [];
  };

  "cli/misc" = {
    packages = with pkgs; [ convmv duti unar watch zstd p7zip ttyd ];
    casks = [];
    deps = [];
  };

  # ── Development: Base ───────────────────────────────────────
  "dev/base" = {
    packages = with pkgs; [ gh nil nixd ];
    casks = [];
    deps = [ "base" "cli/tools" ];
  };

  "dev/go" = {
    packages = with pkgs; [ go gopls gotools go-tools ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/rust" = {
    packages = with pkgs; [ rustup rust-analyzer ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/node" = {
    packages = [ pkgs.fnm ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/python" = {
    packages = with pkgs; [ python3 poetry ];
    casks = [];
    brews = [ "uv" "ruff" ];
    deps = [ "dev/base" ];
  };

  "dev/deno" = {
    packages = [];
    casks = [];
    brews = [ "deno" ];
    deps = [ "dev/base" ];
  };

  "dev/c" = {
    packages = with pkgs; [ automake clang-tools libtool pkgconf libev libpq ];
    casks = [];
    deps = [ "dev/base" ];
  };

  "dev/k8s" = {
    packages = [ pkgs.kubectl ];
    casks = [];
    deps = [ "dev/base" ];
  };

  # ── Fonts ───────────────────────────────────────────────────
  "fonts/base" = {
    packages = [];
    casks = [
      "font-commit-mono"
      "font-commit-mono-nerd-font"
      "font-ioskeley-mono"
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
    packages = [];
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
    casks = [ "gitbutler" "tower" ];
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
      "typeless" "google-chrome" "bitwarden" "folo"
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
    packages = [ pkgs.doctl ];
    casks = [ "gcloud-cli" ];
    deps = [ "work/base" ];
  };
}
