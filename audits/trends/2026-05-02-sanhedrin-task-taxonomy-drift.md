# Sanhedrin Task Taxonomy Drift

Audit timestamp: 2026-05-02T05:03:49+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only to evaluate whether Sanhedrin historical rows preserve stable task identity. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-sanhedrin-task-taxonomy-drift.sql`

## Summary

Sanhedrin historical telemetry is dominated by reusable task labels rather than durable work item identifiers. Of 11,687 Sanhedrin iteration rows, 10,586 rows (90.58%) use one of ten generic task IDs such as `AUDIT`, `CLEANUP`, `EMAIL-CHECK`, `VM-COMPILE`, or `CI-CHECK`. That makes long-window trend analysis depend on free-form `notes` parsing instead of the structured `task_id` column, and it weakens Law 7 blocker escalation because repeated blockers cannot be reliably grouped by a specific audit target.

Findings: 5 warnings.

## Findings

### WARNING-1: Generic task IDs dominate Sanhedrin history

Evidence:

- Sanhedrin iteration rows: 11,687.
- Distinct Sanhedrin `task_id` values: 25.
- Rows using the ten generic labels audited here: 10,586.
- Generic-label share: 90.58%.

Impact: `task_id` behaves more like an activity category than a durable unit of work. Trend queries cannot distinguish a retro commit audit, a cross-repo invariant check, a liveness check, and a Law-specific audit unless they parse prose in `notes` or infer from changed files.

### WARNING-2: `AUDIT` collapses thousands of distinct audit events into one key

Evidence:

- `AUDIT`: 2,823 rows, 2,792 pass rows, 31 fail rows.
- `AUDIT` has only 3 distinct `files_changed` values and 1 distinct `validation_cmd` value, but 2,801 distinct `notes` values.
- `AUDIT` appears in 707 immediate consecutive repeats after timestamp normalization.

Impact: the highest-volume Sanhedrin key contains most of its distinguishing information only in free-form notes. That makes duplicate detection, regression grouping, and "same error string 3+ consecutive iterations" checks brittle unless every consumer reimplements text parsing.

### WARNING-3: Routine side checks are indistinguishable from target-specific checks

Evidence:

| Task ID | Rows | Pass | Skip | Fail | Blocked |
| --- | ---: | ---: | ---: | ---: | ---: |
| `EMAIL-CHECK` | 2,088 | 0 | 2,088 | 0 | 0 |
| `CLEANUP` | 1,918 | 1,918 | 0 | 0 | 0 |
| `VM-COMPILE` | 1,269 | 1,244 | 12 | 10 | 3 |
| `CI-CHECK` | 1,261 | 1,261 | 0 | 0 | 0 |
| `VM-CHECK` | 752 | 735 | 12 | 5 | 0 |

Impact: repeated environmental checks have enough volume to dominate agent history, but their `task_id` values do not name the repo, run id, commit SHA, queue item, or audit artifact under examination. This reduces the usefulness of `task_id` for historical root-cause analysis.

### WARNING-4: The central `queue` table cannot repair the traceability gap

Evidence:

- `queue` rows in the central database: 0.
- Sanhedrin rows: 11,687.
- Research rows: 444, with 249 distinct `trigger_task` values and 0 missing triggers.

Impact: there is no structured central queue join that can map generic Sanhedrin rows back to a stable work item. Research telemetry is better linked than Sanhedrin iteration telemetry, which suggests the schema can carry triggers when the loop writes them.

### WARNING-5: Mixed task families encode status semantics inconsistently

Evidence:

| Family | Rows | Unique IDs | Pass | Skip | Fail | Blocked |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `AUDIT` | 2,833 | 5 | 2,801 | 0 | 32 | 0 |
| `CI` | 2,347 | 7 | 1,685 | 618 | 44 | 0 |
| `EMAIL` | 2,088 | 1 | 0 | 2,088 | 0 | 0 |
| `VM` | 2,021 | 2 | 1,979 | 24 | 15 | 3 |
| `CLEANUP` | 1,918 | 1 | 1,918 | 0 | 0 | 0 |

Impact: family-level status distributions are not directly comparable. `EMAIL-CHECK` uses `skip` as its normal outcome, `CLEANUP` uses `pass`, and CI run IDs mix skip/pass/fail under both generic and numeric IDs. Historical dashboards need a normalized `activity_type`, `target_repo`, `target_ref`, and `reason` separate from process status.

## Recommendation

Add a Sanhedrin task taxonomy contract for future DB writes:

```text
task_id: stable human-meaningful audit item, e.g. AUDIT-RETRO-<sha8> or CI-TEMPLEOS-<run_id>
activity_type: retro_audit | cross_repo_audit | trend_audit | ci_check | vm_check | cleanup | email_check
target_repo: TempleOS | holyc-inference | temple-sanhedrin | central-db
target_ref: commit SHA, CI run id, audit artifact path, or DB query id
status: pass | fail | skip | blocked
reason: short normalized skip/block/fail reason
```

This keeps `task_id` useful for Law 7 escalation and lets trend reports aggregate by activity without reverse-engineering prose.

## Read-Only Verification Command

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-sanhedrin-task-taxonomy-drift.sql
```

Finding count: 5 warnings.
