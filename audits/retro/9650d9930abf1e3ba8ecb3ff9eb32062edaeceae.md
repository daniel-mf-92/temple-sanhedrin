# Retroactive Commit Audit: 9650d9930abf1e3ba8ecb3ff9eb32062edaeceae

Audited at: 2026-04-29T20:45:19+02:00

Repo: holyc-inference (`/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`)

Commit: `9650d9930abf1e3ba8ecb3ff9eb32062edaeceae`

Subject: `feat(inference): codex iteration 20260429-201627`

Scope selected: retroactive commit audit.

## Summary

This commit adds host-side QEMU prompt benchmark serial-output line telemetry, a `--max-serial-output-lines` gate, smoke coverage, documentation, and refreshed benchmark artifacts.

Changed paths are limited to `GPT55_PROGRESS.md`, `bench/README.md`, `bench/qemu_prompt_bench.py`, `bench/qemu_prompt_bench_ci_smoke.py`, and `bench/results/` artifacts. No HolyC runtime source under `src/` changed.

Finding count: 1 warning, 0 critical.

## Law Checklist

| Law | Result | Evidence |
| --- | --- | --- |
| Law 1 - HolyC Purity | Pass | Python changes are host-side benchmark tooling under `bench/`, which is explicitly outside the core runtime purity boundary. No `.c`, `.cpp`, `.rs`, `.go`, `.py`, `.js`, or `.ts` files were added under `src/`, `Kernel/`, `Adam/`, `Apps/`, `Compiler/`, or `0000Boot/`. |
| Law 2 - Air-Gap Sanctity | Pass | `bench/qemu_prompt_bench.py` still rejects network arguments and builds QEMU commands with `-nic none`; the committed smoke artifacts also show `"-nic", "none"` in benchmark commands. No networking stack or remote runtime dependency was added. |
| Law 4 - Integer Purity | Pass | The commit does not touch inference runtime tensor code. Added Python telemetry computes output line counts for host-side benchmark artifacts only. |
| Identifier Compounding Ban | Pass | Changed basenames are within limits: longest changed basename is `qemu_prompt_bench_20260429T182259Z.json` at 39 chars; max token count among changed basenames is 5. Added/changed function and class names in `bench/qemu_prompt_bench.py` had no names over 40 chars or over 5 underscore-separated tokens. |
| Law 5 / North Star Discipline | Warning | The commit adds meaningful benchmark gating, but the generated result artifacts identify the parent commit instead of the audited commit, weakening historical evidence traceability. |

## Findings

### WARNING: Refreshed benchmark artifacts identify the parent commit, not the audited commit

The commit introduces refreshed benchmark artifacts, but their embedded provenance records `32541c6c3932`, which is the parent of the audited commit. The audited commit short SHA is `9650d9930abf`.

Evidence:

- `bench/results/qemu_prompt_bench_latest.json` contains top-level `"commit": "32541c6c3932"` and per-run commit fields with the same value.
- `bench/results/qemu_prompt_bench_latest.csv` records `32541c6c3932` in the `commit` column.
- The artifact timestamp is `2026-04-29T18:22:59Z`; the progress entry for this iteration is `2026-04-29T18:25:17Z`, and the git commit was created at `2026-04-29T20:26:41+02:00`.

Impact:

Historical reviewers can confirm that the benchmark command, line-count telemetry, and gate outputs existed before the commit was created, but they cannot use the artifacts alone to prove they were generated from the exact committed tree. This is not a HolyC purity or air-gap violation, but it is a repeatable evidence-quality drift under Law 5 / North Star discipline.

Recommended remediation:

For generated benchmark artifacts, include both `source_head_before_commit` and `artifact_commit_introduced_by` fields, or use an artifact manifest that links the generated files to the final git SHA after commit creation.

## Verification Performed

- Inspected commit metadata, changed paths, and diff with `git show`.
- Reviewed `bench/qemu_prompt_bench.py` command construction and network-argument rejection logic at the audited commit.
- Checked changed file basenames and function/class names for compound-name limits.
- Extracted the audited commit to `/tmp/holyc-audit-9650.iHahAK` using `git archive` to avoid active sibling worktree contamination.
- Ran `python3 bench/qemu_prompt_bench_ci_smoke.py` from the archived commit snapshot; it exited 0.
- Ran a negative serial-line gate probe from the archived commit snapshot with `--max-serial-output-lines 0`; it failed as expected with 2 `serial_output_lines` telemetry findings and retained `-nic none` in the generated command.

## Non-Findings

- No trinity source code was modified during this audit.
- No live liveness watching or current-iteration audit was performed.
- No QEMU command was executed without explicit `-nic none`; the only benchmark execution used the synthetic fixture command produced by the audited runner.
- No WS8 networking work was executed.
