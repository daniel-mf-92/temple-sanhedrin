# Cross-Repo Audit: GGUF Model-Info Layout Proof Drift

Timestamp: 2026-04-30T03:09:15+02:00

Audit angle: cross-repo invariant check for whether TempleOS model parse/trust evidence can prove the GGUF tensor layout summarized by the newest holyc-inference model-info helper.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `f247f4ea41c581d7585a4daab75f4d5137f11986`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `3d55474220c74c45a78014872eb1459e424b0e16`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, networking, or package-download command was executed.

## Expected Cross-Repo Invariant

If holyc-inference accepts a GGUF model-info summary, TempleOS must be able to bind the same tensor-layout facts into the local trust/control plane before model promotion:

`{model_id, full_model_digest, gguf_magic, header_hash, tensor_data_base, file_nbytes, tensor_count, total_payload_bytes, last_tensor_end, layout_digest, parser_status, Book-of-Truth append proof}`

The worker-side tensor rows are useful only if TempleOS can prove the exact same byte-layout summary was parsed and recorded in the Book of Truth. Otherwise a model can be trusted against a coarse header tuple while the runtime consumes a richer, unaudited tensor payload shape.

Finding count: 4 findings: 4 warnings.

## Findings

### WARNING-001: TempleOS parse evidence omits the tensor-layout summary holyc-inference now computes

Applicable laws:
- Law 5: North Star Discipline
- Law 3: Book of Truth Immutability

Evidence:
- holyc-inference commit `2799283c` adds `GGUFModelInfoBuildCheckedNoPartial(...)`, which preflights tensor rows from `tensor_data_base`, `file_nbytes`, `tensor_count`, `tensor_offsets`, and `tensor_sizes`, then commits `rel_offset`, `byte_count`, `abs_start`, `abs_end`, `out_total_payload`, and `out_last_end` only after validation (`src/gguf/model_info.HC:36-122`).
- TempleOS `BookTruthModelParseRun(...)` records only `fmt`, `magic`, `hdr_hash`, `bytes`, `fuzz`, `parse_mask`, and `parse_tsc` (`Kernel/BookOfTruth.HC:12713-12752`).
- The immutable TempleOS parse payload stores marker, model id, format, mask, and ok bit only (`Kernel/BookOfTruth.HC:12737-12741`).

Assessment:
The new inference-side model-info helper makes tensor payload layout a first-class checked object, but TempleOS still cannot prove which tensor offsets or sizes were checked. A later `BookTruthModelStatus` row can say parsing passed while omitting `tensor_count`, `tensor_data_base`, total payload bytes, or a layout digest. That is a trust-evidence gap, not a HolyC or air-gap violation.

Required remediation:
- Add a shared GGUF layout digest or compact proof tuple to TempleOS parse records.
- Bind `tensor_count`, `tensor_data_base`, `file_nbytes`, `total_payload_bytes`, and `last_tensor_end` to the Book-of-Truth parse event or an adjacent sealed event.

### WARNING-002: TempleOS promotion does not require a successful GGUF layout proof

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS promotion gates on schema, verification, failed parser status if `parse_fmt != 0`, and secure-local deterministic gate (`Kernel/BookOfTruth.HC:12866-12881`).
- The parser gate treats `parse_fmt==0` as not failed rather than as missing evidence (`Kernel/BookOfTruth.HC:12871-12880`).
- holyc-inference marks `WS2-05` done for a GGUF validation tool and the new helper is specifically a "model-info validation" path (`MASTER_TASKS.md:69`, `src/gguf/model_info.HC:1-3`).

Assessment:
Even after the worker repo gained a concrete GGUF model-info checker, TempleOS can still promote a verified model without any recorded layout proof if no parse run happened. This repeats the older parser-gate ambiguity at a more specific tensor-layout layer: the control plane can trust model bytes without proving the runtime's tensor rows were checked.

Required remediation:
- For GGUF models in `secure-local`, treat missing parse/layout evidence as a gate failure.
- Split parser status into explicit header, metadata, tensor-info, tensor-layout, and deterministic-reference gates so "not run" cannot be mistaken for success.

### WARNING-003: Worker model-info rows are not joined to TempleOS model identity

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `GGUFInfoRow` contains only relative offset, byte count, absolute start, and absolute end (`src/gguf/model_info.HC:11-17`).
- `GGUFModelInfoBuildCheckedNoPartial(...)` accepts raw arrays and output buffers but no `model_id`, SHA256/full digest, tokenizer hash, provenance, or TempleOS append proof (`src/gguf/model_info.HC:36-45`).
- TempleOS model identity uses `model_id`, `sha_hi`, `sha_lo`, `quant`, `tok_hash`, and provenance (`Kernel/BookOfTruth.HC:153-175`, `12656-12710`).

Assessment:
holyc-inference can validate a tensor layout in isolation, while TempleOS can track a model identity in isolation. There is no shared join key proving that the layout rows came from the exact model record that TempleOS imported, verified, and promoted.

Required remediation:
- Extend worker model-info output with a model-proof header: `model_id`, full digest or TempleOS digest projection, tokenizer hash, quant type, parser status, and Book-of-Truth append proof.
- Sanhedrin should reject layout evidence that cannot join to a TempleOS model record by immutable digest and append sequence.

### WARNING-004: Layout failure reasons are richer than TempleOS parse-mask capacity

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference has separate model-info errors for null pointer, bad parameter, overflow, out-of-bounds, and overlap (`src/gguf/model_info.HC:4-9`).
- TempleOS parser mask covers format, byte bounds, fuzz range, magic mismatch, and zero header hash (`Kernel/BookOfTruth.HC:12636-12653`).
- TempleOS parse event stores only the low 8 bits of `mask` in the payload (`Kernel/BookOfTruth.HC:12737-12741`).

Assessment:
The worker can distinguish tensor overlap from EOF bounds from arithmetic overflow, but the TempleOS parser mask has no corresponding reason domain. Historical ledger review would be unable to tell whether a parser rejection came from header mismatch, missing header hash, tensor overlap, or payload overrun unless host-side artifacts survive separately.

Required remediation:
- Reserve shared parse/layout failure bits for tensor overlap, out-of-bounds tensor payload, tensor span overflow, alignment mismatch, and row-count/capacity mismatch.
- Add a decoded `BookTruthModelLayoutStatus` or equivalent local-only status surface that reports those reasons from immutable ledger-backed state.

## Non-Findings

- No Law 1 core-language violation was found in this slice: the new inference runtime helper is HolyC, and its Python harness is under `tests/`, which LAWS.md allows.
- No Law 2 air-gap issue was found. The reviewed change does not add networking, WS8 work, package download behavior, QEMU launch behavior, or VM execution.
- The worker helper uses integer offset/count math and does not introduce runtime floating-point tensor operations.

## Suggested Sanhedrin Follow-Up

Track a shared `GGUFLayoutProof` contract. Minimum fields: `model_id`, `sha256_hex64` or canonical digest projection, `gguf_magic`, `header_hash`, `tensor_data_base`, `file_nbytes`, `tensor_count`, `total_payload_bytes`, `last_tensor_end`, `layout_digest`, `layout_error_code`, `bot_seq`, `bot_event_type`, `bot_payload_marker`, and `bot_entry_hash`.

## Evidence Commands

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference show --stat --oneline --name-only 2799283c9554bea44c132137c590f02034c8f726`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/model_info.HC | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_gguf_model_info_build.py | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,75p;1138,1165p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '120,190p;12620,12755p;12845,12915p;12925,13080p'`
