{ config, lib, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  mkLink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    force = true;
  };
in
{
  home.file = lib.mkMerge [
    {
      # Fish shell (dir symlink — new files auto-appear)
      ".config/fish" = mkLink "shells/fish";

      # Editors
      ".config/zed/settings.json" = mkLink "editors/zed/settings.json";

      # Terminals
      ".config/ghostty/config" = mkLink "terminals/ghostty/config";
      ".config/otty/config.toml" = mkLink "terminals/otty/config.toml";
      ".tmux.conf.local" = mkLink "terminals/tmux/.tmux.conf.local";

      # VCS - Git
      ".gitconfig" = mkLink "vcs/git/.gitconfig";
      ".gitignore_global" = mkLink "vcs/git/.gitignore_global";
      ".work.gitconfig" = mkLink "vcs/git/.work.gitconfig";

      # Tools
      ".config/worktrunk/config.toml" = mkLink "tools/worktrunk/config.toml";

      # Claude Code - Agents (dir symlink)
      ".claude/agents" = mkLink "agents/agents";

      # Claude Code - Skills (dir symlink)
      ".claude/skills" = mkLink "agents/skills";
    }

    # macOS-specific paths
    (lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/lazygit/config.yml" = mkLink "vcs/lazygit/config.yml";
    })
  ];
}
