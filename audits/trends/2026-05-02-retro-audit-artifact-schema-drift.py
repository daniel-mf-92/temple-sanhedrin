#!/usr/bin/env python3
"""Read-only retro audit artifact schema drift analyzer."""

from __future__ import annotations

import collections
import re
import subprocess
from pathlib import Path


ROOT = Path("/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55")
REPOS = {
    "TempleOS": Path("/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS"),
    "holyc-inference": Path(
        "/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference"
    ),
}


def repo_commits(repo: Path, *extra: str) -> set[str]:
    out = subprocess.check_output(
        ["git", "-C", str(repo), "log", *extra, "--format=%H"], text=True
    )
    return {line.strip() for line in out.splitlines() if line.strip()}


def main() -> int:
    retro_files = sorted((ROOT / "audits" / "retro").glob("*.md"))
    all_ref_commits = {name: repo_commits(repo, "--all") for name, repo in REPOS.items()}
    branch_commits = {name: repo_commits(repo) for name, repo in REPOS.items()}

    joined_all = collections.Counter()
    joined_branch = collections.Counter()
    counters = collections.Counter()
    samples: dict[str, list[str]] = collections.defaultdict(list)

    checks = {
        "missing_repo_line": r"^- Repo:",
        "missing_commit_line": r"^- Commit:",
        "missing_subject_line": r"^- Subject:",
        "missing_finding_count": r"(?i)^finding count\s*:",
        "missing_findings_heading": r"^## Findings\b",
        "missing_verification_text": (
            r"(?i)verification|static validation|read-only verification"
        ),
        "missing_qemu_nonexecution_statement": (
            r"(?i)(qemu was not executed|no vm command|no qemu|"
            r"did not run qemu|qemu.*not.*executed|no vm.*run)"
        ),
    }

    for path in retro_files:
        text = path.read_text(errors="ignore")
        sha = path.stem
        all_hits = [name for name, commits in all_ref_commits.items() if sha in commits]
        branch_hits = [name for name, commits in branch_commits.items() if sha in commits]

        if len(all_hits) == 1:
            joined_all[all_hits[0]] += 1
        elif not all_hits:
            counters["orphan_reports"] += 1
            samples["orphan_reports"].append(path.name)
        else:
            counters["ambiguous_reports"] += 1
            samples["ambiguous_reports"].append(path.name)

        if len(branch_hits) == 1:
            joined_branch[branch_hits[0]] += 1

        for key, pattern in checks.items():
            if not re.search(pattern, text, re.M):
                counters[key] += 1
                if len(samples[key]) < 5:
                    samples[key].append(path.name)

        if re.search(r"(?i)\bCRITICAL\b|\bWARNING\b", text):
            counters["severity_word_reports"] += 1
        if re.search(r"(?i)no violations found|no laws\.md violations|no findings", text):
            counters["no_violation_reports"] += 1

    print(f"retro_files {len(retro_files)}")
    for name in REPOS:
        print(f"{name}_all_ref_commits {len(all_ref_commits[name])}")
        print(f"{name}_current_branch_commits {len(branch_commits[name])}")
        print(f"{name}_joined_all_refs {joined_all[name]}")
        print(f"{name}_joined_current_branch {joined_branch[name]}")
        print(
            f"{name}_missing_all_ref_reports "
            f"{len(all_ref_commits[name] - {p.stem for p in retro_files})}"
        )
        print(
            f"{name}_missing_current_branch_reports "
            f"{len(branch_commits[name] - {p.stem for p in retro_files})}"
        )

    for key, count in counters.most_common():
        print(f"{key} {count}")

    for key in sorted(samples):
        print(f"{key}_sample {', '.join(samples[key])}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
