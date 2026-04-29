# Historical Validation-Evidence / Air-Gap Drift Audit

Timestamp: 2026-04-29T10:23:28+02:00
Scope: `temple-central.db` historical `iterations` rows, 2026-04-12 through 2026-04-23.
Audit angle: historical drift trends.
Repos under audit: `TempleOS` modernization rows and `holyc-inference` inference rows.
Source query file: `audits/trends/2026-04-29-validation-evidence-airgap-drift.sql`

No trinity source files were modified. No QEMU or VM command was executed. This report only reads historical rows from `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`.

## Summary

The long-window evidence shows a modernization validation drift: many rows recorded `exit 0` while depending on remote SSH execution or while the local QEMU stage was skipped because the ISO was unavailable. This weakens retroactive Law 2 and Law 5 auditability because the historical record cannot consistently prove a local, air-gapped, `-nic none` guest execution path.

## Findings

1. **WARNING - Modernization validation relied on remote SSH in 194 / 1,505 rows.**
   Evidence: `validation_cmd LIKE '%ssh %'` matched 194 modernization rows; 183 mention `azureuser@`. Daily concentration was highest on 2026-04-20 with 65 rows, then 2026-04-22 with 52 rows and 2026-04-19 with 32 rows. Law 2 forbids network-dependent build steps; even when the guest may remain air-gapped, the historical validation chain is network-dependent.

2. **WARNING - Only 5 / 1,505 modernization rows explicitly record `-nic none`.**
   Evidence: `validation_cmd LIKE '%-nic none%' OR validation_result LIKE '%-nic none%'` matched only 5 modernization rows. The other rows may have used a safe wrapper, but the database evidence itself usually does not prove the hard air-gap requirement.

3. **WARNING - 108 modernization pass rows record QEMU/ISO skip semantics.**
   Evidence: ISO-unavailable or skipped-QEMU terms matched 108 modernization rows. Examples include `exit 0 (QEMU compile skipped: ISO download unavailable on air-gapped host)` and `exit 0 (QEMU stage skipped: ISO download unavailable)`. These rows often still show source changes, including 334 added lines for `CQ-1229` and 638 added lines for `CQ-1186/CQ-1187`.

4. **WARNING - Builder duration telemetry is absent across all historical builder rows.**
   Evidence: `duration_sec IS NULL` for 1,505 / 1,505 modernization rows and 1,414 / 1,414 inference rows. This blocks long-window detection of slow, hung, or suspiciously short iterations without reconstructing timing from adjacent timestamps.

5. **INFO - Inference validation evidence is materially stronger on this axis.**
   Evidence: inference rows show 0 remote SSH validations, 0 ISO/QEMU skip rows, and 0 missing validation command/result rows across 1,414 rows. This does not prove semantic correctness, but it makes inference validation more locally auditable than modernization validation in the historical database.

## Daily Modernization Drift

| Day | Rows | Remote SSH | ISO/QEMU skip rows |
|---|---:|---:|---:|
| 2026-04-12 | 85 | 0 | 12 |
| 2026-04-13 | 137 | 1 | 19 |
| 2026-04-15 | 31 | 1 | 0 |
| 2026-04-16 | 68 | 1 | 0 |
| 2026-04-17 | 143 | 0 | 0 |
| 2026-04-18 | 146 | 0 | 1 |
| 2026-04-19 | 142 | 32 | 13 |
| 2026-04-20 | 225 | 65 | 20 |
| 2026-04-21 | 248 | 31 | 30 |
| 2026-04-22 | 246 | 52 | 13 |
| 2026-04-23 | 34 | 11 | 0 |

## Recommendations

- Treat remote SSH-backed modernization validation as insufficient for Law 2 evidence unless the row also records the exact remote QEMU command and explicit `-nic none`.
- Record local wrapper safety proof in `validation_result`, not only `exit 0`.
- Split fixture/syntax success from guest compile/boot success so ISO-unavailable skips cannot appear as equivalent pass evidence.
- Populate `duration_sec` for builder and Sanhedrin rows to support historical liveness and stuck-process analysis without live watching.
