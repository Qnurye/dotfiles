{ config, lib, pkgs, resolver, ... }:

let
  tagRegistry = import ../tags.nix { inherit pkgs; };
  resolved = resolver.resolveTags tagRegistry config.myConfig.tags;
in
{
  imports = [
    ../modules/darwin
  ];

  options.myConfig = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user account name.";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tag names to install on this host.";
    };
  };

  config = {
    nixpkgs.hostPlatform = "aarch64-darwin";

    environment.systemPackages = resolved.packages;
    homebrew.casks = map (name: { inherit name; }) resolved.casks;
    homebrew.brews = resolved.brews;

    system.primaryUser = config.myConfig.username;
    users.users.${config.myConfig.username}.home = "/Users/${config.myConfig.username}";

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${config.myConfig.username} = import ../modules/home;
    };

    system.stateVersion = 5;
  };
}
