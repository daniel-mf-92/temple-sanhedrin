#!/usr/bin/env python3
"""Read-only continuation scanner for LAWS.md No Self-Generated Queue Items."""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass


@dataclass(frozen=True)
class RepoScan:
    name: str
    path: str
    task_file: str
    prefix: str
    base: str


REPOS = (
    RepoScan(
        name="TempleOS",
        path="/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS",
        task_file="MODERNIZATION/MASTER_TASKS.md",
        prefix="CQ",
        base="abadd2368ae3e3e0c55796ba2589e6de4b8a6367",
    ),
    RepoScan(
        name="holyc-inference",
        path="/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference",
        task_file="MASTER_TASKS.md",
        prefix="IQ",
        base="b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d",
    ),
)


def git(repo: RepoScan, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", repo.path, *args],
        text=True,
        errors="replace",
    )


def scan_repo(repo: RepoScan) -> None:
    head = git(repo, "rev-parse", "HEAD").strip()
    log = git(
        repo,
        "log",
        "--reverse",
        "--format=%H%x09%ad%x09%s",
        "--date=iso-strict",
        f"{repo.base}..HEAD",
        "--",
        repo.task_file,
    ).splitlines()

    unchecked_re = re.compile(r"^\+\s*- \[ \]\s+" + repo.prefix + r"-\d+")
    checked_re = re.compile(r"^\+\s*- \[[xX]\]\s+" + repo.prefix + r"-\d+")

    unchecked_commits = []
    checked_add_commits = []
    unchecked_lines = 0
    checked_lines = 0

    for row in log:
        sha, date, subject = row.split("\t", 2)
        diff = git(repo, "show", "--format=", "--unified=0", sha, "--", repo.task_file)
        unchecked = [line for line in diff.splitlines() if unchecked_re.match(line)]
        checked = [line for line in diff.splitlines() if checked_re.match(line)]
        if unchecked:
            unchecked_commits.append((sha, date, subject, len(unchecked)))
            unchecked_lines += len(unchecked)
        if checked:
            checked_add_commits.append((sha, date, subject, len(checked)))
            checked_lines += len(checked)

    print(f"repo={repo.name}")
    print(f"base={repo.base}")
    print(f"head={head}")
    print(f"task_file={repo.task_file}")
    print(f"commits_touching_task_file={len(log)}")
    print(f"unchecked_addition_commits={len(unchecked_commits)}")
    print(f"unchecked_added_lines={unchecked_lines}")
    print(f"checked_line_addition_commits={len(checked_add_commits)}")
    print(f"checked_added_lines={checked_lines}")
    for sha, date, subject, count in unchecked_commits:
        print(f"VIOLATION {sha} {date} count={count} subject={subject}")
    print()


def main() -> None:
    for repo in REPOS:
        scan_repo(repo)


if __name__ == "__main__":
    main()
