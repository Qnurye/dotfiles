{ config, lib, pkgs, resolver, tagRegistry, ... }:

let
  resolved = resolver.resolveTags tagRegistry config.myConfig.tags;
in
{
  imports = [
    ../../modules/darwin
  ];

  # Host identity
  networking.hostName = "bowl-air";

  myConfig.username = "qnurye";

  # Tags for this machine
  myConfig.tags = [
    "shell/fish"
    "cli/tools"
    "dev/go"
    "dev/rust"
    "dev/node"
    "dev/python"
    "dev/deno"
    "fonts/base"
    "fonts/extra"
    "apps/editors"
    "apps/terminal"
    "apps/llm"
    "apps/productivity"
    "apps/dev"
    "apps/social"
    "apps/media"
    "apps/utils"
  ];

  # Wire resolved packages into system
  environment.systemPackages = resolved.packages;

  # Wire resolved casks into homebrew
  homebrew.casks = map (name: { name = name; }) resolved.casks;

  # Declare the primary user for nix-darwin activation and home-manager
  system.primaryUser = config.myConfig.username;
  users.users.${config.myConfig.username}.home = "/Users/${config.myConfig.username}";

  # home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.myConfig.username} = import ../../modules/home;
  };

  # System defaults
  system.stateVersion = 5;
}
