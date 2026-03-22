{ config, lib, pkgs, resolver, tagRegistry, ... }:

let
  resolved = resolver.resolveTags tagRegistry config.myConfig.tags;
in
{
  imports = [
    ../../modules/darwin
  ];

  # Host identity
  networking.hostName = "heavybowl-ii";

  myConfig.username = "qnurye";

  # Tags for this machine
  myConfig.tags = [
    "work/base"
    "shell/fish"
    "dev/go"
    "dev/rust"
    "dev/node"
    "dev/python"
    "dev/deno"
    "fonts/base"
    "fonts/extra"
    "apps/terminal"
    "apps/llm"
    "apps/productivity"
    "apps/dev"
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
