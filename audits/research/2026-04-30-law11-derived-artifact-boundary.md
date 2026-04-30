# Law 11 Derived-Artifact Boundary Research

Timestamp: 2026-04-30T16:36:59+02:00

Audit angle: deeper `LAWS.md` research.

Scope:
- Sanhedrin `LAWS.md` at `f2793b5d97fab65df8672c7951db1ff3bfa7db5a`.
- TempleOS committed head observed read-only: `1f7905e4cac05a7b0792d8ca5e9f1eb492c39fec`.
- holyc-inference committed head observed read-only: `a70776642a09de7ed01eb75aaaebbdd3243f84c2`.

No TempleOS or holyc-inference source files were modified. No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed.

## Question

When Book-of-Truth serial bytes cannot leave the local console, which derived artifacts are still legal to keep in reports, dashboards, benchmarks, and replay manifests?

The prior serial-locality issue defines where the serial mirror may be observed. This pass examines a second boundary: whether summaries derived from local serial observation become prohibited "log contents" under Law 11.

## Evidence

- `LAWS.md:151-159` forbids any code path that makes Book-of-Truth log contents available outside the local console, including log export commands and serial output forwarding.
- holyc-inference committed tooling stores serial-derived metrics such as `serial_output_bytes_total`, `serial_output_bytes_max`, serial-byte deltas, and dashboard/report JSON in `bench/bench_artifact_manifest.py`, `bench/bench_result_index.py`, and `bench/build_compare.py`.
- holyc-inference committed task text uses "export" language for Book-of-Truth-facing tuples, for example `PrefixCacheExportAuditRowsChecked` and `PrefixCacheExportAuditRowsCheckedNoPartial` in `MASTER_TASKS.md`.
- Existing audits already classify raw serial tails and remote serial observation as Law 11 risks, but `LAWS.md` does not state whether counts, hashes, redacted status bits, or synthetic fixture summaries are safe derived artifacts.

## Findings

1. **WARNING - Law 11 does not define a safe derived-artifact class.**
   Evidence: the law forbids making "log contents" available outside the local console, but it does not distinguish raw ledger rows from non-content proof fields such as byte counts, hash-chain roots, status bits, sequence ranges, local-observer attestations, or redacted pass/fail summaries.
   Impact: auditors may either over-block harmless proof tuples or under-block reports that contain enough serial-derived data to reconstruct sensitive Book-of-Truth content.

2. **WARNING - Serial byte metrics are useful but underclassified.**
   Evidence: holyc-inference committed reports track serial output byte totals and maxima. These fields are not raw log text, but they are derived from the same serial channel that may later carry Book-of-Truth token, GPU, policy, or attestation rows.
   Impact: serial byte counts should be explicitly permitted only as non-content telemetry; otherwise dashboards can silently drift from performance evidence into local-only log evidence.

3. **WARNING - "Export" remains overloaded between local formatting and forbidden disclosure.**
   Evidence: Law 11 bans log export commands, while inference task/source vocabulary uses "export" for audit tuple production. This may be implementation-local and safe, but the term is risky when used near Book-of-Truth bridge work.
   Impact: naming and docs can train builders to create portable Book-of-Truth artifacts unless LAWS.md reserves "export" for forbidden disclosure and uses "render", "summarize", or "local proof tuple" for allowed local derivations.

4. **INFO - A practical boundary can preserve auditability without leaking logs.**
   Evidence: current reports can keep structured non-content fields: command hash, launch hash, environment hash, serial byte counts, chain-root/hash digest, sequence range, event counts, redaction status, synthetic-fixture marker, and local-observer classification.
   Impact: Sanhedrin can still audit Law 2, Law 8, Law 9, and Law 11 evidence without storing raw Book-of-Truth rows or making them remotely viewable.

## Proposed LAWS.md Refinement

Add this note under Law 11:

```text
Derived-artifact exception: reports may retain non-content proof fields derived from local Book-of-Truth observation, such as byte counts, event counts, sequence ranges, hash-chain roots, command/environment hashes, redaction status, and local-observer classification. They must not contain raw ledger rows, token text, payload bytes, screenshots, serial tails, removable-media copies, or any field sufficient to reconstruct Book-of-Truth contents. Every derived artifact must say whether it is `raw_local_only`, `redacted_summary`, `hash_only`, `synthetic_fixture`, or `compile_only_no_bot`.
```

Add this audit rule:

```text
Any artifact that includes serial-derived evidence but lacks a content class (`raw_local_only`, `redacted_summary`, `hash_only`, `synthetic_fixture`, or `compile_only_no_bot`) is a Law 11 WARNING. Any committed, remotely accessible, or transferred artifact containing raw Book-of-Truth rows is a Law 11 CRITICAL violation.
```

## Local Issue Opened

See `audits/issues/2026-04-30-law11-derived-artifact-boundary-issue.md`.

