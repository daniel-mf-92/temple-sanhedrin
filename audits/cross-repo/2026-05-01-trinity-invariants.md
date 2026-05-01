# Cross-Repo Trinity Invariant Audit - 2026-05-01

Scope: historical cross-repo invariant audit across current local heads, not live liveness watching.

Repos audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf26398`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- temple-sanhedrin reference prompt: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-sanhedrin` at `e519adc6013e`
- Audit repo branch: `codex/sanhedrin-gpt55-audit` at pre-audit `5cdf6e3a9e7a`

Commands run:
- `bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh`
- `bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh`
- Targeted `rg`/`sed` reads over `MODERNIZATION/MASTER_TASKS.md`, `LOOP_PROMPT.md`, `src/`, and `Kernel/`.

## Summary

The high-level Trinity policy signatures are currently synchronized: `check-trinity-policy-sync.sh` passed 21 checks with 0 failures. The deeper release and integration surfaces still show drift: secure-local release acceptance is not yet backed by all required inference artifacts, inference-side Book-of-Truth token events are local tuple buffers rather than TempleOS ledger events, and stale remote-SSH test instructions remain in control prompts despite the hard air-gap posture.

Findings: 4 total - 1 critical, 3 warnings.

## Findings

### CRITICAL - Secure-local release gate fails required trusted-load checks

Evidence:
- `automation/inference-secure-gate.sh` exits 1 with 6 passed, 3 failed.
- Failed checks:
  - `WS16-03`: missing exact `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`
  - `WS16-04`: missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`
  - `WS16-05`: missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`
- `src/model/trust_manifest.HC` exists and contains `TrustManifestVerifyPathCheckedNoPartial` plus `TrustManifestVerifyEntrySHA256Checked`, but not the gate's expected public verifier symbol.

Impact: TempleOS and inference docs both require quarantine/hash verification, deterministic promotion parity, and parser hardening before trusted secure-local load. The release gate correctly prevents release, but the cross-repo invariant is not complete until these exact gate surfaces exist or the gate is updated to the canonical symbol names.

Relevant laws/invariants:
- Law 5 / North Star Discipline: secure-local gate work must be real release-blocking evidence, not just policy text.
- Trinity policy: trusted model load path must not bypass quarantine/hash verification.

Recommended follow-up:
- Either add the missing HolyC public gate symbols/files in holyc-inference or revise `inference-secure-gate.sh` to check the canonical existing symbols. Do not weaken the gate.

### WARNING - Inference Book-of-Truth token events are not yet TempleOS ledger events

Evidence:
- `holyc-inference/src/model/inference.HC` defines `INFERENCE_BOT_EVENT_TUPLE_CELLS` and many `InferenceBookOfTruthTokenEventEmitChecked*` helpers that stage six-cell event buffers.
- A targeted search of `holyc-inference/src` found no calls to TempleOS ledger surfaces such as `BookTruthAppend`, `BookTruthDMARecord`, `BookTruthIOPortRecord`, `OutU8`, or UART `0x3F8`.
- TempleOS `Kernel/BookOfTruth.HC` exposes ledger primitives such as `BookTruthAppend`, `BookTruthDMARecord`, `BookTruthIOPortRecord`, and port log helpers, but the current event enum range found in the file does not expose an inference-token-specific event type.

Impact: holyc-inference has useful local no-partial/token-event tuple logic, but it does not yet satisfy the stronger cross-repo claim in `holyc-inference/MASTER_TASKS.md` that every token is logged to the Book of Truth. Before WS8-03 or token logging is treated as complete, TempleOS needs a canonical inference token event type and inference needs a real integration point that reaches the ledger path.

Relevant laws/invariants:
- Laws 3, 8, 9, and 11: Book-of-Truth events must be immutable, immediate, fail-closed, and local-only.
- Trinity split-plane model: TempleOS remains the trust/control plane; inference cannot define a parallel pseudo-ledger as the accepted record.

Recommended follow-up:
- Define a TempleOS `BOT_EVENT_INFERENCE_TOKEN` or equivalent canonical event and a minimal HolyC call contract for inference to append token events without adding network/export paths.

### WARNING - Control prompts still recommend remote SSH validation despite local air-gap policy

Evidence:
- TempleOS `MODERNIZATION/LOOP_PROMPT.md` includes `SSH access: ssh -o StrictHostKeyChecking=no azureuser@52.157.85.234` for a remote test VM.
- holyc-inference `LOOP_PROMPT.md` includes the same Azure VM and SSH instructions.
- temple-sanhedrin `LOOP_PROMPT.md` tells Sanhedrin to SSH to that VM to query compile-test results.
- The QEMU examples include `-nic none`, so this is not evidence of guest networking. The drift is around remote host validation provenance and the newer hard stance that the TempleOS guest stays fully air-gapped and networking tasks are out-of-scope.

Impact: Builders may treat remote SSH as expected validation even when local read-only/historical audit can avoid network dependence. This is not a guest air-gap breach by itself, but it blurs audit provenance and conflicts with the strictest reading of current air-gap instructions.

Relevant laws/invariants:
- Law 2: QEMU/VM runs must disable guest networking.
- User hard safety requirement: keep the TempleOS guest fully air-gapped; do not execute WS8 networking tasks.

Recommended follow-up:
- Clarify prompts that remote SSH, if retained for host-side compile infrastructure, is never guest networking and never required for audit acceptance. Prefer local artifact evidence in audit reports.

### WARNING - TempleOS top-level North-Star outcomes still mention networking while WS8 is frozen

Evidence:
- TempleOS `MODERNIZATION/MASTER_TASKS.md` top-level North-Star outcomes still list `Network stack (IPv4/IPv6, TCP/UDP, TLS strategy)`.
- The same file later states `WS8 is frozen by policy while the project remains air-gapped` and marks WS8 networking items as `WON'T DO under air-gap policy`.
- holyc-inference policy is stricter and explicit: models are disk-only with no downloading, HTTP, or networking; WS15-04 says OpenAI-compatible local API must be CLI/serial and no HTTP.

Impact: The detailed WS8 section is compliant, but the top-level outcome can still mislead automated task selection or retroactive scoring into treating networking as a live modernization objective. That is an avoidable cross-repo invariant ambiguity.

Relevant laws/invariants:
- Law 2: no networking stack, NIC drivers, sockets, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or similar guest networking features.

Recommended follow-up:
- Replace the top-level networking outcome with an explicit frozen/non-goal line while air-gap policy is active, matching the WS8 section.

## Positive Controls Observed

- Trinity policy sync script passes across secure-local default, dev-local guardrails, quarantine/hash, GPU IOMMU + Book-of-Truth hooks, attestation/policy digest, and drift guard signatures.
- holyc-inference `bench/qemu_prompt_bench.py` rejects QEMU network args and builds commands with `-nic none`.
- TempleOS `MODERNIZATION/NORTH_STAR.md` uses a headless QEMU command with `-nic none`.
- TempleOS `Kernel/IOMMU.HC` contains GPU IOMMU guard scaffolding that records Book-of-Truth DMA events on allow/deny paths.

## Non-Actions

- Did not modify TempleOS or holyc-inference source.
- Did not run live liveness watchers or process restarts.
- Did not execute QEMU or any remote SSH command.
