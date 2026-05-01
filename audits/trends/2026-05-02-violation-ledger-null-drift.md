# temple-central.db Violation Ledger Null Drift

Audit timestamp: 2026-05-02T00:45:42+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only and scanned existing Sanhedrin audit markdown under this repo for severity signals. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `66c21a987f7b`
- SQL: `audits/trends/2026-05-02-violation-ledger-null-drift.sql`

## Summary

`temple-central.db` has a normalized `violations` table and 11 rows in `laws`, but it contains zero violation rows. That is not consistent with the audit corpus: this repository currently has 1,070 markdown audit reports across `audits/` and `audit/`, including 401 files with critical signals and 529 files with warning signals. The central database therefore records Sanhedrin activity volume, but not the structured severity outcomes needed for long-window Law trend analysis.

Findings: 5 total.

## Findings

### CRITICAL-1: The normalized violation ledger is completely empty

Evidence:
- `laws` table rows: 11.
- `violations` table rows: 0.
- `iterations` table rows: 14,606.
- Markdown audit reports scanned: 1,070.
- Markdown files with critical signals: 401.
- Markdown files with warning signals: 529.

Impact: historical compliance scoring cannot use the intended relational sink. Any severity trend has to parse prose and filenames, which is weaker, slower, and easier to skew than inserting one row per law finding.

### WARNING-2: Sanhedrin failure rows do not preserve machine-readable error payloads

Evidence:
- Sanhedrin `fail` rows: 94.
- Sanhedrin `fail` rows with empty `error_msg`: 94.
- Sanhedrin `blocked` rows: 3.
- Sanhedrin `blocked` rows with empty `error_msg`: 3.

Impact: Law 7 blocker escalation and repeat-error detection cannot be reconstructed from `error_msg`; auditors must parse free-form `notes` or markdown instead.

### WARNING-3: Sanhedrin rows omit validation command, validation result, and duration fields

Evidence:
- Sanhedrin rows: 11,687.
- Rows with empty `validation_cmd`: 11,687.
- Rows with empty `validation_result`: 11,687.
- Rows with null `duration_sec`: 11,687.

Impact: Sanhedrin appears as a high-volume activity stream without enough structured provenance to distinguish full audits, skipped checks, blocked checks, enforcement actions, and partial observations.

### WARNING-4: Daily fail trends exist only as status counts, not law-linked findings

Evidence:
- Sanhedrin fail rows by day include 42 on 2026-04-16, 15 on 2026-04-21, 10 on 2026-04-20, and 9 each on 2026-04-17 and 2026-04-22.
- All daily fail rows have empty `error_msg`.
- All violation severities remain absent because `violations` is empty.

Impact: the DB can show when Sanhedrin failed, but not which Law failed, which agent was responsible, severity, evidence, or resolution state. That blocks reliable historical drift charts by Law.

### INFO-5: The gap is backfillable from local artifacts without touching builder repos

Evidence:
- Existing markdown report paths and contents contain enough severity vocabulary to seed a derived backfill table or pending insert set.
- The query pack is read-only and does not require TempleOS or holyc-inference source writes.
- The `violations` schema already has `law_id`, `agent`, `severity`, `evidence`, and `resolved` fields.

Impact: a conservative backfill can start with report-level severity rows linked to `evidence` paths, then later refine `law_id` and agent attribution from headings and filenames. This would convert the audit corpus into durable trend data without changing the trinity source repos.

## Key Aggregates

| Source | Count |
| --- | ---: |
| DB `laws` rows | 11 |
| DB `violations` rows | 0 |
| DB `iterations` rows | 14,606 |
| Markdown audit reports scanned | 1,070 |
| Markdown files with critical signals | 401 |
| Markdown files with warning signals | 529 |
| Markdown files with info signals | 148 |

| Sanhedrin Status | Rows | Rows Without `error_msg` |
| --- | ---: | ---: |
| blocked | 3 | 3 |
| fail | 94 | 94 |
| pass | 8,850 | 8,850 |
| skip | 2,740 | 2,740 |

| Agent | Rows | Empty Validation Cmd | Empty Validation Result | Empty Error Msg | Null Duration |
| --- | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 1,414 | 1,414 |
| modernization | 1,505 | 0 | 0 | 1,505 | 1,505 |
| sanhedrin | 11,687 | 11,687 | 11,687 | 11,687 | 11,687 |

## Recommendations

- Insert one `violations` row per Sanhedrin finding, even when the detailed report remains markdown.
- For every Sanhedrin `fail` or `blocked` iteration, populate `error_msg` with the normalized blocker or law breach summary.
- Add a report path or artifact pointer to `evidence` so database trends can join back to the full markdown.
- Backfill conservatively: start with report-level severity counts and mark ambiguous law/agent attribution as unresolved until manually classified.

## Read-Only Verification Commands

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-violation-ledger-null-drift.sql
```

```bash
python3 - <<'PY'
from pathlib import Path
files = [p for root in ('audits', 'audit') for p in Path(root).rglob('*.md')]
crit = []
warn = []
info = []
for path in files:
    text = path.read_text(errors='ignore')
    if 'CRITICAL' in text or 'critical' in path.name:
        crit.append(path)
    if 'WARNING' in text or 'warning' in path.name:
        warn.append(path)
    if 'INFO' in text:
        info.append(path)
print(len(files), len(crit), len(warn), len(info))
PY
```

Finding count: 5 total, 1 critical, 3 warnings, and 1 info.
