{ config, lib, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
  mkLink = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    force = true;
  };
in
{
  home.file = lib.mkMerge [
    {
      # Fish shell
      ".config/fish/config.fish" = mkLink "shells/fish/config.fish";
      ".config/fish/conf.d/dotfiles_sync.fish" = mkLink "shells/fish/conf.d/dotfiles_sync.fish";
      ".config/fish/conf.d/tide_one_dark.fish" = mkLink "shells/fish/conf.d/tide_one_dark.fish";
      ".config/fish/functions/brew.fish" = mkLink "shells/fish/functions/brew.fish";
      ".config/fish/functions/nix-add.fish" = mkLink "shells/fish/functions/nix-add.fish";
      ".config/fish/functions/nix-up.fish" = mkLink "shells/fish/functions/nix-up.fish";
      ".config/fish/functions/wt.fish" = mkLink "shells/fish/functions/wt.fish";
      ".config/fish/functions/y.fish" = mkLink "shells/fish/functions/y.fish";
      ".config/fish/completions/deno.fish" = mkLink "shells/fish/completions/deno.fish";
      ".config/fish/completions/wt.fish" = mkLink "shells/fish/completions/wt.fish";
      ".config/fish/fish_plugins" = mkLink "shells/fish/fish_plugins";

      # Editors
      ".config/zed/settings.json" = mkLink "editors/zed/settings.json";

      # Terminals
      ".config/ghostty/config" = mkLink "terminals/ghostty/config";
      ".tmux.conf.local" = mkLink "terminals/tmux/.tmux.conf.local";

      # VCS - Git
      ".gitconfig" = mkLink "vcs/git/.gitconfig";
      ".gitignore_global" = mkLink "vcs/git/.gitignore_global";
      ".work.gitconfig" = mkLink "vcs/git/.work.gitconfig";

      # Tools
      ".config/worktrunk/config.toml" = mkLink "tools/worktrunk/config.toml";

      # Claude Code - Agents
      ".claude/agents/diverge-devils-advocate.md" = mkLink "agents/agents/diverge-devils-advocate.md";
      ".claude/agents/diverge-implementer.md" = mkLink "agents/agents/diverge-implementer.md";
      ".claude/agents/diverge-plan-writer.md" = mkLink "agents/agents/diverge-plan-writer.md";
      ".claude/agents/diverge-spec-auditor.md" = mkLink "agents/agents/diverge-spec-auditor.md";
      ".claude/agents/diverge-tdd-devils-advocate.md" = mkLink "agents/agents/diverge-tdd-devils-advocate.md";
      ".claude/agents/diverge-tdd-implementer.md" = mkLink "agents/agents/diverge-tdd-implementer.md";
      ".claude/agents/diverge-tdd-writer.md" = mkLink "agents/agents/diverge-tdd-writer.md";

      # Claude Code - Skills
      ".claude/skills/copywriting/SKILL.md" = mkLink "agents/skills/copywriting/SKILL.md";
      ".claude/skills/diverge/SKILL.md" = mkLink "agents/skills/diverge/SKILL.md";
      ".claude/skills/diverge/PROTOCOL.md" = mkLink "agents/skills/diverge/PROTOCOL.md";
      ".claude/skills/diverge/scripts/diverge-consolidate.sh" = mkLink "agents/skills/diverge/scripts/diverge-consolidate.sh";
      ".claude/skills/diverge/scripts/diverge-copy-da-tests.sh" = mkLink "agents/skills/diverge/scripts/diverge-copy-da-tests.sh";
      ".claude/skills/diverge/scripts/diverge-merge-into-da.sh" = mkLink "agents/skills/diverge/scripts/diverge-merge-into-da.sh";
      ".claude/skills/diverge/scripts/diverge-wip-commit.sh" = mkLink "agents/skills/diverge/scripts/diverge-wip-commit.sh";
      ".claude/skills/diverge/scripts/diverge-wt-create.sh" = mkLink "agents/skills/diverge/scripts/diverge-wt-create.sh";
      ".claude/skills/diverge/scripts/gather-context.sh" = mkLink "agents/skills/diverge/scripts/gather-context.sh";
      ".claude/skills/diverge/scripts/generate-launcher.sh" = mkLink "agents/skills/diverge/scripts/generate-launcher.sh";
      ".claude/skills/diverge/scripts/migrate-sessions.sh" = mkLink "agents/skills/diverge/scripts/migrate-sessions.sh";
      ".claude/skills/pr/SKILL.md" = mkLink "agents/skills/pr/SKILL.md";
      ".claude/skills/view-plans/SKILL.md" = mkLink "agents/skills/view-plans/SKILL.md";
      ".claude/skills/view-plans/serve.ts" = mkLink "agents/skills/view-plans/serve.ts";
      ".claude/skills/view-plans/template.html" = mkLink "agents/skills/view-plans/template.html";
    }

    # macOS-specific paths
    (lib.mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/lazygit/config.yml" = mkLink "vcs/lazygit/config.yml";
    })
  ];
}
