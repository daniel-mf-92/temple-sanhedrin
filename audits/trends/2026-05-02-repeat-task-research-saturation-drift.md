# temple-central.db Repeat-Task Research Saturation Drift

Audit timestamp: 2026-05-02T07:45:33Z

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for long-window research-ledger saturation around repeat-task, same-task, stuck-loop, and streak remediation. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-repeat-task-research-saturation-drift.sql`

## Summary

The historical research ledger is dominated by repeat-task/stuck-loop mitigation notes. Of 444 research rows, 414 rows (93.2%) have repeat-task, same-task, stuck, or streak themed topics. This is an audit signal for Law 5 and Law 7: the same operational blocker class was researched repeatedly, often minutes apart, but the database has no `violations` rows and therefore no structured escalation sink for the repeated Law 7 threshold.

Findings: 5 warnings.

## Findings

### WARNING-1: Repeat-task remediation consumes nearly the entire research ledger

Evidence:
- Total research rows: 444.
- Repeat/stuck-task topic rows: 414 (93.2%).
- First repeat/stuck-task research row: `2026-04-17T04:55:30`.
- Last repeat/stuck-task research row: `2026-04-23T05:59:23`.

Impact: research became a holding area for the same process-control problem instead of a supporting artifact for distinct workstreams. Under Law 5, repeated research about how to stop repeat work can itself become busywork unless it closes with an enforceable control.

### WARNING-2: Two days contain most of the repeated research burst

Evidence:
- `2026-04-21`: 262 of 273 research rows are repeat/stuck-task themed.
- `2026-04-22`: 146 of 160 research rows are repeat/stuck-task themed.
- Those two days account for 408 of the 414 repeat/stuck-task rows.

Impact: the ledger shows burst saturation rather than a small number of durable design decisions. This weakens later historical review because the same blocker class appears as hundreds of separate research events.

### WARNING-3: Repeated trigger tasks are recorded under many topic variants

Evidence:
- `AUDIT`: 39 rows, 35 distinct topics, 15 rows missing references.
- `CQ-1223`: 9 rows, 9 distinct topics.
- `CQ-914/IQ-878`: 9 rows, 8 distinct topics.
- `IQ-990`: 9 rows, 8 distinct topics.
- `CQ-1118`: 8 rows, 8 distinct topics.

Impact: topic churn obscures blocker identity. A stable blocker key would make it possible to answer whether the same Law 7 failure has already been researched, escalated, suppressed, or resolved.

### WARNING-4: Research cadence is too dense for independent findings

Evidence:
- Adjacent repeat/stuck-task research pairs: 413.
- Pairs within 2 minutes: 186.
- Pairs within 10 minutes: 360.
- Busiest hour: `2026-04-21T21:00:00`, with 27 repeat/stuck-task rows across 18 trigger labels.

Impact: this cadence looks more like repeated ledger writes than independent research. For historical audit, it creates high-volume noise around one blocker family while still not proving that the blocker was escalated.

### WARNING-5: Law 7 threshold mentions do not reach the violation ledger

Evidence:
- Repeat/stuck-task research rows: 414.
- Rows mentioning a 3x or `>=3` threshold pattern: 169.
- Rows in `violations`: 0.

Impact: Law 7 requires escalation after 3+ consecutive appearances of the same error string. The research table frequently recognizes the threshold, but the structured violation sink has no rows, so retroactive tooling cannot distinguish "threshold observed and escalated" from "threshold observed and researched again."

## Recommendations

- Add a canonical `blocker_key` or `law7_key` for repeat-task/stuck-loop research rows.
- When a key reaches the 3x threshold, write one structured `violations` row and link later research rows to that escalation instead of creating fresh topic variants.
- Normalize repeat-task research topics to a small taxonomy such as `law7-repeat-task`, `law7-stuck-loop`, and `law7-blocker-resolution`.
- Require `references_urls` or an explicit `local-analysis-only` marker for research rows; 73 repeat/stuck-task rows currently have empty references.
- Treat additional research on an already-escalated blocker as Law 5-sensitive unless it records a new control, new evidence, or a closure decision.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-repeat-task-research-saturation-drift.sql
```

Finding count: 5 warnings.
