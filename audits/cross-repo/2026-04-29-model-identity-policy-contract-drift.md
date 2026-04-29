# Cross-Repo Model Identity And Policy Contract Drift Audit

Timestamp: 2026-04-29T18:03:44+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d9c3b620dbe9cf8bde884ed11c8ec1df99a68e89`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, WS8 networking, package download, or live liveness command was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

The repos agree on secure-local/dev-local numeric profile IDs and both keep model loading air-gapped, but the shared contract is still under-specified in three places: model identity, target architecture, and worker policy evidence. These are not immediate Law 1 or Law 2 violations. They are cross-repo drift risks because TempleOS is the sovereign control plane while holyc-inference is building worker-side proof structures that do not yet map one-to-one to TempleOS ledger gates.

## Finding WARNING-001: North Star target model family is split between GPT-2 and LLaMA-family contracts

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/NORTH_STAR.md:7` defines the deliverable as a small GPT-2 forward pass.
- `holyc-inference/NORTH_STAR.md:16-18` narrows that to a Q4_0 GPT-2 124M weight blob and `tests/reference_q4_gpt2.py`.
- `holyc-inference/MASTER_TASKS.md:18-21` instead says the single first architecture is LLaMA-family, with TinyLlama/Qwen as the small-model targets.
- `holyc-inference/docs/LLAMA_ARCH.md:1-18` documents LLaMA-family as the first forward-pass target.
- TempleOS `BookTruthModelParseMask` currently accepts model format and GGUF magic only; it does not record or gate architecture family (`TempleOS/Kernel/BookOfTruth.HC:12498-12513`).

Assessment:
The worker repo has two competing first-model contracts. This matters cross-repo because TempleOS can currently trust a model record by `{model_id, sha_hi, sha_lo, quant, tok_hash, provenance}` and parse format, but not by architecture family. A future "trusted model" could satisfy TempleOS' generic GGUF gate while failing the actual inference North Star the worker claims to be pursuing.

Required remediation:
- Declare one first North Star model family as authoritative, then update the other docs/tasks to match.
- Add an architecture field or architecture digest to the shared model promotion evidence before trusted dispatch.
- Treat LLaMA-vs-GPT-2 mismatch as a release-blocking documentation drift until the executable E2E target and TempleOS model gate agree.

## Finding WARNING-002: TempleOS model identity schema is richer than the holyc-inference trust manifest

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- TempleOS model entries store `model_id`, `state`, `quant`, `provenance`, parse status, `sha_hi`, `sha_lo`, and `tok_hash` (`TempleOS/Kernel/BookOfTruth.HC:147-164`).
- `BookTruthModelSchemaMask` requires a valid model ID, nonzero hash halves, quant in range, nonzero tokenizer hash, and provenance in range (`TempleOS/Kernel/BookOfTruth.HC:12472-12488`).
- `BookTruthModelImport` and `BookTruthModelVerify` expose that schema through the kernel ABI (`TempleOS/Kernel/KExts.HC:105-112`).
- holyc-inference `TrustManifestEntry` stores only `sha256_hex`, `size_bytes`, and `rel_path` (`holyc-inference/src/model/trust_manifest.HC:31-35`).
- holyc-inference `ModelQuarantineState` stores path, byte size, manifest entry index, 64-char hash, and profile ID, but not `model_id`, `quant`, `tok_hash`, or provenance (`holyc-inference/src/model/quarantine.HC:31-40`).

Assessment:
The control-plane and worker-plane model identities do not have a lossless mapping. TempleOS can require `tok_hash` and `quant`, while the worker trust manifest can verify only path/size/SHA256. Without a canonical projection from the 256-bit SHA256 plus tokenizer/model metadata into TempleOS' `sha_hi/sha_lo/tok_hash/quant/provenance` fields, audits cannot prove that a worker-verified model is the same model TempleOS promoted.

Required remediation:
- Define a shared manifest schema containing `model_id`, full SHA256, `sha_hi`, `sha_lo`, `quant`, tokenizer hash, provenance, byte size, path, and architecture.
- Add a deterministic derivation rule for any compressed ledger fields so auditors can recompute them from the full manifest.
- Make worker quarantine promotion emit the exact fields TempleOS expects before any trusted-load/key-release report can pass.

## Finding WARNING-003: Worker policy digest exists, but TempleOS only records that the digest must be checked

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `InferencePolicyDigestChecked` hashes profile ID, secure-default flag, IOMMU flag, Book-of-Truth DMA/MMIO/dispatch flags, quarantine gate, hash-manifest gate, and policy bits (`holyc-inference/src/runtime/policy_digest.HC:86-170`).
- TempleOS modernization docs say trusted-load/key-release requires a policy digest match (`TempleOS/MODERNIZATION/MASTER_TASKS.md:45`) and list WS14-19 as the still-open policy-digest validation task (`TempleOS/MODERNIZATION/MASTER_TASKS.md:277`).
- Source search found TempleOS references to policy-digest requirements in modernization docs, but no current kernel implementation of `InferencePolicyDigest` validation in `TempleOS/Kernel`.
- TempleOS currently exposes profile status and model gates, not a worker policy digest verifier (`TempleOS/Kernel/KExts.HC:101-117`).

Assessment:
The worker has a concrete digest algorithm; TempleOS still has a requirement and open task. Until TempleOS validates the same digest tuple and records the decision in the Book of Truth, policy digest is worker-side evidence, not a control-plane gate. That is acceptable only if all trusted dispatch remains blocked or diagnostic.

Required remediation:
- Implement the TempleOS-side verifier for the worker digest tuple, or add a clear blocked status in release reports.
- Record the digest, expected digest, match result, and gate decision through Book of Truth before trusted dispatch.
- Keep key-release and trusted-load decisions out of holyc-inference until TempleOS owns this comparison.

## Finding WARNING-004: GPU Book-of-Truth event vocabulary does not map cleanly onto TempleOS ledger events

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `book_of_truth_bridge.HC` defines worker-side GPU event classes for DMA, MMIO, and dispatch, with operations for map/update/unmap, MMIO write, submit/complete/timeout (`holyc-inference/src/gpu/book_of_truth_bridge.HC:9-34`).
- The worker bridge stores events in a local ring supplied by the caller (`holyc-inference/src/gpu/book_of_truth_bridge.HC:36-54`).
- TempleOS currently exposes `BookTruthDMARecord` and DMA status, with DMA ops read/write/bidir (`TempleOS/Kernel/BookOfTruth.HC:63-65`, `TempleOS/Kernel/KExts.HC:121`).
- Source search found no TempleOS kernel `BOT_GPU_EVENT_*` vocabulary for MMIO write or dispatch submit/complete/timeout at current head.

Assessment:
The worker has a richer GPU telemetry vocabulary than TempleOS can currently ledger as first-class events. If those worker events are treated as Book-of-Truth records, Law 8 is at risk because the records are not necessarily synchronous TempleOS UART/ledger events. If they remain advisory pre-ledger tuples, the name "Book-of-Truth bridge" should not imply control-plane recording.

Required remediation:
- Define the canonical TempleOS ledger ABI for GPU DMA, MMIO, and dispatch events before worker-side GPU acceleration is considered trusted.
- Rename or document the worker bridge as staging evidence unless and until it calls TempleOS ledger primitives.
- Require every GPU dispatch readiness report to show TempleOS event IDs for DMA, MMIO, and dispatch decisions, not only worker ring sequence IDs.

## Finding INFO-001: Profile numeric constants are synchronized across the two repos

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS defines `BOT_PROFILE_SECURE_LOCAL 1` and `BOT_PROFILE_DEV_LOCAL 2` (`TempleOS/Kernel/BookOfTruth.HC:99-100`).
- TempleOS profile names map `2` to `dev-local` and default to `secure-local` (`TempleOS/Kernel/BookOfTruth.HC:12375-12383`).
- holyc-inference defines `INFERENCE_PROFILE_SECURE_LOCAL 1` and `INFERENCE_PROFILE_DEV_LOCAL 2` (`holyc-inference/src/runtime/profile.HC:10-11`).
- holyc-inference profile names map `1` to `secure-local` and `2` to `dev-local`, with secure-local as the global default (`holyc-inference/src/runtime/profile.HC:19-33`).

Assessment:
This invariant is healthy. Profile IDs and names can be safely used as shared evidence fields, provided the policy digest and model identity gaps above are closed.

## Non-Findings

- No guest networking, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or WS8 networking task was executed or introduced.
- No QEMU/VM command was run, so no VM networking state changed.
- No TempleOS or holyc-inference source code was edited.
- No Law 1 foreign-language runtime implementation was found in the audited core surfaces; this audit focused on cross-repo contract drift, not a full language-boundary sweep.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "GPT-2|LLaMA|TinyLlama|Qwen|architecture|Architecture" \
  /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md \
  /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md \
  /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/LLAMA_ARCH.md
rg -n "BookTruthModel|BOT_PROFILE|BookTruthProfile|BookTruthDMARecord|BOT_DMA|BOT_GPU|InferencePolicyDigest|policy-digest" \
  /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel \
  /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION
rg -n "TrustManifestEntry|ModelQuarantineState|InferencePolicyDigest|INFERENCE_PROFILE|BOT_GPU_EVENT|BOTGPUBridge" \
  /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src
```
