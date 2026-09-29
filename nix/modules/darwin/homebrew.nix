{ config, lib, pkgs, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      # NOTE: Switch to "zap" after all desired packages are represented as tags.
      # "zap" will remove any cask/formula not declared here, making management fully declarative.
      # During migration, "none" prevents accidental removal of packages not yet in tags.
      cleanup = "none";
      # Casks are install-only: GUI apps self-update, and brew's Caskroom version
      # goes stale after they do, so upgrading here re-downloads apps already current.
      # Formulae, fonts and casks without their own updater go through `brew-up`.
      autoUpdate = false;
      upgrade = false;
    };

    taps = [
      "homebrew/services"
    ];

    # Casks and per-tag brews are injected from resolver output (hosts/default.nix).
    # Below: homebrew-core brews not in nixpkgs and not tag-specific:
    brews = [
      "mas"
      "rtk"
    ];

    masApps = {
      Shadowrocket = 932747118;
    };
  };
}
