# temple-central.db Book of Truth Signal Saturation Drift

Audit timestamp: 2026-05-01T17:54:44+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether modernization rows preserve specific Book of Truth law evidence, or whether broad `BookOfTruth` references have become too saturated to classify Law 3, Law 8, Law 9, Law 10, and Law 2 coverage. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-bookoftruth-signal-saturation-drift.sql`

## Summary

The modernization ledger is nearly saturated with Book of Truth references: 1,463 of 1,505 rows (`97.2%`) contain `BookOfTruth` or `Book of Truth` in notes, changed files, commands, or results. That is useful for broad WS13 visibility, but too coarse for law-specific trend scoring. Of those Book of Truth rows, 434 have no nearby signal for serial/UART proximity, hash/sealing immutability, fail-stop/HALT behavior, readonly image handling, or explicit air-gap evidence. Another 404 rows mention multiple law surfaces at once, making it difficult to tell which invariant a pass row actually validated.

Findings: 5 total.

## Findings

### WARNING-1: `BookOfTruth` is too saturated to be a useful law classifier by itself

Evidence:
- Modernization rows: 1,505.
- Rows with `BookOfTruth` / `Book of Truth` signal: 1,463 (`97.2%`).
- Rows with serial/UART/`0x3F8` signal: 646.
- Rows with hash/seal signal: 36.
- Rows with fail-stop/HALT signal: 212.
- Rows with readonly signal: 0.
- Rows with explicit air-gap/no-network signal: 699.

Impact: a long-window audit that treats `BookOfTruth` as equivalent to Law 3, Law 8, or Law 9 evidence will overcount coverage. The term mostly identifies the workstream, not the specific invariant proven.

### WARNING-2: 434 Book of Truth rows lack specific law-surface terms

Evidence:
- Book of Truth rows without serial/UART, hash/seal, fail-stop/HALT, readonly, or air-gap markers: 434.
- Recent examples include `CQ-1351/CQ-1352`, `CQ-1350`, `CQ-1346/CQ-1347`, and `CQ-1347`, all recorded as `exit 0` while their row text is dominated by source-mask/window/digest smoke-script names.

Impact: these rows may still be valid implementation progress, but the central ledger cannot classify them as Law 3 immutability, Law 8 hardware proximity, Law 9 crash-on-log-failure, Law 10 readonly image, or Law 2 air-gap evidence without reopening source or audit artifacts.

### WARNING-3: Multi-law signal rows blur which invariant passed

Evidence:
- Book of Truth rows with two or more law-specific signals: 404.
- Daily spikes include 2026-04-21 with 247 Book of Truth rows, 64 serial rows, 12 hash/seal rows, 26 fail-stop rows, and 163 air-gap rows; 2026-04-22 with 239 Book of Truth rows, 228 serial rows, 172 fail-stop rows, and 147 air-gap rows.

Impact: multi-signal rows are better than generic rows, but they still lack normalized proof fields. A row can mention serial, fail-stop, and air-gap in one command bundle while `validation_result` only says `exit 0`, so the DB cannot tell which sub-checks passed or skipped.

### WARNING-4: QEMU-heavy Book of Truth rows often collapse to `exit 0`

Evidence:
- Book of Truth rows with exact `validation_result = 'exit 0'`: 1,354.
- Book of Truth rows whose validation command mentions QEMU: 1,113.
- Book of Truth rows with both QEMU command evidence and exact `exit 0` result: 1,004.

Impact: this compounds earlier QEMU provenance concerns. The command text often shows wrapper use, but the result field does not preserve whether the QEMU phase ran, skipped, proved `-nic none`, or proved readonly image handling.

### INFO-5: The drift is an evidence-quality issue, not a direct violation

Evidence:
- The query found broad signal saturation and missing normalized law-surface detail; it did not execute QEMU, inspect live processes, or observe a guest network path.
- The readonly count is zero because the historical row text in this DB window does not carry that marker, not because current QEMU launchers were audited in this pass.

Impact: score these rows as `law_surface_unknown` unless a commit-level retro audit or source-specific artifact supplies the missing proof. The durable fix is structured evidence such as `law_surfaces_checked`, `qemu_airgap_proof`, `bot_serial_proof`, `bot_immutability_proof`, and `bot_failstop_proof`.

## Key Aggregates

| Metric | Rows |
| --- | ---: |
| Modernization rows | 1,505 |
| Book of Truth signal rows | 1,463 |
| Serial/UART/0x3F8 signal rows | 646 |
| Hash/seal signal rows | 36 |
| Fail-stop/HALT signal rows | 212 |
| Readonly signal rows | 0 |
| Air-gap/no-network signal rows | 699 |
| Book of Truth rows without specific law signal | 434 |
| Book of Truth rows with 2+ specific law signals | 404 |
| Book of Truth rows with generic `exit 0` | 1,354 |
| Book of Truth QEMU rows with generic `exit 0` | 1,004 |

## Recommendations

- Treat bare `BookOfTruth` text as workstream evidence, not proof of Law 3, Law 8, Law 9, Law 10, or Law 2 compliance.
- Add normalized law-surface fields to future builder inserts instead of relying on free-text path and command terms.
- For QEMU rows, record explicit sub-results for air-gap flags and readonly image handling rather than only `exit 0`.
- Preserve this report as historical scoring guidance; do not rewrite the central DB or sibling source repos.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-bookoftruth-signal-saturation-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
