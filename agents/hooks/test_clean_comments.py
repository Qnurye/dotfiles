import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


HOOK = Path(__file__).with_name("clean-comments.py")


class CommentHookTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name).resolve()

    def run_hook(self, phase, event):
        p = subprocess.run(
            [sys.executable, HOOK, phase],
            input=json.dumps(event),
            capture_output=True,
            text=True,
            cwd=self.root,
            env={**os.environ, "TMPDIR": str(self.root)},
            check=True,
        )
        self.assertEqual(p.stderr, "")
        return json.loads(p.stdout)

    def test_write_keeps_existing_comments_strings_and_directives(self):
        path = self.root / "demo.py"
        original = "# Initialize kept to zero\nkept = 0\n"
        path.write_text(original)
        preserved = original + (
            'text = """\n# Initialize count to zero\ncount = 0\n"""\n'
            "# Initialize total to zero because empty batches are valid\ntotal = 0\n"
            "value = 4  # noqa: F841\n"
        )
        text = preserved + "# 初始化index为0\nindex = 0\n"
        ev = {
            "session_id": "s",
            "tool_use_id": "a",
            "cwd": str(self.root),
            "tool_name": "Write",
            "tool_input": {"file_path": str(path), "content": text},
        }
        self.assertEqual(self.run_hook("pre", ev), {})
        path.write_text(text)
        self.assertEqual(
            self.run_hook("post", ev)["hookSpecificOutput"]["additionalContext"],
            "你的注释被我删掉了",
        )
        self.assertEqual(path.read_text(), preserved + "index = 0\n")
        self.assertEqual(self.run_hook("post", ev), {})

    def test_patch_only_changes_added_comment_and_preserves_line_endings(self):
        ev = {
            "session_id": "s",
            "tool_use_id": "b",
            "cwd": str(self.root),
            "tool_name": "apply_patch",
            "tool_input": {
                "command": "*** Begin Patch\n*** Update File: app.ts\n@@\n+let count = 0; // Initialize count to zero\n*** End Patch"
            },
        }
        path = self.root / "app.ts"
        before = b'const msg = "// return msg";\r\n'
        path.write_bytes(before)
        self.run_hook("pre", ev)
        path.write_bytes(before + b"let count = 0; // Initialize count to zero\r\n")
        self.assertIn(
            "additionalContext", self.run_hook("post", ev)["hookSpecificOutput"]
        )
        self.assertEqual(path.read_bytes(), before + b"let count = 0;\r\n")

    def test_antigravity_sends_notice_once(self):
        path = self.root / "demo.py"
        text = "# Initialize count to zero\ncount = 0\n"
        ev = {
            "conversationId": "s",
            "workspacePaths": [str(self.root)],
            "toolCall": {
                "name": "write_to_file",
                "args": {"TargetFile": str(path), "CodeContent": text},
            },
        }
        self.assertEqual(self.run_hook("pre", ev), {"decision": "allow"})
        path.write_text(text)
        self.assertEqual(self.run_hook("post", ev), {})
        self.assertEqual(path.read_text(), "count = 0\n")
        self.assertEqual(
            self.run_hook("notify", ev)["injectSteps"][0]["ephemeralMessage"],
            "你的注释被我删掉了",
        )
        self.assertEqual(self.run_hook("notify", ev), {})

    def test_failed_or_unmatched_edit_is_a_noop(self):
        ev = {
            "session_id": "s",
            "cwd": str(self.root),
            "tool_name": "Edit",
            "tool_input": {
                "file_path": "demo.py",
                "old_string": "pass",
                "new_string": "# Return value\nreturn value",
            },
        }
        path = self.root / "demo.py"
        path.write_text("pass\n")
        self.run_hook("pre", ev)
        self.assertEqual(self.run_hook("post", ev), {})
        self.assertEqual(path.read_text(), "pass\n")


if __name__ == "__main__":
    unittest.main()
