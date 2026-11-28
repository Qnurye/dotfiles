{ config, lib, pkgs, ... }:

let
  local = "${config.home.homeDirectory}/dotfiles/agents/pstack";
  manifest = builtins.fromJSON (builtins.readFile ../../../tools/symlink-guard/links.json);
  names = lib.attrNames (lib.filterAttrs (_: type: type == "directory")
    (builtins.readDir ../../../agents/pstack/skills));
  collisions = lib.intersectLists names manifest.skills;
in
{
  assertions = [{
    assertion = collisions == [];
    message = "pstack skills collide with agents/skills: ${toString collisions}";
  }];

  home.file = builtins.listToAttrs (lib.concatMap (root:
    map (name: lib.nameValuePair "${root}/${name}" {
      source = config.lib.file.mkOutOfStoreSymlink "${local}/skills/${name}";
      force = true;
    }) names
  ) manifest.skillRoots);
  launchd.agents.pstack-upstream = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "es.qnury.pstack-upstream";
      ProgramArguments = [ "/bin/sh" "${local}/check-upstream.sh" "--notify" ];
      RunAtLoad = true;
      StartInterval = 86400;
      ProcessType = "Background";
    };
  };
}
