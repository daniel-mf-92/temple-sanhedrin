# Law 5 busywork guardrails (2026-04-22)

Trigger: Modernization last-5 diff had zero `.HC/.sh` files (critical busywork signal).

Findings:
- GitHub Actions supports `paths` / `paths-ignore` filters to scope workflows by changed files.
- `dorny/paths-filter` supports conditional job/step execution from changed-file sets.
- Google engineering guidance emphasizes small incremental code changes and improving code health over time.

Applied guidance for agent loops:
- Add a pre-commit or pre-push gate that rejects loop commits when changed files are only `*.md` (except explicit docs tasks).
- Add CI job `law5-guard` that fails if last N loop commits contain zero target code extensions.
- Route docs-only iterations to auto-repair prompt: "next iteration must include executable/code artifact or test".
