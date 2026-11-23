"""Remove one delivery worktree after GitHub confirms its PR merged."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def git(directory, *args):
    return subprocess.check_output(["git", "-C", directory, *args], text=True).rstrip("\n")


def already_removed(control, worktree):
    if worktree.exists():
        return False
    entries = git(control, "worktree", "list", "--porcelain", "-z").split("\0")
    if f"worktree {worktree}" in entries:
        raise ValueError(f"Directory is missing but Git still lists {worktree}.")
    print(f"No worktree remains at {worktree}.")
    return True


def read_pr(pr_url, wait):
    command = ["gh", "pr", "view", pr_url, "--json", "state,headRefName,headRefOid"]
    delays = (15, 60, 180) if wait else ()
    for delay in (*delays, None):
        try:
            return json.loads(subprocess.check_output(command, text=True))
        except subprocess.CalledProcessError as error:
            if delay is None or error.returncode != 1:
                raise
            print(f"PR lookup failed. Retrying in {delay}s.", file=sys.stderr, flush=True)
            time.sleep(delay)


def cleanup(pr_url, worktree, wait):
    control = Path.cwd().resolve()
    if already_removed(control, worktree):
        return
    if control.is_relative_to(worktree) or not (worktree / ".git").is_file():
        raise ValueError("Run from a surviving checkout and specify a linked worktree.")
    common = ("rev-parse", "--path-format=absolute", "--git-common-dir")
    shared_dir = git(control, *common)
    if shared_dir != git(worktree, *common):
        raise ValueError("The checkout and worktree belong to different repositories.")
    if shared_dir == git(worktree, "rev-parse", "--absolute-git-dir"):
        raise ValueError("The primary checkout must be kept.")
    marker = (worktree / ".git").stat()
    branch = git(worktree, "symbolic-ref", "--short", "HEAD")

    while True:
        pr = read_pr(pr_url, wait)
        if pr["headRefName"] != branch:
            raise ValueError(f"PR branch differs from {branch}. Keeping {worktree}.")
        if pr["state"] == "MERGED":
            break
        if pr["state"] != "OPEN" or not wait:
            print(f"PR is {pr['state']}. Keeping {worktree}.")
            return
        time.sleep(60)

    if already_removed(control, worktree):
        return
    if not os.path.samestat((worktree / ".git").stat(), marker):
        raise ValueError(f"Worktree was replaced. Keeping {worktree}.")
    if git(worktree, "symbolic-ref", "--short", "HEAD") != branch:
        raise ValueError(f"Worktree changed branches. Keeping {worktree}.")
    if git(worktree, "rev-parse", "HEAD") != pr["headRefOid"]:
        raise ValueError(f"Local HEAD differs from the merged PR head. Keeping {worktree}.")
    if git(worktree, "status", "--porcelain", "--untracked-files=all", "--ignore-submodules=none"):
        raise ValueError(f"Worktree has local changes. Keeping {worktree}.")

    subprocess.run(["wt", "remove", "--foreground", str(worktree)], check=True)
    if not already_removed(control, worktree):
        raise ValueError(f"Worktrunk returned but {worktree} still exists.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wait", action="store_true", help="wait while the PR is open")
    parser.add_argument("pr_url")
    parser.add_argument("worktree", type=Path)
    args = parser.parse_args()
    try:
        cleanup(args.pr_url, args.worktree.resolve(), args.wait)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
