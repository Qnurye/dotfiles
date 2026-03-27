# Homebrew via nix-darwin Reference

## nix-darwin Homebrew Module

### `homebrew.taps` - Third-party repositories
```nix
homebrew.taps = [
  "user/repo"
];
```

### `homebrew.brews` - CLI formulae (only for packages not in nixpkgs)
```nix
homebrew.brews = [
  "package"
  "user/tap/formula"    # third-party tap formula
];
```

### `homebrew.casks` - GUI applications (injected from tags.nix)
Casks are declared in `nix/tags.nix` per tag and auto-resolved:
```nix
# In nix/tags.nix:
"apps/utils" = {
  packages = [];
  casks = [ "appcleaner" "shottr" ];
  deps = [];
};
```
The resolver collects all casks from active tags, and per-host config wires them:
```nix
# In nix/hosts/*/default.nix:
homebrew.casks = map (name: { name = name; }) resolved.casks;
```

### `homebrew.onActivation` - Lifecycle settings
```nix
homebrew.onActivation = {
  cleanup = "none";     # "none" | "uninstall" | "zap"
  autoUpdate = true;    # run `brew update` on activation
  upgrade = true;       # run `brew upgrade` on activation
};
```

## Current State

### Taps (in `homebrew.nix`)
```
antoniorodr/memo, benngarcia/tap, homebrew/services,
jakehilborn/jakehilborn, nektos/tap, steipete/tap, yakitrak/yakitrak
```

### Brews (in `homebrew.nix` -- not available in nixpkgs)
Third-party tap formulae:
```
antoniorodr/memo/memo, benngarcia/tap/cwt, steipete/tap/{gogcli,goplaces,imsg,peekaboo,remindctl,sag,summarize,wacli}, yakitrak/yakitrak/obsidian-cli
```
Homebrew-core (not in nixpkgs):
```
cagent, docker-agent, rtk
```

## Brewfile Syntax Reference (legacy, for context)

The legacy `homebrew/Brewfile` uses Ruby DSL. These options map to nix-darwin equivalents:

| Brewfile | nix-darwin |
|----------|------------|
| `tap "user/repo"` | `homebrew.taps = [ "user/repo" ];` |
| `brew "pkg"` | `homebrew.brews = [ "pkg" ];` |
| `cask "app"` | Add to tag's `casks` list in `nix/tags.nix` |
| `brew "pkg", restart_service: true` | Not directly supported; use launchd in nix-darwin |
| `mas "App", id: 123` | `homebrew.masApps = { "App" = 123; };` |
