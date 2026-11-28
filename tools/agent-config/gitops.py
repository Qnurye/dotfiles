import difflib
import hashlib
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


def run(repo, *args, env=None, check=True):
    result = subprocess.run(args, cwd=repo, env=env, capture_output=True, text=True)
    if check and result.returncode:
        raise ValueError((result.stderr or result.stdout or "命令失败").strip()[-2200:])
    return result


def changes(catalog):
    repo = catalog.repo
    paths = set(
        run(repo, "git", "diff", "HEAD", "--name-only", "-z").stdout.split("\0")
    )
    paths.update(
        run(
            repo, "git", "ls-files", "--others", "--exclude-standard", "-z"
        ).stdout.split("\0")
    )
    allow = set(catalog.items()) | catalog.touched | {"tools/symlink-guard/links.json"}
    result = []
    for name in sorted(paths - {""}):
        if name not in allow and not name.startswith(
            ("agents/rendered/", "agents/agents/")
        ):
            continue
        path = catalog.path(name)
        if path.is_symlink() or not path.is_file():
            continue
        base = run(repo, "git", "show", "HEAD:" + name, check=False)
        prev = base.stdout if base.returncode == 0 else ""
        text = path.read_text()
        diff = "".join(
            difflib.unified_diff(
                prev.splitlines(True),
                text.splitlines(True),
                fromfile="a/" + name,
                tofile="b/" + name,
            )
        )
        if diff or base.returncode:
            result.append(
                dict(
                    path=name,
                    diff=diff,
                    edited=name in catalog.touched,
                    version=hashlib.sha256(
                        (str(base.returncode) + "\0" + prev + "\0" + text).encode()
                    ).hexdigest(),
                )
            )
    return result


def commit(catalog, versions):
    repo = catalog.repo
    current = {f["path"]: f for f in changes(catalog)}
    if not versions or any(
        k not in current or current[k]["version"] != v for k, v in versions.items()
    ):
        raise ValueError("待提交内容已变化，请刷新差异")
    paths = list(versions)
    index = Path(
        run(
            repo, "git", "rev-parse", "--path-format=absolute", "--git-path", "index"
        ).stdout.strip()
    )
    lock = index.with_name(index.name + ".lock")
    # Hold the normal index lock while Worktrunk uses an independent index. Keep
    # staging for unrelated files, including partially staged changes, intact.
    with tempfile.TemporaryDirectory(dir=index.parent) as tmp:
        published = False
        with lock.open("xb") as out:
            try:
                env = dict(os.environ, GIT_INDEX_FILE=str(Path(tmp) / "commit-index"))
                run(repo, "git", "read-tree", "HEAD", env=env)
                run(repo, "git", "add", "--", *paths, env=env)
                for p in paths:
                    blob = run(repo, "git", "show", ":" + p, env=env).stdout
                    base = run(repo, "git", "show", "HEAD:" + p, check=False)
                    if (
                        hashlib.sha256(
                            (
                                str(base.returncode)
                                + "\0"
                                + (base.stdout if not base.returncode else "")
                                + "\0"
                                + blob
                            ).encode()
                        ).hexdigest()
                        != versions[p]
                    ):
                        raise ValueError("工作树内容变化，请刷新差异")
                # Never discard an independently staged version of a selected file.
                for p in paths:
                    if (
                        run(
                            repo,
                            "git",
                            "diff",
                            "--cached",
                            "--quiet",
                            "--",
                            p,
                            check=False,
                        ).returncode
                        and run(
                            repo, "git", "diff", "--quiet", "--", p, check=False
                        ).returncode
                    ):
                        raise ValueError("所选文件已有部分暂存内容：" + p)
                merged = Path(tmp) / "next-index"
                shutil.copyfile(index, merged)
                nextenv = dict(os.environ, GIT_INDEX_FILE=str(merged))
                tree = run(repo, "git", "write-tree", env=env).stdout.strip()
                run(repo, "git", "reset", "-q", tree, "--", *paths, env=nextenv)
                out.write(merged.read_bytes())
                out.flush()
                run(repo, "wt", "step", "commit", "--stage", "none", env=env)
                os.replace(lock, index)
                published = True
            finally:
                if not published:
                    lock.unlink(missing_ok=True)
    catalog.touched.difference_update(paths)
    return run(repo, "git", "rev-parse", "--short", "HEAD").stdout.strip()
