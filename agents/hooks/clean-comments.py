"""Remove newly added, literal restatements of adjacent code after a native file edit."""

import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

LANG = {
    ".py": "Python",
    ".js": "JavaScript",
    ".jsx": "JavaScript",
    ".mjs": "JavaScript",
    ".cjs": "JavaScript",
    ".ts": "TypeScript",
    ".tsx": "Tsx",
    ".go": "Go",
    ".rs": "Rust",
    ".java": "Java",
    ".c": "C",
    ".h": "C",
    ".cc": "Cpp",
    ".cpp": "Cpp",
    ".hpp": "Cpp",
    ".rb": "Ruby",
}
NOTICE = "你的注释被我删掉了"
LIMIT = 2_000_000


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def words(text):
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", text)
    return " ".join(re.findall(r"[a-z]+|[0-9]+", text.lower()))


def restates(comment, code):
    body = re.fullmatch(r"(?:#|//)\s+([\w ,。.-]+)", comment)
    if not body:
        return False
    chinese = re.sub(r"\s+", "", body[1]).rstrip("。.")
    if not body[1].isascii():
        simple = code.strip().rstrip(";")
        ret = re.fullmatch(r"return\s+([A-Za-z_]\w*)", simple)
        if ret:
            return chinese == "返回" + ret[1]
        assignment = re.fullmatch(
            r"(?:(?:let|const|var|int)\s+)?([A-Za-z_]\w*)\s*(?::=|=)\s*(\w+)", simple
        )
        if assignment:
            name, value = assignment.groups()
            return chinese in {
                f"初始化{name}",
                f"初始化{name}为{value}",
                f"将{name}设置为{value}",
            }
        return False
    label = re.sub(r"\b(?:the|a|an|variable)\b\s*", "", words(body[1])).strip()
    code = code.strip().rstrip(";")
    name = r"([A-Za-z_]\w*)"
    assignment = re.fullmatch(
        r"(?:(?:let|mut|const|var|int|bool|float|double|auto|long|unsigned)\s+)*"
        + name
        + r"\s*(?::\s*[\w.]+\s*)?(?::=|=)\s*(.+)",
        code,
    )
    if assignment:
        target, value = assignment.groups()
        target = words(target)
        values = {words(value)}
        values.update(
            {
                "0": ["zero"],
                "[]": ["empty list", "empty array"],
                "{}": ["empty dict", "empty object"],
            }.get(value, [])
        )
        return any(
            label in {f"{verb} {target}", *(f"{verb} {target} to {v}" for v in values)}
            for verb in ("set", "initialize", "initialise", "declare", "assign")
        )
    ret = re.fullmatch(r"return\s+" + name, code)
    if ret:
        return label in {f"return {words(ret[1])}", f"returns {words(ret[1])}"}
    inc = re.fullmatch(name + r"\s*(\+\+|--|\+=\s*1|-=\s*1)", code)
    if inc:
        verb = "increment" if "+" in inc[2] else "decrement"
        return label in {f"{verb} {words(inc[1])}", f"{verb} {words(inc[1])} by 1"}
    loop = re.fullmatch(r"for\s+\w+\s+in\s+" + name + r":", code)
    return bool(
        loop
        and label in {f"loop over {words(loop[1])}", f"iterate over {words(loop[1])}"}
    )


def proposed(event):
    tool = event.get("tool_name")
    data = event.get("tool_input", {})
    if tool in ("Edit", "Write"):
        yield data["file_path"], data["content" if tool == "Write" else "new_string"]
    elif tool == "apply_patch":
        path = None
        for line in data["command"].splitlines():
            if line.startswith(("*** Add File: ", "*** Update File: ")):
                path = line.split(": ", 1)[1]
            elif line.startswith("*** "):
                path = None
            elif path and line.startswith("+"):
                yield path, line[1:]
    elif "toolCall" in event:
        call = event["toolCall"]
        data = call["args"]
        if call["name"] in ("write_file", "edit_file"):
            yield data["Path"], data.get("Content", data.get("NewString", ""))
            return
        for chunk in data.get("ReplacementChunks", [data]):
            yield (
                data["TargetFile"],
                chunk.get("ReplacementContent", chunk.get("CodeContent", "")),
            )


def prepare(event, state):
    roots = [
        Path(p).resolve()
        for p in event.get("workspacePaths") or [event.get("cwd") or os.getcwd()]
    ]
    candidates = defaultdict(set)
    for raw, fragment in proposed(event):
        path = roots[0] / raw
        if (
            path.suffix not in LANG
            or path.resolve() != path
            or not any(path.is_relative_to(r) for r in roots)
        ):
            continue
        for line in fragment.splitlines():
            if re.search(r"(?:#|//)\s+\w", line):
                candidates[path].add(line)
    plan = {}
    for path, lines in candidates.items():
        if path.exists() and (not path.is_file() or path.stat().st_size > LIMIT):
            continue
        old = path.read_text() if path.exists() else ""
        old_comments = {
            line[m.start() :].strip()
            for line in old.splitlines()
            for m in re.finditer(r"(?:#|//)\s+\w", line)
        }
        # An edit or full-file rewrite can repeat comments that already belonged to the user.
        hashes = [
            digest(line)
            for line in lines
            if not any(
                line[m.start() :].strip() in old_comments
                for m in re.finditer(r"(?:#|//)\s+\w", line)
            )
        ]
        if hashes:
            plan[str(path)] = hashes
    if plan:
        state.write_text(json.dumps(plan))


def clean(path, hashes):
    if path.resolve() != path or not path.is_file():
        return 0
    before = path.stat()
    if before.st_size > LIMIT or before.st_nlink != 1:
        return 0
    raw = path.read_bytes()
    lines = raw.splitlines(keepends=True)
    eligible = [digest(line.rstrip(b"\r\n").decode()) for line in lines]
    counts = Counter(eligible)
    eligible = {i for i, h in enumerate(eligible) if h in hashes and counts[h] == 1}
    if not eligible:
        return 0
    kind = "line_comment" if path.suffix == ".rs" else "comment"
    rule = json.dumps(
        {"id": "comments", "language": LANG[path.suffix], "rule": {"kind": kind}}
    )
    result = subprocess.run(
        ["ast-grep", "scan", "--stdin", "--inline-rules", rule, "--json=compact"],
        cwd="/",
        input=raw,
        capture_output=True,
        timeout=5,
    )
    if result.returncode:
        return 0
    removed = 0
    for match in json.loads(result.stdout):
        span = match["range"]
        i = span["start"]["line"]
        if i not in eligible or i != span["end"]["line"]:
            continue
        prefix = lines[i][: span["start"]["column"]].rstrip(b" \t")
        if not prefix and (
            i + 1 == len(lines) or (i and lines[i - 1].rstrip().endswith(b"\\"))
        ):
            continue
        code = prefix or lines[i + 1]
        if restates(match["text"], code.decode()):
            ending = lines[i][len(lines[i].rstrip(b"\r\n")) :]
            lines[i] = prefix + ending if prefix else b""
            removed += 1
    if removed:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as out:
            tmp = Path(out.name)
        try:
            tmp.write_bytes(b"".join(lines))
            shutil.copystat(path, tmp)
            os.utime(tmp, None)
            current = path.lstat()
            if (current.st_ino, current.st_ctime_ns) != (
                before.st_ino,
                before.st_ctime_ns,
            ):
                return 0
            tmp.replace(path)
        finally:
            tmp.unlink(missing_ok=True)
    return removed


def handle(event, phase):
    agy = "conversationId" in event
    session = event.get("conversationId") or event.get("session_id")
    call = event.get("tool_use_id") or json.dumps(
        event.get("toolCall") or event.get("tool_input"), sort_keys=True
    )
    if not session:
        return {}
    cache = Path(tempfile.gettempdir()) / f"dotfiles-comment-hook-{os.getuid()}"
    cache.mkdir(mode=0o700, exist_ok=True)
    if (
        cache.is_symlink()
        or cache.stat().st_uid != os.getuid()
        or stat.S_IMODE(cache.stat().st_mode) != 0o700
    ):
        return {}
    notice = cache / ("notice-" + digest(session))
    if phase == "notify":
        try:
            notice.unlink()
        except FileNotFoundError:
            return {}
        return {"injectSteps": [{"ephemeralMessage": NOTICE}]}
    state = cache / digest(session + ":" + call)
    if phase == "pre":
        state.unlink(missing_ok=True)
        prepare(event, state)
    elif state.exists():
        plan = json.loads(state.read_text())
        state.unlink()
        if not event.get("error"):
            removed = 0
            for raw, hashes in plan.items():
                try:
                    removed += clean(Path(raw), set(hashes))
                except (ValueError, OSError, subprocess.SubprocessError):
                    continue
            if removed:
                if agy:
                    notice.touch()
                else:
                    return {
                        "hookSpecificOutput": {
                            "hookEventName": "PostToolUse",
                            "additionalContext": NOTICE,
                        }
                    }
    return {}


if __name__ == "__main__":
    fallback = {}
    try:
        event = json.load(sys.stdin)
        phase = sys.argv[1]
        fallback = (
            {"decision": "allow"}
            if phase == "pre" and "conversationId" in event
            else {}
        )
        print(json.dumps(handle(event, phase) or fallback, ensure_ascii=False))
    except Exception:
        print(json.dumps(fallback))
