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
      "benngarcia/tap"
      "homebrew/services"
      "jakehilborn/jakehilborn"
      "nektos/tap"
      "steipete/tap"
      "yakitrak/yakitrak"
    ];

    # Casks are injected by the darwin module from resolver output.
    # Additional brews from third-party taps that aren't in nixpkgs:
    brews = [
      # Third-party taps
      "antoniorodr/memo/memo"
      "benngarcia/tap/cwt"
      "steipete/tap/gogcli"
      "steipete/tap/goplaces"
      "steipete/tap/imsg"
      "steipete/tap/peekaboo"
      "steipete/tap/remindctl"
      "steipete/tap/sag"
      "steipete/tap/summarize"
      "steipete/tap/wacli"
      "yakitrak/yakitrak/obsidian-cli"
      # Homebrew-core (not in nixpkgs)
      "cagent"
      "docker-agent"
      "rtk"
    ];
  };
}
