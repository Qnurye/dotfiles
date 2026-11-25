{
  description = "Qnurye's dotfiles — nix-darwin + home-manager";

  inputs = {
    # Stable release pair — small update deltas instead of unstable's
    # world-rebuilds. Fast-moving tools are managed via homebrew instead.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agent skills, linked into every skill root by modules/home/pstack.nix.
    pstack = {
      url = "github:backnotprop/pstack";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, pstack, ... }:
    let
      resolver = import ./lib { lib = nixpkgs.lib; };

      # Single nixpkgs instantiation: hosts set nixpkgs.hostPlatform and the
      # tag registry is built from the module system's own pkgs.
      mkDarwinHost = hostname: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit resolver pstack; };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/default.nix
          ./hosts/${hostname}
        ];
      };
    in
    {
      darwinConfigurations = {
        "bowl-air" = mkDarwinHost "bowl-air";
        "heavybowl-ii" = mkDarwinHost "heavybowl-ii";
      };

      # Expose resolver for external use/testing
      lib = { inherit resolver; };
    };
}
