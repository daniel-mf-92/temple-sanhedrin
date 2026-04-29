# temple-central.db Book-of-Truth Hardware-Proximity Evidence Drift

Audit timestamp: 2026-04-29T02:39:25+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for Book-of-Truth hardware-proximity evidence, then spot-checked current TempleOS source paths without modifying TempleOS or holyc-inference.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder repos checked read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Query pack: `audits/trends/2026-04-29-bookoftruth-hardware-proximity-evidence-drift.sql`
- LAWS.md focus: Law 8 Book-of-Truth immediacy and hardware proximity, with secondary Law 3/Law 9 relevance where serial evidence is used to prove ledger integrity.

## Findings

1. WARNING - `temple-central.db` records Book-of-Truth breadth but not the Law 8 hardware-near proof tokens.
   - Evidence: modernization has 1,449 rows with Book-of-Truth terms in notes/files and 1,457 rows with Book-of-Truth validation terms, but 0 rows with `0x3f8`, 0 rows with `rdtsc`, and 0 rows with `rdmsr`.
   - Impact: historical trend reports can prove the builder was repeatedly working near Book-of-Truth functionality, but they cannot prove the Law 8-specific raw UART/TSC/MSR clauses from structured database evidence.

2. WARNING - Serial validation rose over time, but the database signal remains semantic rather than hardware-address-specific.
   - Evidence: modernization has 583 validation rows mentioning serial or UART. Daily notes/files mention serial/UART on 11 rows on 2026-04-12, 63 on 2026-04-18, and 227 on 2026-04-22, yet every day has 0 `0x3f8` rows.
   - Impact: serial smoke coverage exists historically, but a regression from direct COM1 access to a wrapper or proxy could be missed unless scanners inspect source or audit artifacts outside the database.

3. WARNING - Law 8 proximity wording is nearly absent from builder iteration records.
   - Evidence: only 1 modernization row contains `inline` or `synchronous` in the combined iteration fields, and inference has 7 such rows. The sole modernization hit is an optional consensus-suite note, not a direct hardware-proximity proof.
   - Impact: Sanhedrin cannot trend whether the builder increasingly satisfies the "same instruction sequence" requirement from iteration metadata alone.

4. WARNING - The `violations` table is empty despite later audit artifacts finding Law 8/Law 9 critical issues.
   - Evidence: `select count(*) from violations` returns 0. Audit artifacts outside the DB include critical historical findings for wrappered `GetMSR`/`GetTSC`, IRQ hook indirection, logical-not-hardware sealing, and configurable serial fail-stop behavior.
   - Impact: long-window queries over `temple-central.db` undercount safety regressions unless audit findings are backfilled into `violations` or joined from audit markdown.

5. INFO - Current TempleOS source still contains direct COM1 and Book-of-Truth append surfaces, but also the known Law 8 evidence patterns that require source-level auditing.
   - Evidence: focused read-only grep found `BOT_COM1_BASE 0x3F8`, `InU8(BOT_COM1_BASE+...)`, `OutU8(BOT_COM1_BASE+...)`, and many `BookTruthAppend(...)` calls. It also found `GetMSR`, `GetTSC`, `IRQTimerHook -> BookTruthIRQHook`, `BookTruthWXAllow`, and `BookTruthDMARecord`, matching previously reported proximity concerns.
   - Impact: the database trend should be treated as an observability warning, not proof that current source violates every Law 8 clause. Source/audit-artifact checks remain required for authoritative judgment.

## Supporting Extracts

| Agent | Rows | First timestamp | Last timestamp |
| --- | ---: | --- | --- |
| inference | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 |
| modernization | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 |

| Agent | Rows | BoT notes/files | BoT validation | Serial validation | `0x3f8` | `rdtsc` | `rdmsr` | Proximity terms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 2 | 2 | 0 | 0 | 0 | 0 | 7 |
| modernization | 1,505 | 1,449 | 1,457 | 583 | 0 | 0 | 0 | 1 |

Modernization day-level evidence:

| Day | Rows | BoT rows | Serial rows | `0x3f8` rows | Proximity rows |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-04-12 | 85 | 80 | 11 | 0 | 0 |
| 2026-04-13 | 137 | 120 | 21 | 0 | 0 |
| 2026-04-15 | 31 | 31 | 4 | 0 | 0 |
| 2026-04-16 | 68 | 67 | 6 | 0 | 0 |
| 2026-04-17 | 143 | 143 | 33 | 0 | 0 |
| 2026-04-18 | 146 | 146 | 63 | 0 | 0 |
| 2026-04-19 | 142 | 142 | 50 | 0 | 0 |
| 2026-04-20 | 225 | 221 | 19 | 0 | 1 |
| 2026-04-21 | 248 | 244 | 51 | 0 | 0 |
| 2026-04-22 | 246 | 239 | 227 | 0 | 0 |
| 2026-04-23 | 34 | 16 | 8 | 0 | 0 |

Post-database cutoff context:

- Latest database builder timestamps stop at 2026-04-23T12:06:44.
- Current read-only heads inspected: TempleOS `9ecc6aa996307f8e20f05a843c4188ad7f72f6dd`, holyc-inference `ce09228422dae06e86feb84925d51df88d67821b`.
- TempleOS has 62 post-cutoff commits touching focused Law 8 paths: `Kernel/BookOfTruth.HC`, `Kernel/BookOfTruthSerialCore.HC`, `Kernel/KInts.HC`, or `Kernel/Mem/MemPhysical.HC`.

## Commands

```text
sqlite3 -readonly /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-bookoftruth-hardware-proximity-evidence-drift.sql
rg -n "0x3F8|BOT_COM1_BASE|OutU8|InU8|RDMSR|RDTSC|GetMSR|GetTSC|BookTruthAppend|BookTruthSerialEmit|IRQTimerHook|BookTruthIRQHook|BookTruthWXAllow|BookTruthDMARecord" Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC Kernel/KInts.HC Kernel/Mem/MemPhysical.HC Kernel/KUtils.HC Compiler/OptPass3.HC Compiler/CompilerA.HH
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --since='2026-04-23T12:06:44' --all --oneline -- Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC Kernel/KInts.HC Kernel/Mem/MemPhysical.HC
```

## Recommendations

- Backfill audit findings into `violations` with law id, severity, evidence path, commit SHA, and resolution state so long-window trend queries do not miss known Law 8/Law 9 regressions.
- Add structured iteration evidence fields or a normalized evidence table for `uart_port=0x3F8`, `raw_rdtsc`, `raw_rdmsr`, `inline_isr_hook`, `pte_mutation_inline`, `serial_halt_on_dead`, and `qemu_no_network`.
- Treat `serial` and `Book of Truth` text as broad discovery terms only; require raw-address and raw-instruction tokens or source-level checks for Law 8 conclusions.
- Keep post-2026-04-23 Law 8 trend claims tied to git/audit artifacts until `temple-central.db` ingestion resumes or a commit/audit backfill is imported.
