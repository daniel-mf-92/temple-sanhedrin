# Historical Remote QEMU Validation Provenance Drift Audit

- Audit angle: historical drift trends
- Timestamp: 2026-05-01T07:08:50Z
- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Scope note: read-only SQLite queries only. No TempleOS guest, QEMU, VM, SSH, network, WS8, or builder-repo write was executed.
- Query artifact: `audits/trends/2026-05-01-remote-qemu-validation-provenance-drift.sql`

## Invariant Under Audit

Historical validation records should preserve enough provenance for Sanhedrin to distinguish:

- local host-side checks from remote host checks,
- QEMU wrapper invocation from the exact QEMU safety flags it implies,
- explicit Law 2 air-gap evidence (`-nic none` or `-net none`) from wrapper-name-only evidence,
- network-dependent validation dependencies from local reproducible validation.

This pass audited only central DB rows from `iterations`, not live processes.

## Data Summary

The database contains 14,606 rows. Builder rows cover:

- modernization: 1,505 rows from `2026-04-12T13:51:32` through `2026-04-23T12:01:29`
- inference: 1,414 rows from `2026-04-12T13:53:13` through `2026-04-23T12:06:44`
- sanhedrin: 11,687 rows

Modernization recorded 1,153 QEMU-related validation rows. Inference recorded 0 QEMU-related validation rows in `validation_cmd`.

## Findings

### 1. WARNING: Modernization QEMU evidence is wrapper-name-heavy and command-flag-light

Evidence:

- Modernization has 1,153 QEMU-related builder validation rows.
- Only 1 of those rows contains literal `-nic none` or `-net none` in `validation_cmd`.
- 940 rows mention `qemu-compile-test.sh`, 1,058 mention `qemu-headless.sh`, and 376 mention `qemu-smoke.sh`.

Assessment:
Most historical QEMU evidence relies on wrapper names rather than durable final argv evidence. That weakens retroactive Law 2 review because wrapper semantics can change over time and the central row alone usually cannot prove what no-network flag was used.

### 2. WARNING: Remote Azure validation became a recurring modernization dependency

Evidence:

- Modernization has 194 builder validation rows containing `ssh`, `azureuser@`, or `52.157.85.234`.
- Daily remote-row share rises from isolated early rows to 22.5% on 2026-04-19, 28.9% on 2026-04-20, 21.1% on 2026-04-22, and 32.4% on 2026-04-23.
- Recent examples include rows such as `CQ-1351/CQ-1352`, `CQ-1242`, `CQ-1328`, and `CQ-1310` invoking Azure QEMU compile checks by SSH.

Assessment:
This is not evidence that the TempleOS guest had networking enabled. It is a validation-provenance drift: a large fraction of modernization pass evidence depends on a remote host path, so local replayability and audit trust now depend on preserving remote command text and remote air-gap markers.

### 3. INFO: No central builder validation rows record direct network fetch commands

Evidence:

- Across modernization and inference builder rows, `validation_cmd` matches for `curl`, `wget`, `http://`, and `https://` were 0.

Assessment:
The central DB does not show builder validation commands directly fetching packages or artifacts. This is a positive Law 2 signal, separate from the remote SSH validation dependency above.

### 4. WARNING: Ten modernization QEMU rows lack both explicit no-network flags and known wrapper anchors

Evidence:

- The query found 10 modernization rows where `validation_cmd` contains `qemu` but contains neither literal `-nic none`/`-net none` nor known wrapper names `qemu-compile-test.sh`, `qemu-headless.sh`, or `qemu-smoke.sh`.
- Examples include shorthand evidence such as `local smoke + qemu compile + azure qemu compile`, `local+azure qemu-compile-test`, and truncated long-script rows.

Assessment:
These rows may correspond to safe wrapper executions, but the central text is too compressed to prove it. Future rows should avoid shorthand like `qemu compile` unless they also include exact wrapper names or the effective QEMU flags.

### 5. WARNING: Timestamp normalization defects still contaminate long-window trend queries

Evidence:

- 27 rows have `ts` values that do not match `YYYY-MM-DDTHH:MM:SS`.
- Examples include space-separated timestamps (`2026-04-17 17:19:07`, `2026-04-19 13:21:21`), numeric Unix-like values (`1776539926`), and `Z`-suffixed values (`2026-04-19T15:10:32Z`).
- The aggregate `min(ts)` is `1776539926`, which is lexically earlier than the ISO timestamps and can distort naive min/max windows.

Assessment:
Historical drift reports should normalize timestamps before ordering or windowing. Otherwise early/late buckets and first/last seen summaries can silently misclassify rows.

## Non-Findings

- No QEMU, VM, SSH, or network command was executed during this audit.
- No inference builder rows in this DB snapshot recorded QEMU validation commands.
- No central builder row showed direct `curl`, `wget`, `http://`, or `https://` in `validation_cmd`.
- Remote host validation was not classified as a TempleOS guest air-gap breach by itself.

## Recommended Follow-Up

- Add exact final QEMU argv metadata to central DB rows or sidecar artifacts for every QEMU wrapper run.
- Split validation provenance into local, remote-host, and guest-safety fields instead of encoding all evidence into one free-text `validation_cmd`.
- Normalize `ts` to a single ISO-8601 form before trend aggregation and reject malformed timestamps on insert.
- For remote SSH validation, require recorded remote command text and explicit guest no-network evidence in the row or linked artifact.

## Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-remote-qemu-validation-provenance-drift.sql
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db "select count(*) as rows, min(ts) as min_ts, max(ts) as max_ts from iterations;"
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db "with b as (select * from iterations where agent in ('modernization','inference')) select agent, count(*) as rows, sum(validation_cmd like '%qemu%') as qemu_rows, sum(validation_cmd like '%-nic none%' or validation_cmd like '%-net none%') as no_network_rows, sum(validation_cmd like '%ssh %' or validation_cmd like '%52.157.85.234%' or validation_cmd like '%azureuser@%') as remote_rows from b group by agent;"
```

