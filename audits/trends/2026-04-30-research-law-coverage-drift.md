# temple-central.db Research LAWS.md Coverage Drift

Timestamp: 2026-04-30T03:00:23+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for deep-research ledger coverage against LAWS.md safety doctrine. It did not inspect live loop liveness, run QEMU/VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code.

SQL: `audits/trends/2026-04-30-research-law-coverage-drift.sql`

## Summary

The historical `research` table is overwhelmingly a repeat-task remediation ledger, not a balanced LAWS.md research ledger. Of 444 research rows from 2026-04-15 through 2026-04-23, 437 rows match repeat/stuck/loop/retry language, while only 9 rows mention any safety-law surface such as HolyC, air-gap, networking, QEMU, integer purity, serial, immutable image, or local access. Several high-risk laws have no direct research rows by keyword surface.

Findings: 5 total.

## Findings

### WARNING-1: Deep research is saturated by repeat-task remediation

Evidence:
- Research rows: 444.
- Repeat/stuck/loop/retry rows: 437.
- Law/safety-surface rows: 9.

Impact: the deep-research channel is not giving proportional historical attention to the immutable safety doctrine. This creates a blind spot for retroactive ambiguity discovery in Laws 1-4 and 8-11.

### WARNING-2: Safety-law coverage is compressed into two days

Evidence:
- No law/safety-surface rows appear on 2026-04-15, 2026-04-16, 2026-04-17, 2026-04-19, 2026-04-20, or 2026-04-23.
- One law/safety-surface row appears on 2026-04-21.
- Eight law/safety-surface rows appear on 2026-04-22.

Impact: safety-doctrine research appears reactive and bursty, not a stable background control. Long windows can pass with no recorded LAWS.md-focused research despite active builder work.

### WARNING-3: Multiple high-risk law surfaces have zero direct research hits

Evidence:
- Law 3 Book of Truth immutability: 0 matching rows.
- Law 8 hardware proximity: 0 matching rows.
- Law 10 immutable OS image: 0 matching rows.
- Law 11 local access only: 0 matching rows.

Impact: these are high-severity modernization constraints. Zero research-ledger coverage means ambiguity analysis and edge-case refinement for the most safety-critical doctrines is not historically visible in `temple-central.db`.

### WARNING-4: Queue/liveness terms dominate even the law keyword matrix

Evidence:
- Law 7 liveness/stuck/process/heartbeat surface: 190 matching rows.
- Law 6 queue/CQ/IQ surface: 77 matching rows.
- Law 2 air-gap/network/QEMU surface: 3 matching rows.
- Law 1 HolyC surface: 1 matching row.

Impact: even when mapped onto LAWS.md, the research table mostly reflects operational loop management. Safety boundaries such as air-gap and HolyC purity are not represented at comparable depth.

### INFO-5: Top trigger-task concentration confirms repeat-loop shape

Evidence:
- `AUDIT` appears in 41 rows.
- `CQ-1223` and `IQ-990` each appear in 10 rows.
- Several combined repeated-task triggers such as `CQ-914/IQ-878` and `CQ-877/IQ-839/IQ-842/IQ-844` appear near the top.

Impact: the research table is useful for diagnosing task repetition, but it should not be treated as a complete record of deep LAWS.md research.

## Source Counts

| Metric | Count |
| --- | ---: |
| Research rows | 444 |
| Repeat/stuck/loop/retry rows | 437 |
| Law/safety-surface rows | 9 |
| Rows with blank references | 76 |
| First research timestamp | 2026-04-15T16:02:12 |
| Last research timestamp | 2026-04-23T05:59:23 |

| LAWS.md Surface | Matching Rows |
| --- | ---: |
| Law 1 HolyC purity | 1 |
| Law 2 air-gap/network/QEMU | 3 |
| Law 3 Book of Truth immutability | 0 |
| Law 4 integer purity | 2 |
| Law 5 no busywork/north star | 2 |
| Law 6 queue health | 77 |
| Law 7 liveness/stuck/process | 190 |
| Law 8 hardware proximity/UART/TSC/MSR | 0 |
| Law 9 resource supremacy/crash | 1 |
| Law 10 immutable image | 0 |
| Law 11 local access only | 0 |

## Recommendations

- Add `law_id` or `law_surface` to `research` rows so deep research can be tracked against LAWS.md directly instead of inferred from free text.
- Reserve a periodic research quota for hard safety laws, especially Laws 2, 3, 8, 10, and 11.
- Keep repeat-task research, but classify it separately from LAWS.md doctrine research.
- Add a Sanhedrin trend guard that warns when seven consecutive research days have no rows for air-gap, HolyC purity, Book of Truth immutability, hardware proximity, immutable image, or local-only access.

## Read-Only Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema research'
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-research-law-coverage-drift.sql
```
