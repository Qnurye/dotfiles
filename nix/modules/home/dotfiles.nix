{ config, lib, pkgs, ... }:

{
  home.file = lib.mkMerge [
    {
      # Fish shell
      ".config/fish/config.fish" = {
        source = ../../../shells/fish/config.fish;
        force = true;
      };
      ".config/fish/conf.d" = {
        source = ../../../shells/fish/conf.d;
        force = true;
        recursive = true;
      };
      ".config/fish/functions" = {
        source = ../../../shells/fish/functions;
        force = true;
        recursive = true;
      };
      ".config/fish/completions" = {
        source = ../../../shells/fish/completions;
        force = true;
        recursive = true;
      };
      ".config/fish/fish_plugins" = {
        source = ../../../shells/fish/fish_plugins;
        force = true;
      };

      # Editors
      ".config/zed/settings.json" = {
        source = ../../../editors/zed/settings.json;
        force = true;
      };

      # Terminals
      ".config/ghostty/config" = {
        source = ../../../terminals/ghostty/config;
        force = true;
      };
      ".tmux.conf.local" = {
        source = ../../../terminals/tmux/.tmux.conf.local;
        force = true;
      };

      # VCS - Git
      ".gitconfig" = {
        source = ../../../vcs/git/.gitconfig;
        force = true;
      };
      ".gitignore_global" = {
        source = ../../../vcs/git/.gitignore_global;
        force = true;
      };
      ".work.gitconfig" = {
        source = ../../../vcs/git/.work.gitconfig;
        force = true;
      };

      # Tools
      ".config/worktrunk/config.toml" = {
        source = ../../../tools/worktrunk/config.toml;
        force = true;
      };
    }

    # macOS-specific paths
    (lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/lazygit/config.yml" = {
        source = ../../../vcs/lazygit/config.yml;
        force = true;
      };
    })
  ];
}
