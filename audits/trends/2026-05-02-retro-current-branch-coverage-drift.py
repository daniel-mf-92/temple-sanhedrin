#!/usr/bin/env python3
"""Read-only retro audit current-branch coverage drift analyzer."""

from __future__ import annotations

import collections
import datetime as dt
import subprocess
from pathlib import Path


ROOT = Path("/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55")
REPOS = {
    "TempleOS": Path("/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS"),
    "holyc-inference": Path(
        "/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference"
    ),
}
NOW = dt.datetime.fromisoformat("2026-05-02T06:49:00+02:00")
WINDOWS = (25, 50, 100, 200)


def git_lines(repo: Path, args: list[str]) -> list[str]:
    out = subprocess.check_output(["git", "-C", str(repo), *args], text=True)
    return [line for line in out.splitlines() if line.strip()]


def current_branch(repo: Path) -> str:
    return git_lines(repo, ["branch", "--show-current"])[0]


def current_branch_commits(repo: Path) -> list[dict[str, object]]:
    rows = git_lines(repo, ["log", "--date=iso-strict", "--format=%H%x09%aI%x09%s"])
    commits: list[dict[str, object]] = []
    for index, row in enumerate(rows, start=1):
        sha, iso_date, subject = row.split("\t", 2)
        commits.append(
            {
                "rank": index,
                "sha": sha,
                "date": dt.datetime.fromisoformat(iso_date),
                "subject": subject,
            }
        )
    return commits


def report_stems() -> set[str]:
    return {path.stem for path in (ROOT / "audits" / "retro").glob("*.md")}


def age_hours(commit_date: dt.datetime) -> int:
    return int((NOW - commit_date.astimezone(NOW.tzinfo)).total_seconds() // 3600)


def streaks(commits: list[dict[str, object]], reports: set[str]) -> tuple[int, int, int]:
    newest_streak = 0
    longest_gap = 0
    current_gap = 0
    audited_after_gap = 0

    for commit in commits:
        if commit["sha"] in reports:
            if current_gap > longest_gap:
                longest_gap = current_gap
            current_gap = 0
            audited_after_gap += 1
        else:
            current_gap += 1
            if audited_after_gap == 0:
                newest_streak += 1

    return newest_streak, max(longest_gap, current_gap), audited_after_gap


def date_buckets(commits: list[dict[str, object]], reports: set[str]) -> collections.Counter:
    buckets: collections.Counter[str] = collections.Counter()
    for commit in commits:
        day = commit["date"].astimezone(NOW.tzinfo).date().isoformat()
        suffix = "audited" if commit["sha"] in reports else "missing"
        buckets[f"{day}_{suffix}"] += 1
    return buckets


def main() -> int:
    reports = report_stems()
    print(f"retro_reports {len(reports)}")

    for name, repo in REPOS.items():
        branch = current_branch(repo)
        commits = current_branch_commits(repo)
        audited = [commit for commit in commits if commit["sha"] in reports]
        missing = [commit for commit in commits if commit["sha"] not in reports]
        newest_streak, longest_gap, audited_after_gap = streaks(commits, reports)
        buckets = date_buckets(commits[:200], reports)

        print(f"\nrepo {name}")
        print(f"branch {branch}")
        print(f"current_branch_commits {len(commits)}")
        print(f"current_branch_audited {len(audited)}")
        print(f"current_branch_missing {len(missing)}")
        print(f"coverage_percent {len(audited) * 100 / len(commits):.2f}")
        print(f"newest_unaudited_streak {newest_streak}")
        print(f"longest_unaudited_gap {longest_gap}")
        print(f"audited_commits_after_newest_gap {audited_after_gap}")

        for window in WINDOWS:
            sample = commits[:window]
            sample_audited = sum(1 for commit in sample if commit["sha"] in reports)
            print(f"latest_{window}_audited {sample_audited}")
            print(f"latest_{window}_missing {window - sample_audited}")

        if audited:
            latest_audited = audited[0]
            print(
                "latest_audited "
                f"{latest_audited['rank']} "
                f"{latest_audited['sha'][:12]} "
                f"{latest_audited['date'].isoformat()} "
                f"{age_hours(latest_audited['date'])}h"
            )

        for idx, commit in enumerate(missing[:10], start=1):
            print(
                "missing_sample "
                f"{idx} "
                f"rank={commit['rank']} "
                f"sha={commit['sha'][:12]} "
                f"age_h={age_hours(commit['date'])} "
                f"subject={commit['subject']}"
            )

        for day in sorted({key.rsplit("_", 1)[0] for key in buckets}, reverse=True)[:7]:
            audited_count = buckets[f"{day}_audited"]
            missing_count = buckets[f"{day}_missing"]
            print(f"bucket {day} audited={audited_count} missing={missing_count}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
