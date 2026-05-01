# temple-central.db QEMU Air-Gap Command Evidence Drift

Audit timestamp: 2026-05-01T21:24:20+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder rows whose `validation_cmd` referenced QEMU and then checked whether the row preserved explicit `-nic none` / `-net none` evidence. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `42d2c3a2de67`
- SQL: `audits/trends/2026-05-01-qemu-airgap-command-evidence-drift.sql`

## Summary

The historical ledger strongly suggests the modernization loop intended to preserve the air-gap, but it does not consistently retain command-level proof. Across 1,505 modernization rows, 1,153 rows recorded a QEMU validation command. Only 1 of those QEMU rows preserved `-nic none` or `-net none` directly in `validation_cmd`. Another 281 rows had the disable flag elsewhere in the row text, and 449 rows had air-gap prose such as `air-gapped`, `no-network`, or `no guest networking`. The remaining 422 QEMU rows had no literal disable flag and no row-level air-gap wording, including 289 rows touching core paths.

Findings: 5 total.

## Findings

### WARNING-1: QEMU validation commands are not self-contained air-gap evidence

Evidence:
- Modernization QEMU command rows: 1,153.
- Rows with `-nic none` or `-net none` directly in `validation_cmd`: 1.
- Rows missing the literal disable flag in `validation_cmd`: 1,152.

Impact: Law 2 says any QEMU/VM command must explicitly disable networking. The DB often records wrapper invocations such as `automation/qemu-headless.sh` or `automation/qemu-compile-test.sh`, not the resolved VM argv. A historical auditor cannot prove from `validation_cmd` alone that each VM launch used `-nic none` or `-net none`.

### WARNING-2: 422 QEMU rows lack both disable flags and air-gap prose

Evidence:
- QEMU rows with no command-level disable flag, no row-level disable flag, and no air-gap wording: 422.
- First affected timestamp: 2026-04-12T13:59:16.
- Latest affected timestamp: 2026-04-23T12:01:29.
- Recent examples include `CQ-1351/CQ-1352`, `CQ-1350`, `CQ-1243/CQ-1244/CQ-1245`, `CQ-1242`, `CQ-1330`, and `CQ-1328`.

Impact: this is an evidence gap, not proof that networking was enabled. The rows usually reference host wrappers that may enforce air-gap internally. The ledger still fails as a standalone Law 2 proof because it omits both the exact QEMU argv and any concise air-gap assertion.

### WARNING-3: 289 of the no-evidence QEMU rows touch core paths

Evidence:
- Rows with no disable/air-gap evidence and core path changes: 289.
- Latest examples include Book-of-Truth and scheduler rows touching `Kernel/BookOfTruth.HC`, `Kernel/Sched.HC`, and `Kernel/KExts.HC`.

Impact: core TempleOS changes are the highest-value rows for retroactive Law 2 review. When their validation evidence is only a wrapper name plus `exit 0`, the audit must re-open scripts or commits to recover the actual VM safety posture.

### INFO-4: No builder rows include protocol implementation terms

Evidence:
- Inference rows with QEMU commands: 0.
- Inference rows with protocol terms in this audit: 0.
- Modernization rows with protocol implementation terms matched by this SQL (`socket`, `tcp`, `udp`, `dns`, `dhcp`, `http`, `tls`): 0.

Impact: the drift is concentrated in VM launch evidence recording, not in apparent guest networking implementation. This supports keeping the remediation scoped to audit/ledger evidence, not trinity source code changes from this sibling.

### INFO-5: The evidence gap is backfillable from read-only data

Evidence:
- Rows with row-level disable flags outside `validation_cmd`: 281.
- Rows with air-gap prose but no literal disable flag: 449.
- The SQL classifies exact command evidence, row-level flag evidence, prose-only air-gap evidence, core-path touches, SSH mentions, and protocol terms without touching builder repos.

Impact: future ledger ingestion can store resolved VM argv separately, while existing rows can be scored as `literal flag`, `row evidence`, `prose evidence`, or `missing evidence`.

## Key Aggregates

| Agent | Rows | QEMU Command Rows | Literal Disable In Command | Missing Literal Disable | Row Has Disable Elsewhere | Air-Gap Prose Only | No Disable/Air-Gap Evidence | No-Evidence Core Rows | Protocol Term Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| modernization | 1,505 | 1,153 | 1 | 1,152 | 281 | 449 | 422 | 289 | 0 |

| Day | QEMU Rows | Literal Disable | Row Disable Only | Prose Only | No Evidence |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-04-12 | 77 | 0 | 7 | 53 | 17 |
| 2026-04-13 | 113 | 0 | 17 | 75 | 21 |
| 2026-04-15 | 21 | 0 | 0 | 6 | 15 |
| 2026-04-16 | 53 | 0 | 8 | 9 | 36 |
| 2026-04-17 | 89 | 0 | 21 | 24 | 44 |
| 2026-04-18 | 85 | 0 | 9 | 19 | 57 |
| 2026-04-19 | 98 | 1 | 45 | 19 | 33 |
| 2026-04-20 | 167 | 0 | 62 | 54 | 51 |
| 2026-04-21 | 200 | 0 | 55 | 87 | 58 |
| 2026-04-22 | 222 | 0 | 53 | 90 | 79 |
| 2026-04-23 | 28 | 0 | 4 | 13 | 11 |

## Recommendations

- Record the resolved QEMU argv in a normalized field whenever validation launches or delegates to a VM wrapper.
- Treat wrapper-only QEMU command strings as insufficient standalone Law 2 evidence unless a companion field records `-nic none` or `-net none`.
- Preserve a structured `airgap_evidence_kind` value such as `literal_argv`, `wrapper_verified`, `prose_only`, or `missing`.
- Keep WS8/networking execution out of scope; this audit found no builder rows requiring WS8 execution.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-qemu-airgap-command-evidence-drift.sql
```

Finding count: 5 total, 3 warnings and 2 info.
