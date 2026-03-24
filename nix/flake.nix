{
  description = "Qnurye's dotfiles — nix-darwin + home-manager";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixpkgs-unstable&shallow=1";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      lib = nixpkgs.lib;
      resolver = import ./lib { inherit lib; };
      tagRegistry = import ./tags.nix { inherit pkgs; };

      # Helper to create a darwin configuration for a given hostname
      mkDarwinHost = hostname: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit resolver tagRegistry; };
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/default.nix
          ./hosts/${hostname}/default.nix
        ];
      };

      # Helper to create a standalone home-manager configuration (Linux)
      mkHomeConfig = username: system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        extraSpecialArgs = { inherit resolver tagRegistry; };
        modules = [
          ./hosts/default.nix
          ./modules/home
        ];
      };
    in
    {
      darwinConfigurations = {
        "bowl-air" = mkDarwinHost "bowl-air";
        "heavybowl-ii" = mkDarwinHost "heavybowl-ii";
      };

      # Linux home-manager configs can be added here:
      # homeConfigurations = {
      #   "user@hostname" = mkHomeConfig "user" "x86_64-linux";
      # };

      # Expose lib for external use/testing
      lib = { inherit resolver tagRegistry; };
    };
}
