#!/usr/bin/env python3
"""Read-only cross-repo identifier contract audit."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path


TEMPLEOS = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS")
INFERENCE = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference")
MAX_LEN = 40
MAX_TOKENS = 5

FUNC_RE = re.compile(
    r"^\s*(?:public\s+)?(?:_extern\s+)?"
    r"(?:U0|Bool|I8|I16|I32|I64|U8|U16|U32|U64|F32|F64|C[A-Za-z0-9_]*\s*\*?|"
    r"[A-Za-z_][A-Za-z0-9_]*\s*\*?)\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)\s*\("
)


def token_count(name: str) -> int:
    return len([part for part in re.split(r"[-_]+", name) if part])


def git_head(repo: Path) -> str:
    return subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()


def run_checker(repo: Path) -> tuple[int, str]:
    checker = repo / "automation" / "check-no-compound-names.sh"
    if not checker.exists():
        return 127, "missing automation/check-no-compound-names.sh"
    proc = subprocess.run(
        ["bash", str(checker), "HEAD"],
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return proc.returncode, proc.stdout.strip()


def source_files(repo: Path, prefixes: tuple[str, ...]) -> list[Path]:
    files: list[Path] = []
    for prefix in prefixes:
        root = repo / prefix
        if root.exists():
            files.extend(path for path in root.rglob("*.HC") if path.is_file())
            files.extend(path for path in root.rglob("*.HH") if path.is_file())
    return sorted(files)


def scan_functions(files: list[Path], repo: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for path in files:
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for lineno, line in enumerate(lines, 1):
            match = FUNC_RE.match(line)
            if not match:
                continue
            name = match.group(1)
            rows.append(
                {
                    "name": name,
                    "length": len(name),
                    "tokens": token_count(name),
                    "path": path.relative_to(repo).as_posix(),
                    "line": lineno,
                }
            )
    return rows


def scan_filenames(files: list[Path], repo: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for path in files:
        stem = path.stem
        rows.append(
            {
                "name": path.name,
                "stem": stem,
                "length": len(stem),
                "tokens": token_count(stem),
                "path": path.relative_to(repo).as_posix(),
            }
        )
    return rows


def bad(rows: list[dict[str, object]]) -> list[dict[str, object]]:
    return [row for row in rows if int(row["length"]) > MAX_LEN or int(row["tokens"]) > MAX_TOKENS]


def print_top(title: str, rows: list[dict[str, object]], limit: int = 12) -> None:
    print(f"\n## {title}")
    print()
    print("| Length | Tokens | Name | Location |")
    print("| ---: | ---: | --- | --- |")
    for row in sorted(rows, key=lambda r: (int(r["length"]), int(r["tokens"])), reverse=True)[:limit]:
        location = row["path"]
        if "line" in row:
            location = f"{location}:{row['line']}"
        print(f"| {row['length']} | {row['tokens']} | `{row['name']}` | `{location}` |")


def main() -> int:
    temple_files = source_files(TEMPLEOS, ("Kernel", "Adam", "Apps", "Compiler", "0000Boot"))
    inference_files = source_files(INFERENCE, ("src",))

    temple_functions = scan_functions(temple_files, TEMPLEOS)
    inference_functions = scan_functions(inference_files, INFERENCE)
    temple_file_rows = scan_filenames(temple_files, TEMPLEOS)
    inference_file_rows = scan_filenames(inference_files, INFERENCE)

    temple_checker_rc, temple_checker_out = run_checker(TEMPLEOS)
    inference_checker_rc, inference_checker_out = run_checker(INFERENCE)

    print("# Cross-Repo Identifier Contract Drift Data")
    print()
    print(f"TempleOS HEAD: `{git_head(TEMPLEOS)}`")
    print(f"holyc-inference HEAD: `{git_head(INFERENCE)}`")
    print()
    print("| Repo | Source files scanned | Function defs scanned | Bad source filenames | Bad function names | Checker status |")
    print("| --- | ---: | ---: | ---: | ---: | --- |")
    print(
        f"| TempleOS core | {len(temple_files)} | {len(temple_functions)} | "
        f"{len(bad(temple_file_rows))} | {len(bad(temple_functions))} | rc={temple_checker_rc} |"
    )
    print(
        f"| holyc-inference src | {len(inference_files)} | {len(inference_functions)} | "
        f"{len(bad(inference_file_rows))} | {len(bad(inference_functions))} | rc={inference_checker_rc} |"
    )
    print()
    print("## Checker Output")
    print()
    print("TempleOS:")
    print("```")
    print(temple_checker_out)
    print("```")
    print()
    print("holyc-inference:")
    print("```")
    print(inference_checker_out)
    print("```")

    print_top("holyc-inference Longest Source Function Names", bad(inference_functions))
    print_top("TempleOS Longest Core Function Names", sorted(temple_functions, key=lambda r: int(r["length"]), reverse=True))
    print_top("holyc-inference Source Filename Violations", bad(inference_file_rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
