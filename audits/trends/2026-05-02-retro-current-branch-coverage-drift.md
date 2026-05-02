# Retro Current-Branch Coverage Drift

Audit timestamp: 2026-05-02T04:49:00Z

Audit angle: historical drift trends. This pass analyzed the existing `audits/retro/*.md` corpus against read-only current-branch git history in `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Analyzer: `audits/trends/2026-05-02-retro-current-branch-coverage-drift.py`

## Summary

The newest current-branch commits are covered by retro reports, so there is no immediate head freshness gap. The historical backlog remains large: TempleOS current-branch coverage is 200 of 2,067 commits, and holyc-inference current-branch coverage is 121 of 2,383 commits. The backlog starts just past the recent covered window, then continues uninterrupted to repository roots.

Findings: 5 warnings.

## Findings

### WARNING-1: TempleOS current-branch retro coverage is shallow

Evidence:

- Current branch: `codex/modernization-loop`.
- Current-branch commits: 2,067.
- Current-branch commits with retro reports: 200.
- Current-branch commits missing retro reports: 1,867.
- Coverage: 9.68%.

Impact: the latest TempleOS work has been audited, but the current-branch corpus is still mostly unaudited when measured against the branch history LAWS.md asks the retro lane to walk.

### WARNING-2: holyc-inference current-branch retro coverage is shallower

Evidence:

- Current branch: `main`.
- Current-branch commits: 2,383.
- Current-branch commits with retro reports: 121.
- Current-branch commits missing retro reports: 2,262.
- Coverage: 5.08%.

Impact: holyc-inference has a larger current-branch backlog than TempleOS, and this directly weakens Law 1 / Law 4 / Law 5 historical confidence for the inference runtime.

### WARNING-3: The unaudited backlog begins immediately after the recent covered window

Evidence:

| Repo | First missing rank | First missing commit | Approx age | Subject |
| --- | ---: | --- | ---: | --- |
| TempleOS | 201 | `4f717604e2b3` | 123h | `feat(modernization): codex iteration 20260427-031841` |
| holyc-inference | 122 | `495512715e46` | 131h | `feat(inference): codex iteration 20260426-193910` |

Impact: the gap is not scattered missing reports. It is a contiguous older-history backlog, which means each future retro pass can make deterministic progress by walking backward from those boundary commits.

### WARNING-4: Recent-window coverage differs by repo

Evidence:

| Repo | Latest 25 | Latest 50 | Latest 100 | Latest 200 |
| --- | ---: | ---: | ---: | ---: |
| TempleOS audited | 25/25 | 50/50 | 100/100 | 200/200 |
| holyc-inference audited | 25/25 | 50/50 | 100/100 | 121/200 |

Impact: TempleOS has a clean recent 200-commit retro window, while holyc-inference only has a clean recent 121-commit window. Cross-repo retro comparisons should not assume equivalent historical depth.

### WARNING-5: Coverage dashboards need a current-branch denominator

Evidence:

- Total retro reports in `audits/retro`: 837.
- TempleOS current branch audited: 200 reports.
- holyc-inference current branch audited: 121 reports.
- Existing reports include side-branch/all-ref coverage, so report count alone overstates active-branch completion.

Impact: future compliance scoring should separate `current branch`, `all refs`, and `latest N` coverage. Otherwise, a growing retro corpus can still leave the active builder histories mostly unaudited.

## Read-Only Verification Command

```bash
python3 audits/trends/2026-05-02-retro-current-branch-coverage-drift.py
```

Finding count: 5 warnings.
