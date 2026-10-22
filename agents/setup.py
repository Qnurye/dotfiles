#!/usr/bin/env python3
"""Migrate agent skills and remove retired harness integrations."""

import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time


CANDIDATE_PLUGINS = {
    "context7@claude-plugins-official", "ralph-loop@claude-plugins-official",
    "feature-dev@claude-plugins-official", "superpowers@claude-plugins-official",
    "curl-md@curl-md", "gopls-lsp@claude-plugins-official",
    "typescript-lsp@claude-plugins-official", "skill-creator@claude-plugins-official",
    "obsidian@obsidian-skills", "cloudflare@cloudflare",
    "microsoft-docs@claude-plugins-official",
}
REMOVED_MARKETPLACES = {"cloudflare", "curl-md", "gvzdv-plugins", "obsidian-skills"}
RETIRED = {"codegraph", "context7"}


def guard_module(repo):
    spec = importlib.util.spec_from_file_location("link_guard", repo / "tools/symlink-guard/guard.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class Setup:
    def __init__(self, repo, home):
        self.repo, self.home = repo, home
        self.guard = guard_module(repo)
        self.archive = home / ".local/state/dotfiles-link-guard" / f"migration-{time.time_ns()}"
        self.manifest = json.loads((repo / "tools/symlink-guard/links.json").read_text())
        projects = set()
        registry = home / ".claude/plugins/installed_plugins.json"
        if registry.exists():
            for records in json.loads(registry.read_text()).get("plugins", {}).values():
                projects.update(Path(record["projectPath"]) for record in records if record.get("projectPath"))
        state = home / ".claude.json"
        if state.exists():
            projects.update(Path(path) for path in json.loads(state.read_text()).get("projects", {}))
        self.projects = projects
        active = set()
        for project in projects:
            for relative in [".claude/settings.json", ".claude/settings.local.json"]:
                settings = project / relative
                if settings.is_file():
                    plugins = json.loads(settings.read_text()).get("enabledPlugins", {})
                    active.update(name for name, enabled in plugins.items() if enabled)
        self.removed_plugins = (CANDIDATE_PLUGINS - active) | {"context7@claude-plugins-official"}
        self.removed_marketplaces = REMOVED_MARKETPLACES - {name.rsplit("@", 1)[-1] for name in active}

    def backup(self, path):
        self.archive.mkdir(parents=True, exist_ok=True, mode=0o700)
        relative = path.relative_to(self.home) if path.is_relative_to(self.home) else Path("external") / path.relative_to(path.anchor)
        destination = self.archive / relative
        if not os.path.lexists(destination):
            destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            self.guard.copy_path(path, destination)

    def write_json(self, path, data):
        if json.loads(path.read_text()) == data:
            return
        content = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode()
        if path.read_bytes() != content:
            self.backup(path)
            self.guard.atomic_write(path.resolve(), content, path.stat().st_mode & 0o777)

    def archive_path(self, path):
        if not os.path.lexists(path):
            return
        self.archive.mkdir(parents=True, exist_ok=True, mode=0o700)
        relative = path.relative_to(self.home) if path.is_relative_to(self.home) else Path("repository") / path.relative_to(self.repo)
        destination = self.archive / relative
        destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        shutil.move(str(path), destination)
        print(f"Archived {path}")

    def migrate_skills(self):
        shared = self.repo / "agents/skills"
        roots = [".claude/skills", ".codex/skills", ".agents/skills", ".gemini/skills"]
        owned = {".claude/skills": "synced", ".codex/skills": ".system"}
        for relative in roots:
            root = self.home / relative
            if root.is_symlink():
                previous = root.resolve()
                temporary = root.with_name(f"skills.migrating-{time.time_ns()}")
                temporary.mkdir(mode=0o700)
                if previous.is_dir():
                    for entry in previous.iterdir():
                        if entry.name in self.manifest["skills"] or entry.name == "view-plans":
                            continue
                        if entry.name in {".system", "synced", ".trash"} and entry.name != owned.get(relative):
                            continue
                        self.guard.copy_path(entry, temporary / entry.name)
                self.backup(root)
                root.unlink()
                os.replace(temporary, root)
            else:
                root.mkdir(parents=True, exist_ok=True, mode=0o700)
            name = owned.get(relative)
            if name and (shared / name).is_dir():
                target = root / name
                if not target.exists():
                    self.guard.copy_path(shared / name, target)
                elif target.resolve() != (shared / name).resolve():
                    # Native runtime content takes precedence on repeat installs.
                    shutil.copytree(shared / name, target, dirs_exist_ok=True,
                                    symlinks=True, copy_function=self.copy_missing)
            retired = root / "view-plans"
            if os.path.lexists(retired):
                self.archive_path(retired)

        for name in [".system", "synced", ".trash"]:
            source = shared / name
            if source.exists():
                self.archive_path(source)
        for relative in [".cursor/skills", ".config/opencode/skills", ".factory/skills",
                         ".pi/agent/skills", ".gemini/antigravity/global_skills"]:
            root = self.home / relative
            if root.is_dir():
                for entry in root.iterdir():
                    if entry.is_symlink() and not entry.exists():
                        self.archive_path(entry)

    @staticmethod
    def copy_missing(source, destination):
        if not Path(destination).exists():
            shutil.copy2(source, destination)
        return destination

    def clean_settings(self, data):
        for key in ["mcpServers", "mcp_servers"]:
            for name in list(data.get(key, {})):
                if name.lower() in RETIRED:
                    del data[key][name]
        for key in ["enabledMcpjsonServers", "disabledMcpServers"]:
            if key in data:
                data[key] = [v for v in data[key] if v.lower() not in RETIRED]
        for key in ["enabledPlugins", "plugins"]:
            for name in list(data.get(key, {})):
                if name in self.removed_plugins:
                    del data[key][name]
        for name in self.removed_marketplaces:
            data.get("extraKnownMarketplaces", {}).pop(name, None)
        for name in list(data.get("env", {})):
            if name.startswith("CLAUDISH_"):
                del data["env"][name]
        permissions = data.get("permissions", {})
        for key in ["allow", "ask", "deny"]:
            if key in permissions:
                permissions[key] = [value for value in permissions[key]
                                    if not re.search(r"mcp__(?:codegraph|context7)__", value, re.I)]
        for event, groups in list(data.get("hooks", {}).items()):
            kept = []
            for group in groups:
                group["hooks"] = [hook for hook in group.get("hooks", [])
                                  if not re.search(r"\bcodegraph\b", hook.get("command", ""))]
                for hook in group["hooks"]:
                    if hook.get("command", "").endswith("rtk-rewrite.sh"):
                        hook["command"] = "rtk hook claude"
                if group["hooks"]:
                    kept.append(group)
            data["hooks"][event] = kept
        return data

    def clean_integrations(self):
        path = self.home / ".claude.json"
        projects = list(self.projects)
        if path.exists():
            data = json.loads(path.read_text())
            self.clean_settings(data)
            for name, project in data.get("projects", {}).items():
                self.clean_settings(project)
                projects.append(Path(name))
            self.write_json(path, data)
        paths = [self.home / name for name in [".cursor/mcp.json", ".gemini/settings.json",
                                               ".claude/settings.json"]]
        for project in projects:
            paths.extend(project / name for name in [".mcp.json", ".claude/settings.json",
                                                     ".claude/settings.local.json"])
        for path in dict.fromkeys(paths):
            if path.is_file():
                self.write_json(path, self.clean_settings(json.loads(path.read_text())))
        for relative in [".claude/hooks/rtk-rewrite.sh", ".claude/hooks/.rtk-hook.sha256", ".codegraph"]:
            self.archive_path(self.home / relative)

    def prepare_codex_hooks(self):
        source = self.repo / "agents/codex-hooks.json"
        native = self.home / ".codex/hooks.json"
        if not source.exists() or not native.is_file() or native.resolve() == source.resolve():
            return
        data = json.loads(native.read_text())
        groups = data.setdefault("hooks", {}).setdefault("PreToolUse", [])
        command = "~/dotfiles/agents/hooks/block-destructive-git.sh"
        if not any(hook.get("command") == command for group in groups for hook in group.get("hooks", [])):
            groups.insert(0, {"matcher": "Bash", "hooks": [{"type": "command", "command": command, "timeout": 5}]})
        self.backup(native)
        content = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode()
        self.guard.atomic_write(source, content, source.stat().st_mode & 0o777)
        if not native.is_symlink():
            self.guard.atomic_write(native, content, native.stat().st_mode & 0o777)

    def uninstall_plugins(self):
        registry = self.home / ".claude/plugins/installed_plugins.json"
        if registry.exists():
            data = json.loads(registry.read_text())
            plugins = data.get("plugins", {})
            for name in self.removed_plugins:
                plugins.pop(name, None)
            self.write_json(registry, data)
        cache = self.home / ".claude/plugins/cache"
        for name in sorted(self.removed_plugins):
            plugin, marketplace = name.split("@", 1)
            self.archive_path(cache / marketplace / plugin)
            self.archive_path(self.home / ".claude/plugins/data" / name)
        marketplaces = self.home / ".claude/plugins/known_marketplaces.json"
        if marketplaces.exists():
            data = json.loads(marketplaces.read_text())
            for name in self.removed_marketplaces:
                data.pop(name, None)
                self.archive_path(self.home / ".claude/plugins/marketplaces" / name)
            self.write_json(marketplaces, data)

    def uninstall_codegraph(self):
        binary = shutil.which("codegraph")
        if binary:
            for relative in [".claude.json", ".cursor/mcp.json", ".codex/config.toml",
                             ".config/opencode/opencode.json", ".hermes/config.yaml"]:
                path = self.home / relative
                if path.is_file():
                    self.backup(path)
            subprocess.run([binary, "uninstall", "--yes", "--target", "all",
                            "--location", "global"], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--prepare-links-only", action="store_true")
    args = parser.parse_args()
    setup = Setup(args.repo.resolve(), args.home.resolve())
    setup.migrate_skills()
    setup.prepare_codex_hooks()
    if not args.prepare_links_only:
        setup.uninstall_codegraph()
        setup.clean_integrations()
        setup.uninstall_plugins()
    print(f"Migration complete; backups: {setup.archive}")


if __name__ == "__main__":
    main()
