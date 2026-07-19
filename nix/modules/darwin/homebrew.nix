{ config, lib, pkgs, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      # NOTE: Switch to "zap" after all desired packages are represented as tags.
      # "zap" will remove any cask/formula not declared here, making management fully declarative.
      # During migration, "none" prevents accidental removal of packages not yet in tags.
      cleanup = "none";
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "homebrew/services"
    ];

    # Casks and per-tag brews are injected from resolver output (hosts/default.nix).
    # Below: homebrew-core brews not in nixpkgs and not tag-specific:
    brews = [
      "cagent"
      "docker-agent"
      "rtk"
    ];
  };
}
