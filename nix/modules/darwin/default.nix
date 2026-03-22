{ config, lib, pkgs, ... }:

{
  imports = [
    ./homebrew.nix
  ];

  # Let Determinate Nix manage the daemon; avoid conflicts with nix-darwin
  nix.enable = false;

  # Common darwin settings
  programs.fish.enable = true;

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;
}
