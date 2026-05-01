# temple-central.db Queue-ID Monotonicity Drift

Audit timestamp: 2026-05-01T06:39:22+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether historical builder `iterations.task_id` values moved monotonically by CQ/IQ number. It excluded slash/comma/plus compound task IDs already covered by the compound task-id audit. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-queue-id-monotonicity-drift.sql`

## Summary

The historical builder ledger does not preserve a monotonic queue-consumption sequence. Even after excluding compound task IDs, inference has 193 immediate backward steps and 505 rows below the prior high-water IQ number; modernization has 109 immediate backward steps and 413 rows below the prior high-water CQ number. This is not proof that the builders worked invalid tasks, because the empty `queue` table prevents checking whether older IDs were legitimate retries or reopened work. It is evidence that `iterations.task_id` alone cannot verify the Law 6 monotonic queue-ID invariant.

Findings: 5 total.

## Findings

### WARNING-1: Both builders have many immediate backward queue-ID steps

Evidence:
- Inference clean task rows: 1,414; immediate backward steps: 193.
- Modernization clean task rows: 1,402; immediate backward steps: 109.
- Early examples include `IQ-034` then `IQ-026`, `CQ-111` then `CQ-110`, and `IQ-127` then `IQ-020`.

Impact: a row ordered by insertion time can move from a higher queue number to a lower one without any structured reason. That weakens Law 6 historical scoring because monotonicity cannot be inferred from the append order.

### WARNING-2: Below-high-water rows are widespread, not isolated retries

Evidence:
- Inference rows below prior high-water IQ number: 505 of 1,414 (`35.7%`).
- Modernization rows below prior high-water CQ number: 413 of 1,402 (`29.5%`).
- The largest high-water regressions sampled are large: `IQ-821` after prior high-water `IQ-1061`, and `CQ-114` after prior high-water `CQ-289`.

Impact: once the builders reached a queue high-water mark, many later rows used lower IDs. Without a retry/reopen field, auditors cannot distinguish valid backtracking from queue-order drift.

### WARNING-3: The drift persisted across most recorded days

Evidence:
- Inference recorded backward steps on every captured builder day from 2026-04-12 through 2026-04-23.
- Modernization recorded backward steps on every captured builder day from 2026-04-12 through 2026-04-23.
- Inference peaked at 40 backward steps on 2026-04-20 and 39 on 2026-04-22.
- Modernization peaked at 40 backward steps on 2026-04-22 and 29 on 2026-04-21.

Impact: this is a durable historical pattern rather than a one-day import artifact. Law 6 needs normalized queue provenance to explain why a lower queue number appears after a higher one.

### WARNING-4: Repeated task IDs blur retry versus duplicate-completion semantics

Evidence:
- `CQ-914` appears 6 times.
- `IQ-878`, `CQ-1118`, `CQ-1191`, and `CQ-1223` each appear 5 times.
- Several IQ rows, including `IQ-936`, `IQ-944`, `IQ-960`, `IQ-989`, and `IQ-990`, appear 4 times.

Impact: repeated task IDs can be legitimate retries, but the DB only stores `status = pass` for these builder rows and has no attempt outcome or retry reason. That makes duplicate queue consumption indistinguishable from successful rework in long-window audits.

### INFO-5: This can be repaired as an evidence contract without source writes

Evidence:
- The monotonicity drift is reproducible from `iterations.id`, `agent`, and numeric CQ/IQ suffixes.
- The audit deliberately excludes compound IDs, so it can be combined with the earlier compound task-id audit.
- No TempleOS or holyc-inference source changes are required to classify historical rows.

Impact: future rows should record `queue_attempt`, `queue_state_before`, `queue_state_after`, and `retry_reason` or move queue claims into a normalized `iteration_tasks` table. Historical rows should be scored as `queue_order_unknown` when they go backward without queue table support, not as automatically noncompliant.

## Key Aggregates

| Agent | Clean task rows | Min ID | Max ID | Backward steps | Below prior high-water | Immediate repeats |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 16 | 1,266 | 193 | 505 | 164 |
| modernization | 1,402 | 88 | 1,350 | 109 | 413 | 212 |

| Agent | Day | Rows | Backward steps | Below prior high-water |
| --- | --- | ---: | ---: | ---: |
| inference | 2026-04-20 | 202 | 40 | 62 |
| inference | 2026-04-22 | 224 | 39 | 130 |
| inference | 2026-04-21 | 219 | 38 | 89 |
| modernization | 2026-04-22 | 215 | 40 | 109 |
| modernization | 2026-04-21 | 238 | 29 | 65 |
| modernization | 2026-04-20 | 202 | 15 | 25 |

## Recommendations

- Add normalized queue-attempt fields before using `iterations.task_id` as Law 6 proof.
- Treat backward queue-ID rows as `unknown/retry-needed-evidence` unless the queue source proves invalid ordering.
- Preserve the queue table in the same archival snapshot as iterations; otherwise high-water checks cannot resolve whether older IDs were reopened work.
- Keep compound task-ID parsing and monotonicity scoring as separate checks so each evidence gap remains precise.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-queue-id-monotonicity-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
