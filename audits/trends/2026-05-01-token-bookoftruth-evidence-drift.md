# Historical Trend Audit: Token / Book-of-Truth Evidence Drift

Timestamp: 2026-05-01T13:18:37+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only.

Scope:
- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- SQL pack: `audits/trends/2026-05-01-token-bookoftruth-evidence-drift.sql`
- TempleOS source spot-check: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference source spot-check: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, NIC, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, or remote fetch command was executed.

## Summary

holyc-inference's stated north star requires "every token logged to the Book of Truth." The historical central ledger shows substantial inference token work, but none of the 331 inference rows with token evidence also record Book-of-Truth evidence. The only three inference rows that mention Book of Truth are GPU policy/bridge/fault-injection rows, not per-token generation or tokenizer rows.

Finding count: 5 warnings, 0 critical source violations.

## Findings

### WARNING-001: Inference token work has zero recorded Book-of-Truth join evidence

Evidence:
- `iterations` contains 1,414 inference rows from 2026-04-12 through 2026-04-23.
- 331 inference rows mention token work in `task_id`, `files_changed`, `validation_cmd`, `validation_result`, or `notes`.
- 0 of those 331 rows also mention Book of Truth, `bot_`, or `BOTGPU` evidence.

Impact: historical Law 5 and North Star audits cannot tell whether token-path work was moving toward the mandatory per-token ledger contract or only improving local tokenizer/sampler mechanics.

### WARNING-002: The only inference Book-of-Truth rows are GPU-side, not token-side

Evidence:
- The three inference Book-of-Truth rows are `IQ-1254`, `IQ-1255`, and `IQ-1257`.
- Their notes cover IOMMU/profile dispatch policy, GPU event bridge, and GPU fault-injection.
- None of those rows are token rows under the token keyword scan.

Impact: the database preserves worker-plane GPU Book-of-Truth work, but not the higher-level per-token audit path required for an inference call.

### WARNING-003: Generation/sampling evidence is not paired with ledger evidence

Evidence:
- The query found 63 inference generation/sampling/logit/forward rows.
- 0 of those generation rows also contain Book-of-Truth evidence.
- Daily generation rows appear on 2026-04-12, 2026-04-17, 2026-04-18, 2026-04-19, 2026-04-20, 2026-04-22, and 2026-04-23, but never with a Book-of-Truth join marker.

Impact: first-token, logits, sampling, and generated-token progress cannot be scored as "ledger-visible" from the historical DB.

### WARNING-004: TempleOS central source has no visible per-token Book-of-Truth API surface

Evidence:
- A TempleOS source spot-check found model trust and GPU DMA task references, but no `BookTruth...Token`, `BOT...TOKEN`, or token-specific Book-of-Truth kernel API in the inspected `Kernel/` and `MODERNIZATION/MASTER_TASKS.md` surfaces.
- The only TempleOS token hits in the inspected core paths are compiler/task parser token fields, not inference token ledger events.

Impact: holyc-inference can continue implementing token generation helpers, but there is no obvious TempleOS control-plane ABI for recording `model_id`, `request_id`, `token_index`, `token_id`, logits/sample metadata, and ledger sequence/hash.

### WARNING-005: Current holyc-inference docs demand token logging, but the central ledger never records that bridge

Evidence:
- `holyc-inference/MASTER_TASKS.md:10` states the goal is locally-loaded model output with every token logged to the Book of Truth.
- `holyc-inference/MASTER_TASKS.md:23-24` requires every inference call, every token, and tensor checkpoints to be loggable by the Book of Truth ledger.
- `holyc-inference/MASTER_TASKS.md:115` leaves WS8-03 open for Book-of-Truth hooks that log model load, each token, and anomalies.
- The central ledger has 331 token rows and 0 token-plus-Book-of-Truth rows.

Impact: this is not a direct Law 1, Law 2, Law 4, or air-gap violation. It is a historical evidence gap and cross-repo contract gap: the token path and Book-of-Truth path are progressing in separate traces.

## Evidence Tables

Overall token/Book-of-Truth coverage:

| agent | rows | token_rows | bot_rows | token_bot_rows | token_logish_rows | generation_rows | generation_bot_rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 331 | 3 | 0 | 16 | 63 | 0 |
| modernization | 1,505 | 0 | 1,466 | 0 | 0 | 25 | 25 |

Inference daily token coverage:

| day | rows | token_rows | token_bot_rows | generation_rows |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-12 | 64 | 0 | 0 | 2 |
| 2026-04-13 | 68 | 0 | 0 | 0 |
| 2026-04-15 | 35 | 0 | 0 | 0 |
| 2026-04-16 | 68 | 5 | 0 | 0 |
| 2026-04-17 | 157 | 5 | 0 | 1 |
| 2026-04-18 | 152 | 96 | 0 | 11 |
| 2026-04-19 | 164 | 67 | 0 | 1 |
| 2026-04-20 | 202 | 60 | 0 | 3 |
| 2026-04-21 | 219 | 45 | 0 | 0 |
| 2026-04-22 | 224 | 44 | 0 | 41 |
| 2026-04-23 | 61 | 9 | 0 | 4 |

Inference Book-of-Truth rows:

| ts | task_id | evidence class |
| --- | --- | --- |
| 2026-04-23T09:58:40 | IQ-1254 | GPU policy dispatch gate |
| 2026-04-23T10:08:18 | IQ-1255 | GPU Book-of-Truth event bridge |
| 2026-04-23T10:33:26 | IQ-1257 | GPU fault-injection / secure-local hardening |

## Recommendations

- Define a TempleOS-authoritative token ledger ABI such as `{model_id, request_id, token_index, token_id, sampler_policy_digest, logits_digest, rng_state_digest, seq, hash}`.
- Require holyc-inference token generation rows to include a Book-of-Truth proof tuple or a clear `ledger_pending` status until the TempleOS ABI exists.
- Add normalized DB fields for `token_path_touched`, `book_truth_token_event_seen`, `bot_seq`, `bot_hash`, and `ledger_contract_status`; keyword inference from prose is too weak for Law 5 scoring.
- Keep GPU Book-of-Truth bridge evidence separate from token ledger evidence so GPU readiness cannot be overread as per-token audit coverage.

## Read-Only Commands

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-token-bookoftruth-evidence-drift.sql
rg -n "Book.?Truth|BOT|token|Token" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md
rg -n "BookTruth.*Token|Token.*BookTruth|BOT.*TOKEN|TOKEN.*BOT|token" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md
```

