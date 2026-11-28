import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from catalog import Catalog, MANIFEST, PROMPT
from gitops import changes, commit, run
from native import preferences

SOURCE = Path(__file__).resolve().parents[2]


class EditorTest(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name).resolve()
        self.repo, self.home = root / "repo", root / "home"
        self.repo.mkdir()
        self.home.mkdir()
        shutil.copytree(
            SOURCE / "agents",
            self.repo / "agents",
            ignore=shutil.ignore_patterns("__pycache__"),
        )
        for path in [MANIFEST, "editors/zed/settings.json"]:
            dest = self.repo / path
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(SOURCE / path, dest)
        self.cat = Catalog(self.repo, self.home)

    def test_project_files_excluded_from_catalog_and_git(self):
        run(self.repo, "git", "init", "-q")
        run(self.repo, "git", "add", ".")
        tree = run(self.repo, "git", "write-tree").stdout.strip()
        seed = run(
            self.repo,
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.com",
            "commit-tree",
            tree,
            "-m",
            "fixture",
        ).stdout.strip()
        run(self.repo, "git", "update-ref", "HEAD", seed)
        paths = [
            "AGENTS.md",
            ".claude/skills/project-only/SKILL.md",
            ".claude/agents/helper.md",
            ".claude/settings.json",
            ".codex/config.toml",
        ]
        for path in paths:
            file = self.repo / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text("project config")
            with self.assertRaises(ValueError):
                self.cat.read(path)
        self.assertIn(PROMPT, self.cat.items())
        self.assertEqual(changes(self.cat), [])

    def test_scope_and_native_formats(self):
        doc = self.cat.create("Codex", "Skills", "only-codex")
        self.assertEqual(
            (self.home / ".codex/skills/only-codex/SKILL.md").resolve(),
            self.repo / doc["id"],
        )
        self.assertFalse((self.home / ".agents/skills/only-codex").exists())
        self.cat.create("Universal", "Skills", "shared-skill")
        self.assertTrue(
            (self.home / ".gemini/config/skills/shared-skill/SKILL.md").is_file()
        )
        prompt = self.cat.create("Codex", "Instructions", "instructions")
        self.cat.save(prompt["id"], prompt["version"], "Codex only")
        self.assertEqual((self.home / ".codex/AGENTS.md").read_text(), "Codex only")
        self.assertNotEqual((self.repo / PROMPT).read_text(), "Codex only")
        hook = self.cat.create("Universal", "Hooks", "report")
        self.cat.save(
            hook["id"],
            hook["version"],
            json.dumps({"event": "UserPromptSubmit", "command": "echo ok"}),
        )
        agy = json.loads((self.repo / "agents/antigravity-hooks.json").read_text())
        self.assertEqual(
            agy["agent-config-report"]["PreInvocation"][0]["command"], "echo ok"
        )
        self.assertIn("_otty", agy)
        self.cat.create("Universal", "Agents", "reviewer")
        self.assertTrue((self.repo / "agents/agents/reviewer.md").exists())
        self.assertTrue((self.home / ".codex/agents/reviewer.toml").is_file())
        self.assertTrue((self.home / ".gemini/config/agents/reviewer.md").is_file())

    @patch("catalog.plugins", return_value=[])
    def test_plugin_panel_changes_only_selected_client(self, _plugins):
        policy = self.repo / "agents/claude-settings.json"
        original = json.loads(policy.read_text())
        other = (self.repo / "agents/policies/codex.json").read_bytes()
        panel = self.cat.read("panel:Claude Code")
        value = json.loads(panel["text"])
        value["keep"].append("example@test")
        value["states"]["example@test"] = True
        saved = self.cat.save(panel["id"], panel["version"], json.dumps(value))
        current = json.loads(policy.read_text())
        self.assertTrue(current["enabledPlugins"].pop("example@test"))
        self.assertEqual(current, original)
        self.assertEqual(json.loads(saved["text"]), value)
        _plugins.assert_not_called()
        self.assertEqual((self.repo / "agents/policies/codex.json").read_bytes(), other)
        with self.assertRaises(ValueError):
            self.cat.save(panel["id"], panel["version"], panel["text"])
        with self.assertRaises(ValueError):
            self.cat.save(saved["id"], saved["version"], "[]")

    def test_conflict_and_preferences(self):
        view = self.cat.read(PROMPT)
        self.cat.save(PROMPT, view["version"], "external")
        with self.assertRaises(ValueError):
            self.cat.save(PROMPT, view["version"], "stale")
        native = self.home / ".codex/config.toml"
        native.parent.mkdir()
        native.write_text('model = "old"\n[private]\nkey = "local-only"\n')
        item = self.cat.read("agents/preferences/codex.json")
        self.assertNotIn("local-only", item["text"])
        self.cat.save(item["id"], item["version"], '{"model":"new"}')
        self.assertEqual(preferences(self.home, "Codex"), {"model": "new"})
        self.assertIn('key = "local-only"', native.read_text())

    @unittest.skipUnless(shutil.which("wt"), "Worktrunk required")
    def test_worktrunk_preserves_separate_index(self):
        repo = self.repo
        run(repo, "git", "init", "-q")
        for key, value in [
            ("user.name", "Test"),
            ("user.email", "test@example.invalid"),
            ("commit.gpgsign", "false"),
            ("core.hooksPath", "/dev/null"),
        ]:
            run(repo, "git", "config", key, value)
        run(repo, "git", "add", ".")
        tree = run(repo, "git", "write-tree").stdout.strip()
        seed = run(repo, "git", "commit-tree", tree, "-m", "fixture").stdout.strip()
        run(repo, "git", "update-ref", "HEAD", seed)
        (repo / "unrelated").write_text("staged")
        run(repo, "git", "add", "unrelated")
        (repo / "unrelated").write_text("edited after staging")
        doc = self.cat.read(PROMPT)
        self.cat.save(PROMPT, doc["version"], "new prompt\n")
        wtconfig = self.home / "wt.toml"
        wtconfig.write_text('[commit.generation]\ncommand = "echo fixture-commit"\n')
        with patch.dict(os.environ, WORKTRUNK_CONFIG_PATH=str(wtconfig)):
            version = next(
                f["version"] for f in changes(self.cat) if f["path"] == PROMPT
            )
            commit(self.cat, {PROMPT: version})
        self.assertEqual(
            run(repo, "git", "diff", "--name-only", "HEAD^", "HEAD").stdout.strip(),
            PROMPT,
        )
        self.assertEqual(run(repo, "git", "show", ":unrelated").stdout, "staged")
        self.assertEqual((repo / "unrelated").read_text(), "edited after staging")
        self.assertEqual(
            run(repo, "git", "diff", "--cached", "--name-only").stdout.strip(),
            "unrelated",
        )


if __name__ == "__main__":
    unittest.main()
