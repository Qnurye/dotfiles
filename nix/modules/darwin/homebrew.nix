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
      "antoniorodr/memo"
      "homebrew/services"
      "jakehilborn/jakehilborn"
      "lucasgelfond/zerobrew"
      "nektos/tap"
      "yakitrak/yakitrak"
    ];

    # Casks are injected by the darwin module from resolver output.
    # Additional brews from third-party taps that aren't in nixpkgs:
    brews = [
      # Third-party taps
      "antoniorodr/memo/memo"
      "lucasgelfond/zerobrew/zerobrew"
      "yakitrak/yakitrak/obsidian-cli"
      # Homebrew-core (not in nixpkgs)
      "cagent"
      "docker-agent"
      "rtk"
    ];
  };
}
