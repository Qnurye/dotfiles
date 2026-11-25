{ lib, pstack, ... }:

let
  manifest = builtins.fromJSON (builtins.readFile ../../../tools/symlink-guard/links.json);
  names = lib.attrNames (lib.filterAttrs (_: type: type == "directory")
    (builtins.readDir "${pstack}/skills"));
  collisions = lib.intersectLists names manifest.skills;
in
{
  assertions = [{
    assertion = collisions == [];
    message = "pstack skills collide with agents/skills: ${toString collisions}";
  }];

  home.file = builtins.listToAttrs (lib.concatMap (root:
    map (name: lib.nameValuePair "${root}/${name}" {
      source = "${pstack}/skills/${name}";
      force = true;
    }) names
  ) manifest.skillRoots);
}
