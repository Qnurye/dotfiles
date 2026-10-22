import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch


HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("guard", HERE / "guard.py")
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)
spec = importlib.util.spec_from_file_location("setup_agents", HERE.parents[1] / "agents/setup.py")
setup_agents = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup_agents)


class GuardTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name) / "home"
        self.repo = self.home / "dotfiles"
        self.repo.mkdir(parents=True)
        self.source = self.repo / "AGENTS.md"
        self.source.write_text("original\n")
        self.target = self.home / "AGENTS.md"
        self.state = self.home / "state"
        self.watcher = guard.Guard(self.repo, self.home, self.state,
                                   settle=2, links={"AGENTS.md": "AGENTS.md"})

    def settle(self):
        self.watcher.scan(now=0)
        return self.watcher.scan(now=3)

    def test_atomic_editor_replacement_imports_and_preserves_both_versions(self):
        self.target.symlink_to(self.source)
        incoming = self.home / "editor.tmp"
        incoming.write_text("new instruction\n")
        os.replace(incoming, self.target)
        self.assertEqual(self.settle(), 0)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(self.source.read_text(), "new instruction\n")
        backups = [p.read_text() for p in (self.state / "backups").rglob("AGENTS.md")]
        self.assertCountEqual(backups, ["original\n", "new instruction\n"])

    def test_continuing_writes_reset_settling_window(self):
        self.target.write_text("part one")
        self.watcher.scan(now=0)
        self.target.write_text("part one and two")
        self.watcher.scan(now=1)
        self.watcher.scan(now=2)
        self.assertFalse(self.target.is_symlink())
        self.watcher.scan(now=4)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(self.source.read_text(), "part one and two")

    def test_missing_link_is_restored_without_changing_source(self):
        self.assertEqual(self.settle(), 0)
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(self.source.read_text(), "original\n")

    def test_home_manager_intermediate_link_is_accepted(self):
        middle = self.home / "store-link"
        middle.symlink_to(self.source)
        self.target.symlink_to(middle)
        self.assertEqual(self.settle(), 0)
        self.assertEqual(os.readlink(self.target), str(middle))
        self.assertFalse(self.state.exists())

    def test_self_referential_link_is_repaired(self):
        self.target.symlink_to(self.target)
        self.assertEqual(self.settle(), 0)
        self.assertEqual(self.target.resolve(), self.source.resolve())
        self.assertEqual(self.source.read_text(), "original\n")

    def test_later_alias_wins_and_earlier_version_is_backed_up(self):
        other = self.home / "CLAUDE.md"
        self.target.write_text("newer")
        other.write_text("older")
        os.utime(self.target, ns=(20_000_000_000, 20_000_000_000))
        os.utime(other, ns=(10_000_000_000, 10_000_000_000))
        self.watcher.links["CLAUDE.md"] = "AGENTS.md"
        self.settle()
        self.assertEqual(self.source.read_text(), "newer")
        self.assertTrue(other.is_symlink())
        self.assertIn("older", [p.read_text() for p in (self.state / "backups").rglob("*.md")])

    def test_change_during_backup_defers_repair(self):
        self.target.write_text("first")
        original = self.watcher.backup

        def concurrent_write(*args):
            result = original(*args)
            self.target.write_text("still writing")
            return result

        with patch.object(self.watcher, "backup", side_effect=concurrent_write):
            self.settle()
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(self.source.read_text(), "original\n")
        self.watcher.scan(now=4)
        self.watcher.scan(now=7)
        self.assertEqual(self.source.read_text(), "still writing")

    def test_repair_does_not_follow_parent_into_repository(self):
        (self.home / "skills").symlink_to(self.repo)
        self.watcher.links = {"skills/AGENTS.md": "AGENTS.md"}
        with self.assertLogs(guard.LOG, level="ERROR"):
            self.assertEqual(self.settle(), 1)
        self.assertFalse(self.source.is_symlink())
        self.assertEqual(self.source.read_text(), "original\n")

    def test_type_mismatch_preserves_source_and_replacement(self):
        self.target.mkdir()
        (self.target / "keep").write_text("directory content")
        with self.assertLogs(guard.LOG, level="ERROR"):
            self.assertEqual(self.settle(), 1)
        self.assertTrue(self.target.is_dir())
        self.assertEqual(self.source.read_text(), "original\n")

    def test_directory_replacement_merges_without_deleting_source_files(self):
        source = self.repo / "skill"
        source.mkdir()
        (source / "keep").write_text("keep")
        (source / "edit").write_text("before")
        replacement = self.home / "skill"
        replacement.mkdir()
        (replacement / "edit").write_text("after")
        (replacement / "added").write_text("new")
        self.watcher.links = {"skill": "skill"}
        self.settle()
        self.assertTrue(replacement.is_symlink())
        self.assertEqual((source / "keep").read_text(), "keep")
        self.assertEqual((source / "edit").read_text(), "after")
        self.assertEqual((source / "added").read_text(), "new")

    def test_external_source_is_rejected(self):
        outside = self.home / "outside"
        outside.write_text("private")
        (self.repo / "escape").symlink_to(outside)
        self.target.write_text("overwrite")
        self.watcher.links = {"AGENTS.md": "escape"}
        with self.assertLogs(guard.LOG, level="ERROR"):
            self.assertEqual(self.settle(), 1)
        self.assertEqual(outside.read_text(), "private")

    def test_directory_symlink_rejection_does_not_partially_import(self):
        source = self.repo / "skill"
        source.mkdir()
        (source / "a").write_text("original")
        replacement = self.home / "skill"
        replacement.mkdir()
        (replacement / "a").write_text("changed")
        (replacement / "z").symlink_to(self.home)
        self.watcher.links = {"skill": "skill"}
        with self.assertLogs(guard.LOG, level="ERROR"):
            self.assertEqual(self.settle(), 1)
        self.assertEqual((source / "a").read_text(), "original")
        self.assertFalse(replacement.is_symlink())
        self.assertEqual(self.watcher.scan(now=4), 0)

    def test_legacy_directory_with_links_to_its_source_can_be_migrated(self):
        source = self.repo / "fish"
        source.mkdir()
        (source / "config.fish").write_text("configuration")
        replacement = self.home / "fish"
        replacement.mkdir()
        (replacement / "config.fish").symlink_to(source / "config.fish")
        self.watcher.links = {"fish": "fish"}
        self.assertEqual(self.settle(), 0)
        self.assertTrue(replacement.is_symlink())
        self.assertFalse((source / "config.fish").is_symlink())
        self.assertEqual((source / "config.fish").read_text(), "configuration")

    def test_watch_process_repairs_in_background_and_stops(self):
        manifest = self.repo / "tools/symlink-guard/links.json"
        manifest.parent.mkdir(parents=True)
        manifest.write_text(json.dumps({"links": {"AGENTS.md": "AGENTS.md"}, "skills": [], "skillRoots": []}))
        process = subprocess.Popen([sys.executable, str(HERE / "guard.py"), "watch",
                                    "--repo", str(self.repo), "--home", str(self.home),
                                    "--settle", "0.05", "--interval", "0.02"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            deadline = time.monotonic() + 5
            while not self.target.is_symlink() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(self.target.is_symlink())
            incoming = self.home / "new"
            incoming.write_text("from CLI")
            os.replace(incoming, self.target)
            while not self.target.is_symlink() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(self.target.is_symlink())
            self.assertEqual(self.source.read_text(), "from CLI")
        finally:
            process.terminate()
            process.wait(timeout=3)
        self.assertEqual(process.returncode, 0)


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.repo = self.home / "dotfiles"
        shutil.copytree(HERE, self.repo / "tools/symlink-guard",
                        ignore=shutil.ignore_patterns("__pycache__"))
        self.shared = self.repo / "agents/skills"
        self.shared.mkdir(parents=True)
        for name in ["copywriting", "pr", "r2-upload-html", "resolve-conflicts", ".system", "synced"]:
            (self.shared / name).mkdir()
            (self.shared / name / "SKILL.md").write_text(name)
        self.setup = setup_agents.Setup(self.repo, self.home)

    def test_legacy_roots_detach_without_losing_runtime_skills(self):
        for relative in [".claude/skills", ".codex/skills", ".agents/skills", ".gemini/skills"]:
            root = self.home / relative
            root.parent.mkdir()
            root.symlink_to(self.shared if relative == ".claude/skills" else self.home / ".claude/skills")
        self.setup.migrate_skills()
        self.setup.migrate_skills()
        self.assertEqual((self.home / ".codex/skills/.system/SKILL.md").read_text(), ".system")
        self.assertEqual((self.home / ".claude/skills/synced/SKILL.md").read_text(), "synced")
        for relative in [".claude/skills", ".codex/skills", ".agents/skills", ".gemini/skills"]:
            self.assertFalse((self.home / relative).is_symlink())
        self.assertFalse((self.home / ".claude/skills/.system").exists())
        self.assertFalse((self.home / ".codex/skills/synced").exists())
        self.assertFalse((self.shared / ".system").exists())

    def test_cleanup_removes_only_retired_integrations_and_plugins(self):
        original = {"mcpServers": {"codegraph": {}, "context7": {}, "keep": {}},
                    "projects": {str(self.repo): {"disabledMcpServers": ["context7", "keep"]}},
                    "hooks": {"PreToolUse": [{"hooks": [{"command": "~/.claude/hooks/rtk-rewrite.sh"}]}]},
                    "unrelated": "preserve"}
        (self.home / ".claude.json").write_text(json.dumps(original))
        registry = self.home / ".claude/plugins/installed_plugins.json"
        registry.parent.mkdir(parents=True)
        registry.write_text(json.dumps({"version": 2, "plugins": {
            "context7@claude-plugins-official": [], "diverge@diverge": []}}))
        self.setup.clean_integrations()
        self.setup.uninstall_plugins()
        result = json.loads((self.home / ".claude.json").read_text())
        self.assertEqual(result["mcpServers"], {"keep": {}})
        self.assertEqual(result["projects"][str(self.repo)]["disabledMcpServers"], ["keep"])
        self.assertEqual(result["unrelated"], "preserve")
        self.assertEqual(result["hooks"]["PreToolUse"][0]["hooks"][0]["command"], "rtk hook claude")
        self.assertEqual(json.loads(registry.read_text())["plugins"], {"diverge@diverge": []})
        self.assertTrue((self.setup.archive / ".claude.json").exists())

    def test_existing_codex_hooks_keep_custom_handlers_and_gain_guard(self):
        source = self.repo / "agents/codex-hooks.json"
        source.write_text('{"hooks": {}}')
        native = self.home / ".codex/hooks.json"
        native.parent.mkdir()
        native.write_text(json.dumps({"hooks": {"Stop": [{"hooks": [{"command": "custom-notify"}]}]}}))
        self.setup.prepare_codex_hooks()
        self.setup.prepare_codex_hooks()
        data = json.loads(native.read_text())
        self.assertEqual(data["hooks"]["Stop"][0]["hooks"][0]["command"], "custom-notify")
        self.assertEqual(len(data["hooks"]["PreToolUse"]), 1)
        self.assertEqual(native.read_bytes(), source.read_bytes())

    def test_plugins_enabled_in_other_projects_are_preserved(self):
        project = self.home / "notes"
        settings = project / ".claude/settings.json"
        settings.parent.mkdir(parents=True)
        settings.write_text(json.dumps({"enabledPlugins": {
            "obsidian@obsidian-skills": True, "context7@claude-plugins-official": True}}))
        registry = self.home / ".claude/plugins/installed_plugins.json"
        registry.parent.mkdir(parents=True)
        registry.write_text(json.dumps({"plugins": {
            "obsidian@obsidian-skills": [{"scope": "project", "projectPath": str(project)}],
            "context7@claude-plugins-official": []}}))
        setup = setup_agents.Setup(self.repo, self.home)
        setup.clean_integrations()
        setup.uninstall_plugins()
        self.assertIn("obsidian@obsidian-skills", json.loads(registry.read_text())["plugins"])
        self.assertNotIn("context7@claude-plugins-official", json.loads(registry.read_text())["plugins"])
        self.assertEqual(json.loads(settings.read_text())["enabledPlugins"], {"obsidian@obsidian-skills": True})
        self.assertNotIn("obsidian-skills", setup.removed_marketplaces)


if __name__ == "__main__":
    unittest.main()
