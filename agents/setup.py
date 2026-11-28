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
import tomllib


CODEX_MARKETS = {"openai-bundled", "openai-primary-runtime", "openai-curated-remote"}


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

    def allowed_plugins(self, client):
        path = self.repo / "agents/policies" / (client + ".json")
        names = json.loads(path.read_text())
        if not isinstance(names, list) or not all(isinstance(name, str) and name for name in names):
            raise ValueError(f"Invalid plugin list in {path}")
        return set(names)

    def plugin_switches(self, client):
        path = self.repo / "agents/plugin-states" / (client + ".json")
        if not path.exists():
            return {}
        states = json.loads(path.read_text())
        if not isinstance(states, dict) or not all(type(value) is bool for value in states.values()):
            raise ValueError(f"Invalid plugin switches in {path}")
        return states

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
        for name in list(data.get("env", {})):
            if name.startswith("CLAUDISH_"):
                del data["env"][name]
        permissions = data.get("permissions", {})
        for key in ["allow", "ask", "deny"]:
            if key in permissions:
                permissions[key] = [value for value in permissions[key]
                                    if not re.search(r"mcp__(?:codegraph|context7)__", value, re.I)]
        self.remove_retired_hooks(data, lambda cmd: re.search(r"\bcodegraph\b", cmd)
                                  or cmd.endswith(("/rtk-rewrite.sh", "/block-destructive-git.sh"))
                                  or cmd == "rtk hook claude")
        return data

    @staticmethod
    def remove_retired_hooks(data, retired):
        for event, groups in list(data.get("hooks", {}).items()):
            kept = []
            for group in groups:
                group["hooks"] = [hook for hook in group.get("hooks", [])
                                  if not retired(hook.get("command", ""))]
                if group["hooks"]:
                    kept.append(group)
            if kept:
                data["hooks"][event] = kept
            else:
                del data["hooks"][event]

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
        self.remove_retired_hooks(data, lambda cmd: cmd.endswith("/block-destructive-git.sh")
                                  or cmd.rstrip("'\"").endswith("/codex-plain-hook")
                                  or cmd == "codex-plain-hook")
        self.backup(native)
        content = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode()
        self.guard.atomic_write(source, content, source.stat().st_mode & 0o777)
        if not native.is_symlink():
            self.guard.atomic_write(native, content, native.stat().st_mode & 0o777)

    def uninstall_plugins(self):
        root = self.home / ".claude/plugins"
        allowed = self.allowed_plugins("claude")
        markets = {name.split("@")[1] for name in allowed}
        builtin = set()
        if self.home == Path.home() and shutil.which("claude"):
            rows = json.loads(subprocess.check_output(["claude", "plugin", "list", "--json"]))
            builtin = {row["id"] for row in rows if row["id"].endswith("@builtin")}

        global_settings = self.home / ".claude/settings.json"
        paths = {global_settings}
        for project in self.projects | {self.home}:
            paths.update(project / ".claude" / name for name in ("settings.json", "settings.local.json"))
        for path in sorted(paths):
            if not path.is_file():
                continue
            data = json.loads(path.read_text())
            plugins = data.get("enabledPlugins", {})
            for name in list(plugins):
                if name.endswith("@builtin"):
                    plugins[name] = False
                elif name not in allowed:
                    del plugins[name]
            if path == global_settings and builtin:
                data.setdefault("enabledPlugins", {}).update(dict.fromkeys(builtin, False))
            for name in list(data.get("extraKnownMarketplaces", {})):
                if name not in markets:
                    del data["extraKnownMarketplaces"][name]
            self.write_json(path, data)

        registry = root / "installed_plugins.json"
        if registry.is_file():
            data = json.loads(registry.read_text())
            for name in list(data.get("plugins", {})):
                if name not in allowed and not name.endswith("@builtin"):
                    del data["plugins"][name]
            self.write_json(registry, data)
        for market in (root / "cache").glob("*"):
            if market.name not in markets:
                self.archive_path(market)
            elif market.is_dir() and not market.is_symlink():
                for plugin in market.iterdir():
                    if f"{plugin.name}@{market.name}" not in allowed:
                        self.archive_path(plugin)
        known = root / "known_marketplaces.json"
        if known.is_file():
            data = json.loads(known.read_text())
            self.write_json(known, {key: value for key, value in data.items() if key in markets})
        for market in (root / "marketplaces").glob("*"):
            if market.name not in markets:
                self.archive_path(market)
        keep_data = {name.replace("@", "-") for name in allowed}
        keep_data.update(name.split("@")[0] + "-inline" for name in allowed)
        for entry in (root / "data").glob("*"):
            if entry.name not in keep_data:
                self.archive_path(entry)

    def configure_codex_plugins(self):
        root = self.home / ".codex"
        path = root / "config.toml"
        if not path.is_file():
            return
        original = path.read_text()
        config = tomllib.loads(original)
        plugins = config.get("plugins", {})
        names = set(plugins)
        caches = list((root / "plugins/cache").glob("*/*"))
        names.update(f"{entry.name}@{entry.parent.name}" for entry in caches if entry.is_dir())
        for market in CODEX_MARKETS:
            bundled = root / ".tmp/bundled-marketplaces" / market / "plugins"
            names.update(f"{manifest.parents[1].name}@{market}"
                         for manifest in bundled.glob("*/.codex-plugin/plugin.json"))
        allowed = self.allowed_plugins("codex")
        desired = self.plugin_switches("codex")
        for name in names | set(desired):
            if name not in allowed and name.split("@")[0] not in allowed:
                desired[name] = False
        changes = {name: enabled for name, enabled in desired.items()
                   if plugins.get(name, {}).get("enabled") is not enabled}
        if changes:
            content = original
            for name, enabled in sorted(changes.items()):
                literal = str(enabled).lower()
                if name not in plugins:
                    content += f"\n[plugins.{json.dumps(name)}]\nenabled = {literal}\n"
                else:
                    header = re.compile(r"(?m)^\s*\[plugins\.(?:" + re.escape(json.dumps(name))
                                        + "|" + re.escape(repr(name)) + r")\]([^\n]*)\n")
                    match = header.search(content)
                    if not match:
                        raise ValueError(f"Unsupported TOML layout for plugin {name} in {path}")
                    start = match.end()
                    boundary = re.search(r"(?m)^\s*\[", content[start:])
                    end = start + boundary.start() if boundary else len(content)
                    body, count = re.subn(r"(?m)^(\s*enabled\s*=\s*)(?:true|false)\b", r"\g<1>" + literal, content[start:end])
                    content = content[:start] + (body if count else f"enabled = {literal}\n" + body) + content[end:]
                config.setdefault("plugins", {}).setdefault(name, {})["enabled"] = enabled
            if tomllib.loads(content) != config or path.read_text() != original:
                raise ValueError(f"Concurrent or unsupported TOML change in {path}")
            self.backup(path)
            self.guard.atomic_write(path.resolve(), content.encode(), path.stat().st_mode & 0o777)
        for entry in caches:
            third_party = entry.parent.name not in CODEX_MARKETS or entry.name.startswith("app-")
            if third_party and entry.name not in allowed and f"{entry.name}@{entry.parent.name}" not in allowed:
                self.archive_path(entry)

    def configure_other_plugins(self):
        self.configure_codex_plugins()
        allowed = self.allowed_plugins("antigravity")
        root = self.home / ".gemini"
        path = root / "config/config.json"
        if path.is_file():
            data = json.loads(path.read_text())
            plugins = data.setdefault("plugins", {})
            for name, enabled in self.plugin_switches("antigravity").items():
                plugins.setdefault(name, {})["enabled"] = enabled and name in allowed
            for manifest in (root / "antigravity-cli/builtin/plugins").glob("*/plugin.json"):
                name = json.loads(manifest.read_text())["name"]
                if name not in allowed:
                    plugins.setdefault(name, {})["enabled"] = False
            self.write_json(path, data)
        if self.home != Path.home():
            return
        for cli, remove in [("grok", "uninstall"), ("agy", "uninstall")]:
            if shutil.which(cli):
                installed = json.loads(subprocess.check_output([cli, "plugin", "list", "--json"]))
                for plugin in installed:
                    if plugin["name"] not in self.allowed_plugins("grok" if cli == "grok" else "antigravity"):
                        subprocess.run([cli, "plugin", remove, plugin["name"]], check=True)

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
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--prepare-links-only", action="store_true")
    modes.add_argument("--plugins-only", action="store_true")
    args = parser.parse_args()
    setup = Setup(args.repo.resolve(), args.home.resolve())
    if args.plugins_only:
        setup.uninstall_plugins()
        setup.configure_other_plugins()
        return
    # A previously unused Codex global prompt may be an empty regular file.
    # Keep the link guard from importing that placeholder over shared instructions.
    codex_prompt = setup.home / ".codex/AGENTS.md"
    if codex_prompt.is_file() and not codex_prompt.is_symlink() and codex_prompt.stat().st_size == 0:
        setup.archive_path(codex_prompt)
    sys.path.insert(0, str(setup.repo / "tools/agent-config"))
    from native import apply_preferences
    apply_preferences(setup.repo, setup.home)
    setup.migrate_skills()
    setup.prepare_codex_hooks()
    if not args.prepare_links_only:
        setup.uninstall_codegraph()
        setup.clean_integrations()
        setup.uninstall_plugins()
        setup.configure_other_plugins()
    print(f"Migration complete; backups: {setup.archive}")


if __name__ == "__main__":
    main()
