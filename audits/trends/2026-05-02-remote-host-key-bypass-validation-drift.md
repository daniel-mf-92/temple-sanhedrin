# Remote Host-Key Bypass Validation Drift

Audit timestamp: 2026-05-02T03:07:02+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for remote SSH/SCP validation rows that disabled SSH host-key verification. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-remote-host-key-bypass-validation-drift.sql`

## Summary

The historical DB already showed that modernization relied on remote Azure validation. This narrower audit found that 165 of 194 remote modernization validation rows (`85.1%`) used `StrictHostKeyChecking=no`, while zero rows recorded a host-key pinning step such as `ssh-keyscan` or `known_hosts`. This is not evidence that the TempleOS guest had networking enabled; it is evidence that remote host validation provenance was weak exactly where Law 2 and Law 11 audits need strong trust-boundary records.

Findings: 5 total.

## Findings

### WARNING-1: Most remote modernization validation disabled host-key verification

Evidence:
- Modernization rows: 1,505.
- Remote modernization rows: 194.
- Remote rows with `StrictHostKeyChecking=no`: 165 (`85.1%`).
- Inference remote rows: 0.

Impact: a remote validation result can be useful, but a ledger that records host-key bypass cannot prove the remote host identity from the row alone. That weakens historical confidence in remote compile/QEMU evidence.

### WARNING-2: No matching host-key pinning evidence was recorded

Evidence:
- Modernization rows with `azureuser@52.157.85.234`: 183.
- Rows mentioning `ssh-keyscan` or `known_hosts`: 0.
- Rows using `UserKnownHostsFile=/dev/null`: 0.

Impact: the issue is not a documented alternate pinning mechanism. The central record shows a hard-coded remote target plus disabled host-key checking, but no durable proof that the expected host key was verified before accepting validation output.

### WARNING-3: The bypass overlaps Book-of-Truth and QEMU evidence

Evidence:
- Remote modernization rows with Book-of-Truth text or changed paths: 185.
- Remote modernization rows with QEMU text: 194.
- Remote rows with explicit no-network evidence in command/result/notes: 97.

Impact: this does not prove a guest air-gap breach. It shows that high-value Book-of-Truth and QEMU validation evidence often depended on a host-remote channel whose host identity was not authenticated in the ledger.

### WARNING-4: SCP was used for source transfer under the same bypass

Evidence:
- Remote SCP rows: 8.
- Sample rows include `CQ-521`, `CQ-527`, `CQ-534`, and `CQ-568`, which copied `Kernel/BookOfTruth.HC` and related files to `azureuser@52.157.85.234` with `scp -o StrictHostKeyChecking=no`.

Impact: SCP rows are higher-risk than remote read-only checks because they transfer source into the remote validation environment. A historical auditor cannot distinguish expected Azure validation from a substituted host when host-key checking is explicitly disabled.

### WARNING-5: The trend is concentrated during the late Book-of-Truth window

Evidence:
- 2026-04-19: 32 remote rows, 18 with host-key checking disabled, 5 SCP rows.
- 2026-04-20: 65 remote rows, 60 with host-key checking disabled.
- 2026-04-21: 31 remote rows, 28 with host-key checking disabled.
- 2026-04-22: 52 remote rows, 47 with host-key checking disabled.

Impact: this was not a single bootstrap exception. Host-key bypass became normal validation evidence during the same period where remote QEMU and Book-of-Truth work were most active.

## Key Aggregates

| Agent | Rows | Remote rows | Remote rows with host-key disabled | Remote SCP rows | Remote Book-of-Truth rows | Remote QEMU rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 | 0 |
| modernization | 1,505 | 194 | 165 | 8 | 185 | 194 |

| Day | Remote rows | Host-key disabled rows | SCP rows | Book-of-Truth rows |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-13 | 1 | 1 | 0 | 1 |
| 2026-04-15 | 1 | 1 | 0 | 1 |
| 2026-04-16 | 1 | 1 | 0 | 1 |
| 2026-04-19 | 32 | 18 | 5 | 32 |
| 2026-04-20 | 65 | 60 | 0 | 64 |
| 2026-04-21 | 31 | 28 | 1 | 31 |
| 2026-04-22 | 52 | 47 | 2 | 49 |
| 2026-04-23 | 11 | 9 | 0 | 6 |

## Recommendations

- Treat remote rows with `StrictHostKeyChecking=no` as low-provenance validation evidence in historical scoring.
- Add structured validation fields for `host_transport`, `remote_host_id`, `host_key_verified`, `remote_compile_only`, and `book_of_truth_output_seen`.
- Require future remote validation rows to include a pinned host-key fingerprint or classify the result as `remote_unverified`.
- Keep guest air-gap scoring separate from remote host identity scoring: `-nic none` can prove no guest NIC for a real QEMU invocation, but it does not authenticate the host that reported the result.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-remote-host-key-bypass-validation-drift.sql
```

Finding count: 5 warnings.
