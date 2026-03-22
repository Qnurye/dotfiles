{ config, lib, pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  # Common darwin settings
  programs.fish.enable = true;

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;
}
