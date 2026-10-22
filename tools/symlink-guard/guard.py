#!/usr/bin/env python3
"""Restore managed symlinks after applications replace them with plain files."""

import argparse
import fcntl
import json
import logging
import os
from pathlib import Path
import plistlib
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid


LABEL = "es.qnury.dotfiles-link-guard"
LOG = logging.getLogger(LABEL)


def link_map(repo):
    manifest = json.loads((repo / "tools/symlink-guard/links.json").read_text())
    links = dict(manifest["links"])
    for root in manifest["skillRoots"]:
        for name in manifest["skills"]:
            links[f"{root}/{name}"] = f"agents/skills/{name}"
    return links


def fingerprint(path):
    try:
        info = path.lstat()
    except FileNotFoundError:
        return None
    result = (info.st_ino, info.st_mode, info.st_size, info.st_mtime_ns, info.st_ctime_ns)
    if stat.S_ISDIR(info.st_mode):
        return result, tuple((p.name, fingerprint(p)) for p in sorted(path.iterdir()))
    return result


def atomic_write(path, content, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "wb") as stream:
            os.fchmod(stream.fileno(), mode)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def copy_path(source, destination):
    if source.is_symlink():
        destination.symlink_to(os.readlink(source))
    elif source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination)


def points_to(destination, source):
    try:
        return destination.is_symlink() and destination.resolve() == source.resolve()
    except (OSError, RuntimeError):
        return False


class Guard:
    def __init__(self, repo, home, state, settle=2.0, links=None):
        self.repo = repo.resolve()
        self.home = home.resolve()
        self.state = state
        self.settle = settle
        self.links = link_map(self.repo) if links is None else links
        self.pending = {}
        self.failed = {}

    def backup(self, source, relative, category):
        location = self.state / "backups" / f"{time.time_ns()}-{uuid.uuid4().hex[:8]}"
        destination = location / category / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        copy_path(source, destination)
        return destination

    def merge_directory(self, replacement, source):
        operations = []

        def plan(incoming, original):
            for entry in sorted(incoming.iterdir()):
                target = original / entry.name
                if entry.is_symlink() and entry.resolve() == target.resolve():
                    continue
                if entry.is_symlink() or target.is_symlink():
                    raise ValueError(f"Directory import contains a symlink: {entry} -> {target}")
                if entry.is_dir():
                    if target.exists() and not target.is_dir():
                        raise ValueError(f"Directory/file conflict: {target}")
                    operations.append((entry, target, True))
                    plan(entry, target)
                elif entry.is_file():
                    if target.exists() and not target.is_file():
                        raise ValueError(f"File/directory conflict: {target}")
                    operations.append((entry, target, False))
                else:
                    raise ValueError(f"Unsupported file type: {entry}")

        plan(replacement, source)
        for entry, target, directory in operations:
            if directory:
                target.mkdir(exist_ok=True)
            else:
                if not target.exists() or entry.read_bytes() != target.read_bytes():
                    mode = target.stat().st_mode & 0o777 if target.exists() else 0o600
                    atomic_write(target, entry.read_bytes(), mode)

    def repair(self, relative, source_relative, expected):
        destination = self.home / relative
        source = (self.repo / source_relative).resolve(strict=True)
        if not source.is_relative_to(self.repo):
            raise ValueError(f"Source outside repository: {source}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        parent = destination.parent.resolve()
        if parent.is_relative_to(self.repo):
            raise ValueError(f"Parent resolves into repository: {destination}")
        if not parent.is_relative_to(self.home):
            raise ValueError(f"Parent outside home: {destination}")
        if fingerprint(destination) != expected:
            return False

        incoming = None
        if expected is not None and not destination.is_symlink():
            incoming = self.backup(destination, relative, "replacement")
            if fingerprint(destination) != expected:
                return False
            self.backup(source, source_relative, "source")
            if destination.is_file() and source.is_file():
                content = incoming.read_bytes()
                if source.read_bytes() != content:
                    atomic_write(source, content, source.stat().st_mode & 0o777)
            elif destination.is_dir() and source.is_dir():
                self.merge_directory(incoming, source)
            else:
                raise ValueError(f"Replacement/source type mismatch: {destination}")
        elif destination.is_symlink():
            self.backup(destination, relative, "link")

        if fingerprint(destination) != expected:
            return False
        temporary = destination.parent / f".{destination.name}.{uuid.uuid4().hex}.link"
        try:
            temporary.symlink_to(source, target_is_directory=source.is_dir())
            if incoming is not None and destination.is_dir():
                # Directories cannot be replaced atomically with a symlink. Retain
                # the original tree so open writers can never lose their inode.
                retained = self.state / "backups" / f"{time.time_ns()}-original" / relative
                retained.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(destination), retained)
            os.replace(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)
        LOG.info("Restored %s -> %s%s", destination, source,
                 f"; imported replacement, backup: {incoming}" if incoming else "")
        return True

    def scan(self, now=None):
        now = time.monotonic() if now is None else now
        errors = 0
        # Import older aliases first so the most recent AGENTS.md edit wins.
        def modified(item):
            try:
                return (self.home / item[0]).lstat().st_mtime_ns
            except OSError:
                return 0

        for relative, source_relative in sorted(self.links.items(), key=modified):
            destination = self.home / relative
            source = self.repo / source_relative
            signature = None
            try:
                if points_to(destination, source):
                    self.pending.pop(relative, None)
                    self.failed.pop(relative, None)
                    continue
                signature = fingerprint(destination)
                failure = self.failed.get(relative)
                if failure and failure[0] == signature and now < failure[1]:
                    continue
                previous = self.pending.get(relative)
                if previous is None or previous[0] != signature:
                    self.pending[relative] = (signature, now)
                    if self.settle:
                        continue
                elif now - previous[1] < self.settle:
                    continue
                if self.repair(relative, source_relative, signature):
                    self.pending.pop(relative, None)
            except (OSError, ValueError, RuntimeError) as error:
                errors += 1
                self.failed[relative] = (signature, now + 60)
                LOG.error("Cannot repair %s: %s", destination, error)
        return errors


def launch_agent(repo, home, interpreter):
    return {
        "Label": LABEL,
        "ProgramArguments": [str(interpreter), str(repo / "tools/symlink-guard/guard.py"),
                             "watch", "--repo", str(repo), "--home", str(home)],
        "RunAtLoad": True,
        "KeepAlive": True,
        "ProcessType": "Background",
        "ThrottleInterval": 5,
        "StandardOutPath": str(home / ".local/state/dotfiles-link-guard/stdout.log"),
        "StandardErrorPath": str(home / ".local/state/dotfiles-link-guard/stderr.log"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["watch", "repair", "install"])
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--state", type=Path)
    parser.add_argument("--interval", type=float, default=1.0)
    parser.add_argument("--settle", type=float, default=2.0)
    args = parser.parse_args()
    if args.interval <= 0 or args.settle < 0:
        parser.error("interval must be positive; settle must be nonnegative")
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    repo, home = args.repo.resolve(), args.home.resolve()
    state = args.state or home / ".local/state/dotfiles-link-guard"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    if args.action == "install":
        if sys.platform != "darwin":
            parser.error("install requires macOS launchd")
        plist = home / f"Library/LaunchAgents/{LABEL}.plist"
        interpreter = Path("/run/current-system/sw/bin/python3")
        if not interpreter.is_file():
            interpreter = Path(sys.executable)
        atomic_write(plist, plistlib.dumps(launch_agent(repo, home, interpreter)), 0o644)
        domain = f"gui/{os.getuid()}"
        subprocess.run(["launchctl", "bootout", "--wait", f"{domain}/{LABEL}"], capture_output=True)
        subprocess.run(["launchctl", "enable", f"{domain}/{LABEL}"], check=True)
        subprocess.run(["launchctl", "bootstrap", domain, str(plist)], check=True)
        LOG.info("Installed %s", plist)
        return 0
    with (state / "guard.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            LOG.error("Another watcher or repair is running")
            return 1
        guard = Guard(repo, home, state, args.settle)
        if args.action == "repair":
            guard.scan()
            time.sleep(args.settle)
            return int(guard.scan() != 0 or bool(guard.pending))
        running = True

        def stop(signum, frame):
            nonlocal running
            running = False

        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGINT, stop)
        LOG.info("Watching %d links in %s", len(guard.links), home)
        while running:
            guard.scan()
            time.sleep(args.interval)
    return 0


if __name__ == "__main__":
    sys.exit(main())
