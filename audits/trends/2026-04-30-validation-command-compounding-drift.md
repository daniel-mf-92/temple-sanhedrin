# temple-central.db Validation Command Compounding Drift Audit

Audit timestamp: 2026-04-30T11:25:41+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for long-window drift in builder `validation_cmd` strings, with emphasis on Law 4 identifier compounding and Law 5 validation evidence quality.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Table: `iterations`
- Builder rows: 2,919 total, with 1,414 inference rows and 1,505 modernization rows
- Window: `2026-04-12T13:51:32` through `2026-04-23T12:06:44`
- Query pack: `audits/trends/2026-04-30-validation-command-compounding-drift.sql`
- Identifier scan helper: `audits/trends/2026-04-30-validation-command-compounding-drift.py`
- LAWS.md focus: Law 4 identifier compounding ban and Law 5 no busywork / meaningful validation evidence.

No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

## Summary

The historical validation ledger shows that validation commands themselves became a carrier for Law 4 drift. Across builder rows, 2,136 rows include validation paths whose basename is longer than 40 characters or has more than 5 hyphen/underscore tokens. Inference has the most extreme single basename at 242 characters and 33 tokens; modernization has the longest command string at 1,353 characters, with long Book-of-Truth script names chained together.

Findings: 5 total.

## Findings

### WARNING-1: Validation command paths commonly violate the Law 4 name shape

Evidence:
- Inference: 1,243 / 1,414 rows have at least one over-compounded validation path.
- Modernization: 893 / 1,505 rows have at least one over-compounded validation path.
- The helper counted 3,560 bad inference identifiers and 2,616 bad modernization identifiers inside `validation_cmd` text.

Impact: even when source commits later repair file names, the central ledger preserves validation evidence in a naming shape that Law 4 now bans. Historical dashboards that replay or compare validation commands will continue to normalize the anti-pattern unless they classify these rows.

### WARNING-2: Inference validation names show severe chained-suffix growth

Evidence:
- Maximum inference validation basename: 242 characters and 33 tokens.
- Example row: `id=8421`, `IQ-740`, `test_attention_q16_apply_score_scale_rows_checked_nopartial_preflight_only_default_stride_required_stage_bytes_default_capacity_noalloc_hardened_commit_only_parity_noalloc_hardened_preflight_only_noalloc_commit_only_parity_noalloc_hardened.py`.
- Another repeated pattern reaches 233 characters and 34 tokens in `IQ-1128`.

Impact: these names encode implementation history as suffix chains instead of stable test concepts. That weakens Law 5 auditability because the command describes accumulated variants more than the behavior being validated.

### WARNING-3: Modernization validation commands became long chained harness bundles

Evidence:
- Modernization maximum `validation_cmd` length: 1,353 characters.
- Eleven modernization rows have command strings at least 1,000 characters long; 257 are at least 500 characters long.
- Longest example: `CQ-1207` chains `bookoftruth-serial-liveness-failstop-suite-batch-live-audit-trend-sweep-window-compare-digest-drift-tail-reset-proof-window-digest-replay...` scripts.

Impact: long harness chains make it hard to tell which Law 3, Law 8, Law 9, Law 10, or Law 11 property actually passed. They also hide whether QEMU/Book-of-Truth evidence was direct runtime evidence or only host-side fixture validation.

### WARNING-4: Exact validation commands repeat across hundreds of rows

Evidence:
- Inference has 109 exact repeated command strings covering 334 rows; one command repeats 35 times.
- Modernization has 87 exact repeated command strings covering 365 rows; one command repeats 47 times.

Impact: exact repetition is not automatically a violation, but it is a Law 5 drift signal. When many distinct task IDs reuse identical validation text, the DB cannot prove that coverage evolved with the changed surface.

### INFO-5: The drift is concentrated enough to backfill

Evidence:
- Daily rows with commands at least 500 characters long peak on 2026-04-22: 50 inference rows and 86 modernization rows.
- Modernization also has 30 rows with at least five `&&` command-chain links; inference has 5.
- The bad-name scan is reproducible from `validation_cmd` alone and does not require touching either builder repo.

Impact: the historical database can be backfilled with tags such as `validation_name_compounded`, `validation_cmd_long`, and `validation_cmd_reused` without re-running any builder validation.

## Key Aggregates

| Agent | Rows | Max command length | Avg command length | Commands >= 500 chars | Commands >= 1000 chars | Max `&&` links | Rows with >= 5 `&&` links |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 1,010 | 266.7 | 107 | 1 | 5 | 5 |
| modernization | 1,505 | 1,353 | 343.7 | 257 | 11 | 10 | 30 |

| Agent | Rows with bad validation names | Bad identifiers | Names > 40 chars | Names > 5 tokens | Max basename length | Max token count |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,243 | 3,560 | 3,274 | 3,553 | 242 | 34 |
| modernization | 893 | 2,616 | 2,616 | 2,427 | 169 | 25 |

| Agent | Exact repeated commands | Rows in repeated commands | Max repeats for one command |
| --- | ---: | ---: | ---: |
| inference | 109 | 334 | 35 |
| modernization | 87 | 365 | 47 |

## Recommendations

- Add a derived validation-command classifier to Sanhedrin ingestion: `cmd_len`, `cmd_chain_count`, `bad_validation_identifier_count`, and `validation_cmd_fingerprint`.
- Treat validation commands with bad identifiers as historical Law 4 debt, even if the active repo later renames the files.
- Replace chained suffix test naming with stable behavioral names plus structured metadata fields for mode, parity, preflight, commit-only, and hardening variants.
- For Law 5 scoring, require changed-surface coverage to be explicit when the same exact validation command is reused across unrelated task IDs.

## Read-Only Verification Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-validation-command-compounding-drift.sql
python3 audits/trends/2026-04-30-validation-command-compounding-drift.py
```
