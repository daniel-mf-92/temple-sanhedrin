# Cross-Repo Speculative Decode Control-Plane Drift Audit

Timestamp: `2026-04-28T09:57:11+02:00`

Audit angle: cross-repo invariant check between TempleOS trust/control-plane policy and holyc-inference speculative decode worker-plane behavior.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `7bd055f6265469f435f7e529313289e6ffe6ca09`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU or VM command was executed. No networking task was executed or recommended.

## Scope

This audit checked whether speculative decoding can be enabled, measured, and rejected consistently across the trinity without moving trust decisions into the inference worker plane.

Primary evidence reviewed:
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- TempleOS `MODERNIZATION/LOOP_PROMPT.md`
- holyc-inference `MASTER_TASKS.md`
- holyc-inference `NORTH_STAR.md`
- holyc-inference `src/runtime/quant_profile.HC`
- holyc-inference `src/model/spec_decode.HC`
- holyc-inference `tests/test_model_spec_decode.py`
- holyc-inference `tests/test_runtime_quant_profile.py`

## Summary

holyc-inference has a HolyC speculative decode coordinator and a quant-profile selector that disables speculative decode in `secure-local` but enables it for some `dev-local` preferences. TempleOS correctly states that speculative decode belongs to the untrusted throughput plane, while TempleOS owns profile policy, model trust gates, audit authority, and key-release decisions. The remaining drift is contractual: the repos do not yet define the evidence tuple that proves speculative decode was off, on, accepted, rejected, rolled back, or excluded from a trusted run.

This is not a direct air-gap, HolyC-purity, or integer-purity violation. It is a Law 5 / North Star Discipline warning because throughput work can advance locally without producing the cross-repo evidence TempleOS needs before it can count performance wins under `secure-local`.

## Findings

### Finding WARNING-001: profile selector encodes speculative-decode policy, but TempleOS lacks the matching audit event contract

Evidence:
- `holyc-inference/src/runtime/quant_profile.HC:64-69` sets the default profile to `QUANT_PROFILE_SECURE_LOCAL` and `speculative_decode_enabled = 0`.
- `holyc-inference/src/runtime/quant_profile.HC:104-127` keeps speculative decode disabled for every `secure-local` preference.
- `holyc-inference/src/runtime/quant_profile.HC:130-157` enables speculative decode for `dev-local` throughput and balanced preferences while retaining quarantine and manifest gates.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:258-280` defines `secure-local`/`dev-local`, Book-of-Truth events for profile changes/gate failures, `InferencePolicyDigest`, and secure-on performance acceptance, but does not define a Book-of-Truth field for `speculative_decode_enabled`.

Impact:

The inference worker can make the right local choice, but TempleOS cannot yet prove from trusted evidence whether speculative decode was disabled for a `secure-local` run or intentionally enabled only in `dev-local`. That weakens release-blocker checks because a throughput result can omit the optimization state that materially changes token-generation behavior and audit surface.

Recommendation:

Add `speculative_decode_enabled`, `spec_decode_policy_reason`, `profile_id`, `preference`, and `policy_digest` to the TempleOS trusted-run evidence envelope and Book-of-Truth profile/gate event schema.

### Finding WARNING-002: speculative decode coordinator has deterministic rollback fields, but no cross-repo serial telemetry schema

Evidence:
- `holyc-inference/src/model/spec_decode.HC:241-308` publishes `out_drafted_count`, `out_accepted_count`, `out_reject_index`, and `out_committed_count`.
- `holyc-inference/tests/test_model_spec_decode.py:79-134` validates partial accept, full accept, and window-clamp behavior in the host parity model.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-47` requires attestation evidence, policy digest match, and fail-closed rejection or CPU-only fallback for trusted dispatch, but does not name speculative decode draft/accept/reject counters as required worker evidence.

Impact:

Speculative decoding is only trustworthy if the verifier's rejection and rollback decisions are visible to the trust plane. Without a shared serial or evidence schema, TempleOS may see only final token output and miss whether tokens were drafted, rejected, committed, or rolled back according to deterministic rules.

Recommendation:

Define a serial/trusted-evidence record such as `SPEC_DECODE_STATUS:` with `draft_window`, `drafted_count`, `accepted_count`, `reject_index`, `committed_count`, `used_tokens_before`, `used_tokens_after`, `seed`, `vocab_size`, and `status`. Missing or malformed records should fail closed for any run claiming speculative decode.

### Finding WARNING-003: dev-local speculative decode remains air-gapped, but promotion criteria do not say when it may influence secure-local performance claims

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:33-39` allows `dev-local` only as explicit local experimentation, requires it to remain air-gapped, and requires promotion gates before `secure-local`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:36-67` says `secure-local` is default, `dev-local` shortcuts must not merge into default paths, and performance outputs must be measured with security controls on.
- `holyc-inference/src/runtime/quant_profile.HC:141-153` enables speculative decode for `dev-local` throughput/balanced paths.

Impact:

The current split is safe in principle, but reports can overstate progress if `dev-local` speculative decode throughput is compared to secure-on goals without a policy boundary. The repos need a rule for whether speculative decode must be disabled, separately measured, or promoted through deterministic parity before contributing to `secure-local` acceptance.

Recommendation:

Extend the secure-on performance matrix with explicit rows for `speculative_decode=off`, `dev-local speculative_decode=on`, and any future `secure-local candidate`. Require deterministic eval parity and Book-of-Truth evidence before a speculative path can count toward secure-on throughput.

### Finding WARNING-004: holyc-inference has speculative decode as both optimization and advanced feature, while the north star still requires one forward pass

Evidence:
- `holyc-inference/NORTH_STAR.md:7-20` defines the concrete deliverable as one Q4_0 GPT-2 forward pass on fixed token IDs with serial next-token output.
- `holyc-inference/MASTER_TASKS.md:157-164` lists continuous batching, prefix cache, chunked prefill, speculative decode, quant profiles, autotuning, secure-on SLOs, and fail-closed fast paths under the throughput/GPU workstream.
- `holyc-inference/MASTER_TASKS.md:221-226` separately lists speculative decoding as an advanced inference feature using a small model to draft and a large model to verify.

Impact:

Speculative decode is valuable but can distract from the current one-forward-pass north star unless reports distinguish "infrastructure for future decode loops" from "evidence that advances the fixed GPT-2 forward pass." This is a Law 5 drift risk rather than a code violation.

Recommendation:

Require speculative-decode iterations to state which north-star prerequisite they improve: deterministic token-loop semantics, promotion evidence schema, secure-on performance matrix, or future WS13 decode-loop work. If none apply, Sanhedrin should classify the iteration as non-north-star optimization.

### Finding WARNING-005: worker-plane deterministic seed is not bound to TempleOS trusted-run provenance

Evidence:
- `holyc-inference/src/model/spec_decode.HC:107-160` drafts tokens deterministically from `draft_start_token`, `draft_window`, `vocab_size`, and `seed`.
- `holyc-inference/tests/test_model_spec_decode.py:79-134` proves deterministic host vectors for multiple seed/window cases.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:263-279` calls for deterministic inference gates, attestation, policy digest validation, and key-release checks, but does not bind speculative-decode seed/window parameters into `InferencePolicyDigest` or `InferenceAttestationStatus`.

Impact:

A deterministic worker algorithm is not enough for trusted replay unless the trust plane records the exact seed and window policy. Otherwise two runs can share prompt/model identity while using different speculative draft schedules, producing different acceptance traces and timing claims.

Recommendation:

Bind `spec_decode_seed`, `draft_window`, `draft_capacity`, `accepted_target_policy`, and `vocab_size` into the policy digest or attestation bundle before trusted dispatch.

## Positive Observations

- The audited speculative decode implementation is HolyC and uses integer-only arithmetic.
- `secure-local` remains the default profile and keeps speculative decode disabled in the current inference profile selector.
- `dev-local` speculative decode still requires quarantine and manifest gates in the inference selector.
- No reviewed evidence introduces networking, package downloads, sockets, remote services, or VM networking.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No WS8 networking task was executed or recommended.
- No QEMU or VM command was executed during this audit.
- Recommendations preserve the air-gap and keep core TempleOS/inference implementation in HolyC.

## Commands Run

Read-only commands only:

```bash
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "spec_decode|SpecDecode|draft|accepted|reject|speculative|draft_window|token_capacity|used_tokens" src tests README.md docs MODERNIZATION
rg -n "spec_decode|SpecDecode|draft|accepted|reject|speculative|draft_window|token_capacity|used_tokens" Kernel Adam Apps Compiler 0000Boot MODERNIZATION automation tests
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/quant_profile.HC | sed -n '1,190p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/spec_decode.HC | sed -n '1,340p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '145,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '210,232p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,60p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_spec_decode.py | sed -n '1,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_quant_profile.py | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '21,60p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '250,285p'
rg -n "SpecDecode|speculative|draft|accept|reject|InferencePolicyDigest|policy digest|Book of Truth events|worker plane|trusted dispatch|CPU-only" MODERNIZATION/MASTER_TASKS.md MODERNIZATION/LOOP_PROMPT.md MODERNIZATION/NORTH_STAR.md MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md
```

Finding count: 5 warnings, 0 critical violations.
