# Cross-Repo Audit: Dev-Local Guardrail Escape-Hatch Drift

Timestamp: 2026-04-28T13:47:04+02:00

Scope: historical cross-repo invariant check across read-only TempleOS, holyc-inference, and Sanhedrin policy surfaces. No TempleOS or holyc-inference source files were modified. No QEMU or VM command was executed.

TempleOS commit under audit: `e868ba65878b282ff5b2d2464b6bd95cb56e6c76 feat(modernization): codex iteration 20260428-084920`

holyc-inference commit under audit: `ce09228422dae06e86feb84925d51df88d67821b feat(inference): codex iteration 20260428-085506`

## Contract Under Audit

`dev-local` is permitted only as an explicit local experimentation profile. It may not disable the air-gap or Book of Truth. It also may not let relaxed throughput paths be mistaken for `secure-local` promotion, trusted-load, or security-on performance evidence.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:33-39` defines `secure-local` as default, states `dev-local` must remain air-gapped and must not disable Book of Truth, and requires promotion gates before trusted use.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md:38-41` repeats that `dev-local` shortcuts must not merge into default paths without explicit promotion-gate checks.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md:21-36` mirrors the same default, air-gap, Book-of-Truth, and attestation/policy-digest constraints.
- `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md:47-83` directs Sanhedrin to treat secure-local/GPU/profile drift and delegated trust decisions as critical audit surfaces.

## Findings

### WARNING 1: Runtime policy guard toggles can represent disabled Book-of-Truth/quarantine controls without a profile-bound authorization contract

holyc-inference `InferencePolicyRuntimeGuardsSetChecked` accepts binary values for IOMMU, three Book-of-Truth hook flags, quarantine, and hash-manifest gates, then directly stores those global guard values. The digest path records the disabled bits, but it does not require a TempleOS approval event, a Book-of-Truth profile-transition event, or a `dev-local`-only authorization token before controls are turned off.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC:27-33`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC:61-83`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC:135-170`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_policy_digest.py:181-198`

Risk: this is not a direct TempleOS Book-of-Truth disable path, because the code is in the worker repo. The drift is that the worker can produce a valid policy digest for a state with a Book-of-Truth hook bit disabled, while TempleOS policy says even `dev-local` must not disable Book of Truth. A future caller could treat "digest emitted" as "policy accepted" unless the digest consumer rejects forbidden bit patterns.

### WARNING 2: `is_secure_default` is derived from the active profile, not from the immutable default policy

`InferenceProfileStatusChecked` sets `out_is_secure_default` to true only when the active profile is `secure-local`. The tests then expect a `dev-local` digest to clear the secure-default bit. That makes "secure default" behave like "currently secure-local" rather than "the system default remains secure-local."

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/profile.HC:19-20`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/profile.HC:73-78`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC:135-147`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_runtime_policy_digest.py:165-178`

Risk: Sanhedrin or TempleOS could read a dev-local policy digest and infer that the secure-local default has been disabled, or worse, normalize a digest bit that should be an invariant into an ordinary profile-state bit. The policy tuple should distinguish `active_profile` from `default_profile_is_secure_local`.

### WARNING 3: GPU dispatch remains fail-closed on missing booleans, but the booleans are caller-supplied and profile-agnostic

`GPUPolicyAllowDispatchChecked` says `dev-local` still requires hard controls, and it denies dispatch when IOMMU or Book-of-Truth hook flags are false. However, the successful path accepts true caller-supplied booleans for either `secure-local` or `dev-local`; it does not bind those flags to TempleOS attestation, Book-of-Truth serial evidence, or an immutable profile-transition record.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC:4-8`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC:34-40`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/policy.HC:70-94`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:267-279`

Risk: the function is locally fail-closed, which is good. The drift is cross-repo evidence ownership: TempleOS still has the GPU/IOMMU/attestation/key-release producer tasks unchecked, so a worker-side `1,1,1,1` tuple can be structurally accepted before the control plane can prove it.

### WARNING 4: TempleOS requires profile-change and gate-failure Book-of-Truth events, but the worker profile/digest path has no shared event ABI

TempleOS has open WS14 work for boot-visible profile state, Book-of-Truth events for profile changes/model promotions/gate failures, and Sanhedrin enforcement of secure-local invariants. holyc-inference already has profile setters and policy digest helpers, but the cross-repo event schema for profile change, guard toggle, and forbidden dev-local relaxation is not defined.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:259-267`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/profile.HC:36-56`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/policy_digest.HC:175-200`

Risk: profile and guard state can progress independently in the worker without a canonical TempleOS ledger row that says who changed the profile, which guard changed, whether the change was allowed only for dev-local, and whether promotion back to secure-local was blocked until deterministic gates passed.

### WARNING 5: Existing Sanhedrin policy checks can see the doctrine but not the escape-hatch state space

The Sanhedrin prompt and existing trinity policy sync checks focus on doc signatures and high-level source phrases. They catch missing policy language, but they do not yet assert that worker policy digests reject forbidden dev-local states such as disabled Book-of-Truth hooks, disabled quarantine/hash gates, or caller-supplied GPU proof bits without TempleOS attestation.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LOOP_PROMPT.md:47-83`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh:100-122`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:59-69`

Risk: the trinity can remain text-synchronized while an executable worker state represents a policy posture that TempleOS says is forbidden. This is historical Law 5 drift, not a live liveness issue.

## LAWS.md Assessment

- Law 1 HolyC Purity: no violation observed in the inspected runtime files; the worker implementations are HolyC.
- Law 2 Air-Gap Sanctity: no guest networking, VM networking, or WS8 execution was observed; no QEMU command was run during this audit.
- Law 3 / Law 8 / Law 9 Book-of-Truth rules: warning-level cross-repo drift. The worker can encode disabled or caller-supplied Book-of-Truth hook states, but this audit did not observe a TempleOS source change disabling the canonical ledger.
- Law 5 North Star / No Busywork: warning-level drift. `dev-local` policy is present in docs, but the executable state space needs tighter rejection/evidence rules before it can safely feed secure-local promotion or performance claims.

## Recommended Follow-Up

- Split the policy tuple into immutable defaults and active profile: `default_profile_is_secure_local` should remain true even while `active_profile=dev-local`.
- Require policy digest consumers to reject any state where Book-of-Truth hooks, quarantine, or hash-manifest gates are disabled unless the state is explicitly labeled non-promotable dev-local evidence.
- Bind GPU and guard booleans to TempleOS-generated attestation plus Book-of-Truth serial evidence, not arbitrary worker call-site arguments.
- Add a Sanhedrin retro/static check for forbidden dev-local digest bit patterns and for policy tests that bless disabled Book-of-Truth/quarantine controls as acceptable release evidence.

Findings count: 5 warnings, 0 critical.
