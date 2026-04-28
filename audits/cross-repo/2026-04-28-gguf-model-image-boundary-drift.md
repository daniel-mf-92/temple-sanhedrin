# Cross-Repo Audit: GGUF Model Image Boundary Drift

Timestamp: 2026-04-28T12:48:45+02:00

Scope: cross-repo invariant check across read-only TempleOS and holyc-inference worktrees.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: whether TempleOS' local model/trust-plane commitments are precise enough to satisfy holyc-inference's GGUF/tensor payload assumptions when the model lives on an air-gapped `shared.img` or separate writable data partition.

## Summary

The repos agree on the policy intent: no guest networking, local model loading, trusted promotion, deterministic parity, and Book-of-Truth evidence. The drift is at the byte boundary between the TempleOS storage/trust plane and the holyc-inference parser/runtime plane. holyc-inference has detailed GGUF byte, type, offset, and alignment rules; TempleOS currently names the storage surface and trusted manifest fields, but does not define a model-image grammar, file path convention, filesystem role, sector/range evidence, or loader alignment contract. This can let future "model loaded from shared.img" evidence pass without proving the exact bytes, offsets, and tensor payload shape consumed by the inference runtime.

Finding count: 5 warnings, 0 critical violations.

## Findings

### WARNING-001: TempleOS does not define a byte-exact model image contract for the GGUF loader

Relevant laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline / No Busywork
- Law 8: Book of Truth Immediacy and Hardware Proximity
- Law 10: Immutable OS Image

Evidence:
- TempleOS north-star QEMU command documents `shared.img` as an IDE drive and requires a HolyC program on it, but only for the Book-of-Truth hello demo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md:17`.
- TempleOS says user data, Book-of-Truth logs, and LLM models live on a separate writable partition distinct from the OS image: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:213`.
- TempleOS trusted model workstream requires quarantine, hash verify, manifest entry, and trusted promotion, but does not define the disk image path, filesystem, model path, sector ranges, or byte-range grammar: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:260`.
- holyc-inference's GGUF contract is byte-specific: little-endian header, metadata, tensor info, aligned tensor payload base, and checked absolute tensor ranges: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md:23`, `:42`, `:131`, `:145`.

Impact:

Sanhedrin can eventually see "a model exists on shared.img" or "manifest hash passed" without enough evidence to prove that the guest consumed the same byte stream under holyc-inference's GGUF rules. The missing contract is not a runtime breach today, but it weakens future trusted-load evidence.

Recommended closure:

Define a shared model-image contract: image role, filesystem, canonical model path, file format magic, SHA-256 domain, expected byte length, sector range list, tensor payload base, and whether the model image is writable only during quarantine/import and readonly during trusted runs.

### WARNING-002: GGUF alignment requirements are not mapped to TempleOS file-read or heap-buffer guarantees

Relevant laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy and Hardware Proximity

Evidence:
- holyc-inference docs set GGUF default alignment to 32 and require aligned tensor payload base plus aligned tensor relative offsets: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md:131`, `:134`, `:138`, `:140`.
- holyc-inference `tensor_data_base.HC` implements the same default and returns explicit misalignment errors for base or tensor relative offset: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensor_data_base.HC:15`, `:17`, `:213`, `:215`, `:217`.
- TempleOS exposes aligned allocation primitives (`MAllocAligned`, `CAllocAligned`) but the model-loading workstream does not yet say whether GGUF files must be loaded into aligned buffers, streamed by sector, or copied whole into memory before parsing: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Mem/MAllocFree.HC:423`, `:434`.

Impact:

If future TempleOS integration streams model data through arbitrary file buffers, a parser can compute valid file-relative GGUF offsets while the runtime receives unaligned memory views or partial range copies. That creates a hard-to-audit distinction between "file offset aligned" and "actual pointer/address aligned."

Recommended closure:

Add a loader ABI field or spec paragraph covering `file_offset_alignment`, `buffer_base_alignment`, `read_chunk_alignment`, and whether tensor pointers are file-relative offsets, heap pointers, or sector-backed windows. Log those choices in the Book of Truth for trusted runs.

### WARNING-003: holyc-inference has two GGUF type surfaces with different acceptance width

Relevant laws:
- Law 4: Integer Purity for inference runtime
- Law 5: North Star Discipline

Evidence:
- The GGUF docs list current supported runtime sizing for `F32`, `F16`, `Q4_0`, and `Q8_0`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md:116`.
- `tensor_data_base.HC` keeps the runtime-critical type table strict to `F32`, `F16`, `Q4_0`, and `Q8_0`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensor_data_base.HC:19`, `:22`, `:24`, `:25`.
- `validator.HC` accepts a wider tensor-layout set including `Q4_1`, `Q5_0`, `Q5_1`, `Q8_1`, integer scalar types, `F64`, and `BF16`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/validator.HC:17`, `:20`, `:21`, `:24`, `:25`, `:29`, `:30`, `:91`, `:92`, `:100`, `:104`.

Impact:

A negative-corpus or promotion gate that calls the broad validator can certify a tensor table that the stricter runtime sizing path does not actually support. This is fail-closed only if every trusted load later goes through the strict path; the repos do not yet name which parser/validator is authoritative for TempleOS WS14 trusted promotion.

Recommended closure:

Declare one authoritative `secure-local` GGUF acceptance set. Either narrow `validator.HC` for trusted runs or add an explicit mode/profile parameter that marks broad validation as parser-hardening coverage only, not runtime-load eligibility.

### WARNING-004: Weight artifact format identity is not bound across the two north-star specs

Relevant laws:
- Law 5: North Star Discipline
- Law 6: Queue Health / real workstream traceability

Evidence:
- holyc-inference north star says a `Q4_0` GPT-2 124M weight blob lives on `shared.img`, but it does not say whether that blob is GGUF, a raw custom format, or another container: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:16`.
- holyc-inference north-star script looks for `models/gpt2-124m-q4_0.bin`, not a GGUF file or an image-contained path: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh:5`, `:6`.
- holyc-inference separately documents GGUF as the HolyC parser contract for TempleOS parsing: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md:1`, `:3`.
- TempleOS WS14 parser-hardening gate names `GGUF/safetensors`, while the north-star storage wording only says `shared.img` and the TempleOS north-star script currently does not attach that data image: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:262`; `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:21`.

Impact:

Different agents can make progress on incompatible artifacts: a raw `.bin` Q4_0 blob, a GGUF file, or a staged file inside a disk image. This is a Law 5 drift risk because work can appear north-star-aligned while not closing the same executable contract.

Recommended closure:

Choose and record the canonical north-star artifact grammar. If it is GGUF, require a `.gguf` magic check and manifest field. If it is raw Q4_0, mark GGUF parsing as a later parser-hardening track and define the raw header/tensor layout separately.

### WARNING-005: Book-of-Truth disk I/O evidence is not tied to model byte ranges

Relevant laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy and Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- TempleOS has an explicit future item to log all disk I/O at sector level: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:241`.
- TempleOS has future Book-of-Truth events for profile changes, model promotions, and gate failures, but not a named model-load byte-range or tensor-range event: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:265`.
- holyc-inference parser resolves tensor ranges as half-open `[abs_start, abs_end)` inside a file and validates `abs_end <= file_size`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md:144`, `:151`.
- holyc-inference `GGUFModelValidateTensorLayoutCheckedNoPartial` validates tensor offsets against a data-region byte length, but it has no Book-of-Truth sector/range evidence input or output: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/validator.HC:163`, `:169`, `:215`, `:220`.

Impact:

Even if model promotion is hash-verified, a future trusted run needs proof that the loaded file ranges and tensor payload ranges were the promoted bytes, read locally, with no unlogged substitution on the writable data partition. Current workstreams do not bind the GGUF byte ranges to Book-of-Truth disk I/O evidence.

Recommended closure:

Define a `BOT_MODEL_LOAD_RANGE` or equivalent event schema: model id, manifest hash, image id, file path, sector start/count, byte start/end, tensor count, tensor data base, and parser status. Keep the event local-only; do not add remote export or networking.

## Law Compliance Notes

- No trinity source code was modified.
- No VM or QEMU command was executed.
- Air-gap posture was preserved; no networking work was performed.
- Findings are warning-level cross-repo contract drift, not current critical Law 1 or Law 2 violations.

## Evidence Commands

```bash
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '24,70p;208,266p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md | sed -n '1,230p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/tensor_data_base.HC | sed -n '1,260p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/validator.HC | sed -n '1,260p'
```
