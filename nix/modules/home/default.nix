{ config, lib, pkgs, ... }:

{
  imports = [
    ./dotfiles.nix
  ];

  # Basic home-manager configuration
  home.username = "qnurye";
  home.homeDirectory = "/Users/qnurye";
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
