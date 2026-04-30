# Cross-Repo Audit: Text Integrity / Model-Info Proof Boundary Drift

Timestamp: 2026-04-30T23:51:25+02:00

Audit angle: cross-repo invariant check for whether the newest TempleOS kernel text-integrity baseline can be joined to holyc-inference model-info validation evidence as one secure-local proof chain.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `5c26856437cfa7d522928f8204da8a7feeb2eb31`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `19aef079cd72743c4a47315de4602b1746ab06e7`

This audit was read-only against TempleOS and holyc-inference. It did not run QEMU, did not start a VM, did not execute WS8 networking work, did not inspect live liveness, and did not modify trinity source code.

## Expected Cross-Repo Invariant

Secure-local evidence should let Sanhedrin join these facts without host-side guesswork:

`{templeos_commit, kernel_text_hash_full, text_integrity_phase, bot_seq, bot_event_type, bot_payload, bot_entry_hash, model_id, model_digest_full, gguf_layout_digest, tensor_count, total_payload_bytes, policy_digest, inference_event_digest}`

TempleOS is the trust/control plane. holyc-inference can validate model layout locally, but promotion-grade proof needs a TempleOS Book-of-Truth event that binds the exact kernel text baseline and the exact model layout/runtime evidence being consumed.

Finding count: 5 findings: 1 critical, 4 warnings.

## Findings

### CRITICAL-001: Text-integrity baseline exposes a caller-controlled no-event path

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `Kernel/BookOfTruth.HC:55800-55801` defines `BookTruthTextBootBaseline(I64 phase=BOT_TEXT_PHASE_POST_LOAD, Bool emit_event=TRUE)`.
- `Kernel/BookOfTruth.HC:55815-55822` mutates `bot_text_integrity_baseline_hash`, `bot_text_integrity_last_hash`, `bot_text_integrity_last_phase`, run count, payload, and next tick before any append.
- `Kernel/BookOfTruth.HC:55824-55825` appends the `BOT_EVENT_TEXT_INTEGRITY` event only when `emit_event` is true.
- `Kernel/KExts.HC:62-64` exports the same optional `emit_event` parameter.

Assessment:
The boot call uses the default logging path, but the exported API lets any caller refresh the baseline and text-integrity state without producing the immutable event. Law 3 forbids logging-disable flags or APIs; Law 8 requires the event and record to be synchronous with the operation being recorded.

Required remediation:
- Remove caller control over event emission for baseline/state mutation.
- If a dry-run is needed, make it status-only and prevent mutation of baseline hash, last hash, phase, run count, next tick, or payload.

### WARNING-001: The immutable text-integrity event carries only a 56-bit projection of the kernel hash

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 5: North Star Discipline

Evidence:
- `Kernel/BookOfTruth.HC:55809-55820` computes `hash_now=BookTruthTextHashKernel` but stores `payload=hash_now&0x00FFFFFFFFFFFFFF`.
- `Kernel/BookOfTruth.HC:55824-55831` appends only the compact payload, while the full baseline hash appears in a human console/status string.
- `Kernel/KMain.HC:166-168` and `Kernel/KEnd.HC:162-164` call `BookTruthTextBootBaseline` during boot after `BookTruthBootBaseline`.

Assessment:
The event proves that some text-integrity payload was appended, but the ledger payload cannot reconstruct the full 64-bit text hash or the selected phase. Local console output is useful, but it is not the immutable event payload Sanhedrin can replay later. That weakens the join between TempleOS kernel integrity and inference-side secure-local evidence.

Required remediation:
- Emit a full proof tuple for text integrity, either across adjacent Book-of-Truth events or via a dedicated decoded status record: full hash, phase, commit/build marker, sequence, entry hash, and payload projection.
- Treat truncated payload-only text-integrity rows as advisory until they can be joined to the full local-only status surface.

### WARNING-002: WS13-11 is marked complete without executing the text-integrity smoke oracle

Applicable laws:
- Law 5: North Star Discipline
- Law 2: Air-Gap Sanctity

Evidence:
- `MODERNIZATION/MASTER_TASKS.md:244` marks `WS13-11 Kernel code integrity scanner` complete.
- `MODERNIZATION/MASTER_TASKS.md:2224` records validation as `bash -n automation/bookoftruth-text-integrity-smoke.sh && bash automation/check-no-compound-names.sh HEAD && bash automation/north-star-e2e.sh`.
- `automation/bookoftruth-text-integrity-smoke.sh:93-155` has the actual oracle that requires an input serial log or an explicitly air-gapped QEMU run and verifies BOT `evt=16` rows from kernel source.

Assessment:
The ledger says the new text-integrity task is complete, but the cited command only syntax-checks the smoke harness. It does not prove that boot emitted `evt=16`, that the source was kernel, or that live QEMU evidence used `-nic none` / `-net none`. This is not an air-gap breach because no unsafe VM command was executed in this audit; it is an evidence-completeness gap.

Required remediation:
- Record a replay-mode smoke run over a saved serial log, or a live run with explicit `-nic none` evidence, before treating WS13-11 as promotion-grade.
- Include the serial log path, BOT event count, and text-integrity sequence range in the progress ledger.

### WARNING-003: holyc-inference model-info evidence remains worker-local and cannot join to the new TempleOS text baseline

Applicable laws:
- Law 5: North Star Discipline
- Law 3: Book of Truth Immutability

Evidence:
- `src/gguf/model_info.HC:36-45` accepts tensor offsets/sizes and output buffers, but no TempleOS append proof, kernel text hash, `model_id`, full model digest, tokenizer hash, policy digest, or profile state.
- `src/gguf/model_info.HC:70-122` validates and publishes layout rows and summary counters after preflight.
- holyc-inference policy says model files are untrusted and every model must pass quarantine plus hash-manifest verification before trusted load (`MASTER_TASKS.md:26-30`).
- holyc-inference WS16 secure-local tasks for manifest verification, profile transition events, policy digest, attestation bundle, and key-release handshake remain unchecked (`MASTER_TASKS.md:208-219`).

Assessment:
The worker-side GGUF helper is meaningful parser progress, but it is not a control-plane proof. The newest TempleOS text-integrity baseline gives Sanhedrin a kernel-integrity signal, while holyc-inference gives a model-layout signal; there is still no shared tuple saying "this validated layout ran under this TempleOS text baseline and this Book-of-Truth event sequence."

Required remediation:
- Define a shared `SecureLocalRunProof` header carried by inference model-info/token evidence and TempleOS Book-of-Truth status.
- Minimum fields: `kernel_text_hash_full`, `bot_seq`, `bot_entry_hash`, `model_id`, full model digest, layout digest, policy digest, profile, and inference event digest.

### WARNING-004: Latest inference model-info commit includes a generated bytecode artifact in the proof surface

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- holyc-inference commit `2799283c9554bea44c132137c590f02034c8f726` added `tests/__pycache__/test_gguf_model_info_build.cpython-314-pytest-9.0.3.pyc`.
- The same commit also added the durable HolyC helper `src/gguf/model_info.HC` and source harness `tests/test_gguf_model_info_build.py`.
- Existing Sanhedrin backfill work already flags this family of `.pyc` artifacts as generated cache drift; this audit observes the same artifact as part of the cross-repo proof boundary.

Assessment:
The `.pyc` file is not a core language violation because it is under `tests/`, but it is not durable source, policy, or immutable evidence. Cross-repo proof consumers should ignore generated bytecode and require source-level harnesses plus Book-of-Truth or manifest outputs.

Required remediation:
- Keep Python bytecode caches out of proof commits.
- For validation evidence, reference source harnesses, textual reports, and immutable ledger/manifest outputs only.

## Non-Findings

- No networking code, WS8 networking task, package-download path, socket/TCP/IP/DNS/DHCP/TLS feature, or QEMU launch command was added by the reviewed commits.
- No QEMU command was executed by this audit. The TempleOS guest air-gap was not touched.
- No Law 1 HolyC purity violation was found in the reviewed core changes: TempleOS kernel changes are HolyC, and the inference runtime helper is HolyC.
- No Law 4 integer-runtime violation was found in `src/gguf/model_info.HC`; it uses integer offsets, sizes, bounds, and overflow checks.

## Suggested Sanhedrin Follow-Up

Track a shared `TextModelRunProof` contract. Minimum fields: `templeos_commit`, `kernel_text_hash_full`, `text_phase`, `bot_seq`, `bot_entry_hash`, `model_id`, `model_sha256_hex64`, `gguf_layout_digest`, `tensor_count`, `total_payload_bytes`, `policy_digest_q64`, `profile_mode`, and `inference_event_digest_q64`. Treat missing fields as warning evidence and any caller-controlled no-append mutation of trust state as critical.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show --format=medium --find-renames -- Kernel/BookOfTruth.HC Kernel/KEnd.HC Kernel/KExts.HC Kernel/KMain.HC MODERNIZATION/MASTER_TASKS.md
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference show --format=medium --find-renames -- src/gguf/model_info.HC MASTER_TASKS.md tests/test_gguf_model_info_build.py
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '55790,55890p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMain.HC | sed -n '158,171p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KEnd.HC | sed -n '158,171p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '236,246p;2218,2224p'
sed -n '1,220p' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/bookoftruth-text-integrity-smoke.sh
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gguf/model_info.HC | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '20,32p;206,220p;3920,3928p'
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference ls-files 'tests/__pycache__/*'
```
