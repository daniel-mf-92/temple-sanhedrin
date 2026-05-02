# Research Trigger Traceability Drift

Audit timestamp: 2026-05-02T11:41:55+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for `research.trigger_task` traceability into concrete CQ/IQ queue work. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-research-trigger-traceability-drift.sql`

## Summary

The historical research ledger is useful, but its trigger field is not reliably machine-joinable. The DB has 444 research rows from `2026-04-15T16:02:12` through `2026-04-23T05:59:23`; 299 rows use CQ/IQ-looking trigger IDs, yet 0 join to the normalized `queue` table because that table is empty. Another 243 rows use prose, threshold, agent-prefixed, or compound trigger forms. This weakens Law 5 and Law 6 backfills because research can be seen as having happened, but cannot be scored against a normalized queue item, workstream, owner, attempt count, or completion state.

Findings: 5 warning findings.

## Findings

### WARNING-1: Research trigger IDs do not join to normalized queue records

Evidence:
- Research rows: 444.
- CQ/IQ-like trigger rows: 299.
- Exact `research.trigger_task = queue.id` joins: 0.
- `queue` table rows: 0.

Impact: research entries that appear tied to concrete CQ/IQ tasks cannot be joined to queue metadata. That blocks automated Law 6 checks for workstream provenance, queue status, attempts, or whether a research item came from real queue pressure versus after-the-fact narrative.

### WARNING-2: Compound and prose trigger forms are common

Evidence:
- Prose or compound trigger rows: 243.
- Shape counts: 54 `compound_task`, 32 `threshold_or_repeat_prose`, 13 `agent_prefixed_or_prose`, 5 `other`.
- Examples include `CQ-914/IQ-878`, `repeat-task>=3`, `multi-task-repeat>=3`, and `modernization:4x consecutive; inference:3x consecutive`.

Impact: these rows may describe valid research, but they overload one field with multiple tasks, agents, thresholds, and analysis labels. That prevents deterministic joins and makes later auditors reparse free text to decide whether a Law 5 or Law 7 research response matched a specific builder task.

### WARNING-3: The `AUDIT` sentinel masks concrete trigger provenance

Evidence:
- `AUDIT` appears as `trigger_task` in 41 rows.
- Its window runs from `2026-04-17T04:55:30` through `2026-04-22T08:23:12`.
- It is the most repeated exact trigger value in the research table.

Impact: an `AUDIT` sentinel distinguishes Sanhedrin-originated research from builder-originated work, but it loses the specific audit artifact, issue, law, or queue item that caused the research. That makes historical research backfills coarser than the rest of the compliance ledger.

### WARNING-4: Trigger-shape drift concentrated during the busiest research days

Evidence:
- `2026-04-21`: 273 research rows, 178 prose-or-compound trigger rows.
- `2026-04-22`: 160 research rows, 63 prose-or-compound trigger rows.
- Those two days account for 433 of 444 research rows.

Impact: the traceability problem is concentrated in the highest-volume research window, exactly where automated backfill would benefit most from structured joins.

### WARNING-5: Repeated research triggers lack normalized attempt semantics

Evidence:
- `CQ-1223` appears 10 times, `IQ-990` appears 10 times, `CQ-1118` appears 9 times, `CQ-914/IQ-878` appears 9 times, and `IQ-878` appears 9 times.
- Compound repeated triggers include `CQ-877,CQ-810,IQ-839,IQ-842,IQ-844`, `IQ-920,CQ-965`, and `inference:IQ-920x3;modernization:CQ-965x3`.

Impact: repeated research may be legitimate escalation or refinement, but the table has no normalized `research_attempt`, `trigger_kind`, `source_agent`, or multi-trigger child rows. Long-window reports can count repetition, but cannot distinguish useful continuation from Law 5 research churn without manual review.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Research rows | 444 |
| CQ/IQ-like trigger rows | 299 |
| Exact queue joins | 0 |
| CQ/IQ-like rows without queue join | 299 |
| Prose-or-compound trigger rows | 243 |
| `AUDIT` trigger rows | 41 |
| Queue table rows | 0 |

| Trigger Shape | Rows | First Timestamp | Last Timestamp |
| --- | ---: | --- | --- |
| `single_cq` | 152 | `2026-04-20T17:48:21` | `2026-04-23T05:59:23` |
| `single_iq` | 147 | `2026-04-15T16:02:12` | `2026-04-22T11:54:54` |
| `compound_task` | 54 | `2026-04-21T02:20:43` | `2026-04-22T22:31:56` |
| `audit_sentinel` | 41 | `2026-04-17T04:55:30` | `2026-04-22T08:23:12` |
| `threshold_or_repeat_prose` | 32 | `2026-04-21T02:37:27` | `2026-04-22T05:15:35` |
| `agent_prefixed_or_prose` | 13 | `2026-04-20T17:49:28` | `2026-04-22T06:54:40` |
| `other` | 5 | `2026-04-21T08:18:59` | `2026-04-22T05:24:26` |

## Recommendations

- Materialize queue records before or alongside research rows so `trigger_task` can join to `queue.id`.
- Split compound triggers into child rows, for example `research_triggers(research_id, task_id, agent, trigger_kind, repeat_count)`.
- Replace the broad `AUDIT` sentinel with structured fields such as `source=audit`, `law_id`, `audit_artifact`, and optional `task_id`.
- Preserve prose trigger context in a separate notes field, not as the only join key.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-trigger-traceability-drift.sql
```

Finding count: 5 warning findings.
