# Historical Law 5 Busywork / Task-Reuse Drift Audit

Timestamp: 2026-04-28T06:29:48Z

Scope: historical trend audit from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, focused on Law 5 no-busywork signals and repeated CQ/IQ task usage in stored modernization and inference rows. This audit did not inspect live liveness, did not run QEMU/VM commands, did not modify TempleOS or holyc-inference source code, and preserved the guest air-gap.

SQL used: `audits/trends/2026-04-28-law5-busywork-task-reuse-drift.sql`

## Source Coverage

| Source | Rows | First timestamp | Last timestamp | Doc-only rows | MASTER_TASKS-only rows | Tiny MASTER_TASKS-only rows | Core HolyC rows | Tooling/test rows |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | 50 | 45 | 34 | 1,226 | 1,279 |
| modernization | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | 5 | 4 | 4 | 751 | 993 |

## Findings

### 1. WARNING: Inference has repeated tiny `MASTER_TASKS.md`-only pass rows

Inference records 45 rows where the only changed file is `MASTER_TASKS.md`; 34 of those rows add three or fewer lines and remove no lines. That is only 3.18% of all inference rows, but it is concentrated in the exact shape Law 5 warns about: task-list movement without technical payload.

Impact: the rows do not prove a violation by themselves because many surrounding inference rows touch core HolyC and tests. They do show that historical dashboards can count queue grooming as successful builder progress unless they distinguish task-file-only rows from implementation rows.

### 2. WARNING: Inference has multiple short consecutive `MASTER_TASKS.md`-only streaks

The longest `MASTER_TASKS.md`-only streak is three inference rows from 2026-04-19T00:12:27 to 2026-04-19T00:19:59: `IQ-451,IQ-452,IQ-451`, with six lines added and no removals. Four more two-row inference streaks appear on 2026-04-21 and 2026-04-22.

Impact: none reaches the explicit Law 5 tripwire of five or more consecutive doc-structure-only iterations, so this is not a retroactive Law 5 violation. It is still a drift signal because the same task ID appears twice inside the largest queue-only streak.

### 3. WARNING: Task IDs are reused enough to blur one-iteration-one-work-unit accounting

The historical rows include several task IDs with four or more pass rows. Examples include modernization `CQ-914` with six rows, modernization `CQ-1118`, `CQ-1191`, and `CQ-1223` with five rows each, and inference `IQ-878` with five rows. The repeated rows often include substantial added lines, so this is not pure busywork, but it weakens queue progress accounting.

Impact: repeated IDs make it harder to tell whether an item was decomposed into meaningful slices, retried under the same queue label, or used as a container for follow-on work. That affects Law 5 and Law 6 backfills because queue depth and task completion can look healthier than the underlying work-unit structure.

### 4. WARNING: Repeated `MASTER_TASKS.md`-only task IDs exist in inference

Inference has two task IDs repeated as `MASTER_TASKS.md`-only rows: `IQ-451` appears twice between 2026-04-19T00:12:27 and 2026-04-19T00:19:59, and `IQ-932` appears twice between 2026-04-21T17:24:48 and 2026-04-21T17:27:25. Each pair adds four total lines.

Impact: this is the highest-risk historical busywork shape found in this pass: repeated task identity plus queue-only edits plus tiny churn. The row count is low, but it should be scored separately from implementation or test-bearing iterations.

### 5. INFO: The explicit five-row doc-only Law 5 threshold was not observed

The maximum doc-only streak is three for inference and one for modernization. Modernization has only five doc-only rows total in this historical DB window, and inference still has 1,226 rows touching core HolyC plus 1,279 touching tooling or tests.

Impact: the historical trend is drift, not a confirmed Law 5 breach. A useful enforcement refinement would be to record `work_class` at insertion time with values such as `core_holyc`, `host_tooling`, `test`, `spec`, and `queue_only`, then count queue-only streaks and repeated task IDs as first-class metrics.

## Recommendations

- Add typed iteration fields: `work_class`, `queue_only`, `core_holyc_changed`, `test_changed`, and `task_reuse_count`.
- Treat `MASTER_TASKS.md`-only rows as `queue_only_pass`, not the same progress class as implementation or validation-bearing commits.
- Alert on repeated queue-only use of the same task ID, even when the five-row doc-only Law 5 threshold is not reached.
- Keep repeated task IDs allowed for multi-commit implementation work, but require a subtask suffix or note when a CQ/IQ ID spans more than three pass rows.

## Read-Only Verification Commands

- `sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema iterations'`
- `sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-law5-busywork-task-reuse-drift.sql`

Finding count: 5 total, 4 warnings and 1 info.
