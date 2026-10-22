{ config, lib, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  manifest = builtins.fromJSON (builtins.readFile ../../../tools/symlink-guard/links.json);
  skillLinks = builtins.listToAttrs (lib.concatMap (root:
    map (name: lib.nameValuePair "${root}/${name}" "agents/skills/${name}") manifest.skills
  ) manifest.skillRoots);
  links = manifest.links // skillLinks;
  stateDir = "${config.home.homeDirectory}/.local/state/dotfiles-link-guard";
  mkLink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    force = true;
  };
in
{
  home.file = lib.mapAttrs (_: path: mkLink path) links;

  # Detach old directory links before checking per-skill targets; otherwise
  # creating those links would mutate the repository through their parent.
  home.activation.prepareAgentSkills = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    run ${pkgs.python3}/bin/python3 ${lib.escapeShellArg "${dotfilesDir}/agents/setup.py"} --prepare-links-only
    run mkdir -p ${lib.escapeShellArg stateDir}
  '';

  launchd.agents.dotfiles-link-guard = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "es.qnury.dotfiles-link-guard";
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${dotfilesDir}/tools/symlink-guard/guard.py"
        "watch" "--repo" dotfilesDir "--home" config.home.homeDirectory
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      ThrottleInterval = 5;
      EnvironmentVariables.DOTFILES_LINK_GUARD_REVISION =
        builtins.hashFile "sha256" ../../../tools/symlink-guard/guard.py
        + builtins.hashFile "sha256" ../../../tools/symlink-guard/links.json;
      StandardOutPath = "${stateDir}/stdout.log";
      StandardErrorPath = "${stateDir}/stderr.log";
    };
  };
}
