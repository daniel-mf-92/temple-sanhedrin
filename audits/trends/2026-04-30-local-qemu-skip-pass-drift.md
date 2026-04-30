# temple-central.db Local QEMU Skip-as-Pass Drift

Timestamp: 2026-04-30T05:08:04+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder validation rows where local QEMU compile evidence was normalized as `pass` even though the QEMU compile phase skipped because the TempleOS ISO was unavailable. It did not inspect live loop liveness, run QEMU/VM commands, run SSH, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code.

Evidence snapshots:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `6417dc9f441c`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `4c523d358185`
- DB: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- SQL: `audits/trends/2026-04-30-local-qemu-skip-pass-drift.sql`

## Summary

The historical builder ledger contains 108 modernization pass rows whose `validation_result` says the local QEMU compile or boot phase skipped because the ISO was unavailable. That is 7.18% of modernization rows and 0% of inference rows. The affected rows are not harmless metadata closures: 97 touch `Kernel/`, 101 touch Book-of-Truth surfaces, and 108 invoke `automation/qemu-compile-test.sh`.

Findings: 5 total.

## Findings

### WARNING-1: Local QEMU compile skip was recorded as successful validation

Evidence:
- Builder window: 2,919 rows from 2026-04-12T13:51:32 through 2026-04-23T12:06:44.
- Modernization rows: 1,505.
- Modernization pass rows whose result contains both `skip` and `ISO`: 108.
- Inference rows with the same shape: 0.

Impact: Law 5 scoring can over-credit implementation rows as validated by local QEMU even when the ledger text says the QEMU phase did not run.

### WARNING-2: The skip-as-pass rows concentrate in Book-of-Truth work

Evidence:
- Of 108 affected rows, 97 changed `Kernel/` paths.
- 101 changed paths or notes mentioning `BookOfTruth`.
- First examples include `CQ-115`, `CQ-117`, `CQ-119`, `CQ-130`, `CQ-139`, and `CQ-147`, all marked pass while the result says the QEMU compile harness skipped because the ISO was unavailable.

Impact: high-risk Laws 3, 8, 9, 10, and 11 rely on runtime-adjacent evidence. Rows where the local runtime phase skipped should be classified separately from rows that actually booted and compiled inside the air-gapped guest.

### WARNING-3: The current compile harness still exits 0 on failed ISO fetch

Evidence:
- `TempleOS/automation/qemu-compile-test.sh:23-29` attempts to download `https://templeos.org/Downloads/TempleOS.ISO` when `automation/TempleOS.iso` is missing.
- On `curl` failure it prints a warning and `exit 0`.
- The same script later launches QEMU with `-nic none` when an ISO is present, so guest networking is disabled in the launch path.

Impact: the guest air-gap flag is preserved for real QEMU runs, but missing local ISO evidence collapses into success. Future audits need to distinguish "guest booted with `-nic none`" from "host skipped guest boot because ISO was absent."

### WARNING-4: Remote fallback and local skip are mixed in one pass status

Evidence:
- Eight affected rows also contain `ssh` in `validation_cmd`.
- Nine affected rows mention `remote` or `azure` in `validation_result`.
- Examples include `CQ-584`, `CQ-656`, and `CQ-699`, which record local ISO skip plus remote/Azure compile success.

Impact: a remote compile may be useful as host-side evidence, but it is not equivalent to local physical Book-of-Truth validation. A single `status = pass` field cannot preserve this trust-boundary distinction.

### INFO-5: The drift is time-bounded and backfillable

Evidence:
- Daily affected rows: 12 on 2026-04-12, 19 on 2026-04-13, 1 on 2026-04-18, 13 on 2026-04-19, 20 on 2026-04-20, 30 on 2026-04-21, and 13 on 2026-04-22.
- No affected rows appear for inference.
- The result strings consistently include `ISO`, `skip`, `unavailable`, or equivalent wording, so the historical rows can be tagged conservatively.

Impact: backfill can mark these rows as `local_qemu_skipped` without re-running QEMU or touching builder repos.

## Source Counts

| Metric | Count |
| --- | ---: |
| Builder rows | 2,919 |
| Modernization rows | 1,505 |
| Inference rows | 1,414 |
| Modernization pass rows with `skip` in validation result | 108 |
| Modernization pass rows with `ISO` in validation result | 109 |
| Modernization pass rows with both `skip` and `ISO` | 108 |
| Affected rows changing `Kernel/` paths | 97 |
| Affected rows touching Book-of-Truth surfaces | 101 |
| Affected rows invoking `qemu-compile-test.sh` | 108 |
| Affected rows whose command includes `ssh` | 8 |
| Affected rows whose result mentions `remote` or `azure` | 9 |

## Recommendations

- Change future validation schema from one `status` to per-phase outcomes such as `shell_syntax`, `fixture_smoke`, `local_qemu_compile`, `remote_compile`, and `book_of_truth_runtime`.
- Treat local QEMU skip rows as `pass_with_unrun_local_qemu`, not clean pass, when scoring Law 5 and Book-of-Truth laws.
- Make the QEMU compile harness fail closed when an expected ISO is absent, or require an explicit `ALLOW_QEMU_SKIP=1` result marker that central ingestion records as skipped.
- Keep `-nic none` as mandatory for actual QEMU invocations and record whether a QEMU invocation actually occurred.

## Read-Only Verification Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-local-qemu-skip-pass-drift.sql
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh | sed -n '1,120p'
```
