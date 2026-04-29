# Cross-Repo Audit: GGUF Parser Manifest Contract Drift

Timestamp: 2026-04-29T06:54:27+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `abbc679bc7c429c0d89cdef04432b2e7a9d51fc7` (`feat(modernization): codex iteration 20260429-045038`)
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53` (`feat(inference): codex iteration 20260429-064100`)
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, liveness watcher, process restart, or WS8 networking task was executed. TempleOS had unrelated local worktree changes owned by the live loop; this audit used committed `HEAD` blobs for TempleOS evidence.

## Summary

Found 5 findings: 4 warnings and 1 info.

TempleOS owns the trust/control plane for `secure-local`: quarantine, promotion authority, key release, policy digest checks, and Book-of-Truth events. holyc-inference owns the worker/parser plane for GGUF model bytes. The current TempleOS trusted model manifest task names only `model_id`, `sha256`, quant type, tokenizer hash, and provenance, while the holyc-inference GGUF parser contract accepts or rejects files based on GGUF version, endian layout, metadata and tensor caps, type tables, alignment, tensor range overlap, and parser error classes.

This is not a present Law 1, Law 2, or Law 4 violation. It is warning-level drift: a future `secure-local` promotion could hash and approve a file while failing to bind the exact parser contract that made the file safe to load.

## Finding WARNING-001: trusted model manifest does not bind the GGUF parser contract version

Applicable laws:
- Law 5: North Star Discipline
- Law 3: Book of Truth Immutability

Evidence:
- TempleOS `secure-local` requires model quarantine plus hash verification, and promotion requires deterministic eval parity, parser negative-corpus/fuzz pass, reproducible build hash parity, and zero open critical Sanhedrin findings: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md` committed `HEAD` lines 33-38.
- TempleOS assigns control-plane authority to itself for quarantine, promotion, key release, and Book-of-Truth source of truth: `MODERNIZATION/MASTER_TASKS.md` committed `HEAD` lines 41-45.
- TempleOS WS14-03 currently scopes the trusted model manifest as `model_id`, `sha256`, quant type, tokenizer hash, and provenance: `MODERNIZATION/MASTER_TASKS.md` committed `HEAD` line 261.
- holyc-inference documents GGUF header layout, supported versions, count rejection, metadata caps, tensor sizing, alignment, and range/overlap rules as the parser contract: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md` lines 21-39, 93-127, and 129-152.

Assessment:

A whole-file `sha256` proves byte identity, but it does not prove which parser policy accepted those bytes. A manifest that omits `gguf_contract_version`, supported GGUF versions, parser caps, alignment policy, accepted tensor types, and error-class parity leaves the control plane unable to distinguish "hash-approved under the old parser" from "hash-approved under the current stricter parser."

Recommended closure:

Extend the trusted model manifest with a parser-policy digest over `gguf_contract_version`, accepted GGUF versions, endian policy, metadata/string/array/tensor caps, tensor type table, alignment policy, range-overlap policy, and negative-corpus fixture digest.

## Finding WARNING-002: TempleOS promotion gates do not name parser caps used by holyc-inference

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference metadata parser defines concrete caps: `GGUF_MAX_METADATA_COUNT`, `GGUF_MAX_STRING_BYTES`, and `GGUF_MAX_ARRAY_ELEMS`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/metadata.HC` lines 23-25.
- holyc-inference tensor-info parser has separate caps for tensor count, tensor name bytes, and dimensions: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensorinfo.HC` lines 15-17.
- holyc-inference format docs recommend parser caps and host validation for metadata, tensor info, sizing, alignment, and range cases: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md` lines 93-96 and 186-196.
- TempleOS WS14-04 requires a malformed GGUF/safetensors corpus and fuzz regression runner, but no committed control-plane task binds the cap values or cap digest into the trusted manifest: `MODERNIZATION/MASTER_TASKS.md` committed `HEAD` line 262.

Assessment:

The parser caps are security-relevant acceptance criteria. If holyc-inference tightens or relaxes them without TempleOS recording the cap set used at promotion time, `secure-local` evidence can pass while the parser acceptance surface drifts.

Recommended closure:

Record cap values and cap-source hash in every promotion: `max_metadata_count`, `max_string_bytes`, `max_array_elems`, `max_tensor_count`, `max_tensor_name_bytes`, `max_dims`, plus the negative-corpus digest that exercised those caps.

## Finding WARNING-003: quantization manifest field is too coarse for the parser type table

Applicable laws:
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- TempleOS WS14-03 names only "quant type" as a trusted manifest field: `MODERNIZATION/MASTER_TASKS.md` committed `HEAD` line 261.
- holyc-inference tensor-data sizing recognizes `F32`, `F16`, `Q4_0`, and `Q8_0` type IDs, with Q4_0 and Q8_0 block sizes of 32 and block byte widths of 18 and 34: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensor_data_base.HC` lines 19-41.
- The same helper rejects unknown types and non-multiple element counts before computing tensor bytes: `src/gguf/tensor_data_base.HC` lines 43-137.
- holyc-inference docs specify F32/F16 sizing even while runtime tensor math must stay integer-only: `docs/GGUF_FORMAT.md` lines 116-127.

Assessment:

One manifest-level `quant type` cannot express a mixed tensor table. A GGUF can contain F32/F16 metadata or tensors that are parser-visible even if runtime tensor operations remain integer-only. The control plane needs to know which per-tensor storage types were accepted and whether any non-Q4_0/Q8_0 tensors are loader metadata, blocked tensors, or tolerated constants.

Recommended closure:

Promote models only with a tensor-type inventory digest: counts by `ggml_type`, per-tensor `(name_hash, dims_hash, type, byte_span_hash)`, and an explicit policy for F32/F16 presence.

## Finding WARNING-004: alignment and absolute range policy are worker-local, not promotion evidence

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- holyc-inference default GGUF tensor alignment is 32 bytes: `src/gguf/tensor_data_base.HC` lines 15-18.
- holyc-inference validates power-of-two alignment, aligned tensor base, aligned relative tensor offsets, overflow-safe absolute ranges, file bounds, and non-overlap: `src/gguf/tensor_data_base.HC` lines 139-227 and `docs/GGUF_FORMAT.md` lines 129-152.
- TempleOS WS14-07 plans Book-of-Truth events for profile changes, model promotions, and gate failures, but the committed WS14 list does not name tensor layout/range evidence as an event payload: `MODERNIZATION/MASTER_TASKS.md` committed `HEAD` lines 265-278.

Assessment:

The parser's range policy is one of the strongest defenses against hostile local model files. If promotion events only say "model hash promoted", later audits cannot verify whether the parser rejected overlap, misalignment, out-of-bounds ranges, or overflow edges at the time of promotion.

Recommended closure:

Book-of-Truth promotion events should include `tensor_count`, `tensor_range_digest`, `alignment`, `overlap_policy`, `max_abs_end`, and `range_validation_status`, in addition to the model file hash.

## Finding INFO-001: current GGUF parser posture is air-gapped and HolyC/integer-oriented

Applicable laws:
- Law 1: HolyC Purity
- Law 2: Air-Gap Sanctity
- Law 4: Integer Purity

Evidence:
- holyc-inference GGUF docs state deterministic integer-only parsing, no external dependencies, no networking, disk-only runtime, no sockets/HTTP/downloaders, and QEMU runs with NIC disabled: `docs/GGUF_FORMAT.md` lines 6-10 and 198-202.
- holyc-inference header code decodes fixed little-endian fields and preserves version/magic/count checks in HolyC: `src/gguf/header.HC` lines 4-12, 52-55, 163-190, and 218-255.
- holyc-inference metadata code preserves float metadata payloads as raw integer bits because the runtime stays integer-only: `src/gguf/metadata.HC` lines 56-73.
- No QEMU or VM command was run during this audit; no networking stack, NIC, socket, TCP/IP, UDP, DNS, DHCP, HTTP, or TLS surface was added or enabled.

Assessment:

The drift is not that the worker parser is unsafe today. The drift is that TempleOS has not yet made the parser acceptance surface part of `secure-local` control-plane evidence.

## Recommended Backlog Items

- Add `gguf_parser_contract_digest` to the trusted model manifest.
- Require promotion evidence to record parser caps, accepted GGUF versions, endian policy, alignment policy, tensor-type inventory, and tensor-range digest.
- Add a shared negative-corpus digest that both TempleOS policy and holyc-inference parser validation reference.
- Keep the GGUF path disk-only and local-only; do not use network-dependent model downloaders or WS8 networking tasks.

## Law Compliance Notes

- Law 1 HolyC Purity: no violation found in audited parser/control-plane surfaces.
- Law 2 Air-Gap Sanctity: no networking action performed; no QEMU/VM command executed.
- Law 3 Book-of-Truth: warning-level drift because promotion events do not yet bind parser/range evidence.
- Law 4 Integer Purity: no runtime tensor float violation found; warning-level manifest gap around F32/F16 storage-type policy.
- Law 5 North Star Discipline: warning-level drift because secure-local promotion cannot be fully audited without the parser contract digest.

Finding count: 5

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show HEAD:MODERNIZATION/MASTER_TASKS.md | nl -ba | sed -n '31,45p;258,266p;274,280p'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show HEAD:MODERNIZATION/LOOP_PROMPT.md | nl -ba | sed -n '38,58p;62,65p'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference show HEAD:docs/GGUF_FORMAT.md | nl -ba | sed -n '21,39p;93,127p;129,152p;186,202p'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference show HEAD:src/gguf/header.HC | nl -ba | sed -n '4,12p;52,55p;163,190p;218,255p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/metadata.HC | sed -n '23,25p;56,73p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensorinfo.HC | sed -n '15,17p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensor_data_base.HC | sed -n '15,41p;43,137p;139,227p'
```
