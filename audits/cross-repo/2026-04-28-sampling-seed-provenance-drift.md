# Cross-Repo Sampling Seed Provenance Drift Audit

Timestamp: `2026-04-28T09:41:24+02:00`

Audit angle: cross-repo invariant checks between TempleOS secure-local control-plane policy and holyc-inference WS7 sampling/generation.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `e868ba65878b282ff5b2d2464b6bd95cb56e6c76`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `a5d2d13634a64d246c721206d8e0b9802a4c0a3d`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU/VM command was run. No WS8 networking task was executed. No trinity source code was modified.

## Scope

This audit checked whether the inference runtime's deterministic sampling inputs match the current TempleOS trusted-run and Book-of-Truth evidence contract.

Primary evidence reviewed:
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- TempleOS `Kernel/KMathB.HC`
- holyc-inference `MASTER_TASKS.md`
- holyc-inference `src/model/sampling.HC`

## Summary

holyc-inference has made sampling deterministic only when the caller supplies the exact decoding parameters and `random_q16_values` stream. TempleOS policy requires deterministic prompt/seed/logit-window parity before secure-local promotion and positions TempleOS as the trust/control plane, but the current TempleOS contract only names `Inference("prompt");` as a CLI goal and does not define how seed, random stream, decoding parameters, or per-token sampler inputs enter the Book of Truth.

This is not an observed air-gap or HolyC-purity violation. It is warning-level Law 5 / north-star drift: the repos can both pass local checks while leaving the eventual trusted inference run unreplayable from ledger evidence.

## Findings

### WARNING-001: Inference generation consumes explicit random Q16 lanes, but TempleOS has no trusted-run seed envelope

holyc-inference requires a caller-provided random stream for generation. `SamplingSelectNextTokenChecked` accepts `random_q16` and rejects values outside `[0, 1.0_q16)`. `GenerationRunChecked` requires `random_q16_values`, checks that `max_new_tokens <= random_values_capacity`, and passes `random_q16_values[step_index]` into every `GenerationStepChecked` call. `InferenceGenerateTokensPreflightChecked` separately publishes `required_random_capacity = max_new_tokens`.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2154`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2217`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2603`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2659`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2732`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:7577`

TempleOS requires deterministic inference gate parity, but the current secure-local and CLI policy does not define a seed envelope such as `{seed_id, rng_algorithm, random_q16_count, random_stream_digest}`.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:27`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:31`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:37`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:263`

Impact: a trusted run can be reproduced only if the random Q16 stream is known. If TempleOS logs the prompt, model, and output token but not the seed/stream provenance, Book-of-Truth evidence cannot prove that the token came from the declared deterministic parity baseline.

Recommendation: define a shared sampling provenance tuple for every trusted generation run: `rng_algorithm`, `seed_value`, `random_q16_count`, `random_stream_digest`, `temperature_q16`, `top_k`, `top_p_q16`, `repetition_penalty_q16`, and `sampler_contract_version`.

### WARNING-002: TempleOS default RNG is timer-mixed, while deterministic eval requires stable prompt+seed replay

TempleOS core RNG functions mix `GetTSC` into `Rand*` outputs unless `TASKf_NONTIMER_RAND` has been set by a non-zero `Seed(seed)` call. `Seed(0)` explicitly clears that flag and mixes `GetTSC` into the task seed.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:77`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:81`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:117`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:121`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:147`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC:153`

holyc-inference and TempleOS both define deterministic eval as prompt+seed parity work. Inference explicitly lists validation against llama.cpp for the same prompt+seed+model, and WS16-04 calls out prompt/seed/logit-window parity.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:46`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:55`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:211`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:263`

Impact: if a future TempleOS `Inference("prompt");` implementation derives sampling values from the default task RNG, replay parity will depend on TSC timing unless the integration explicitly forces non-timer seeded mode or bypasses `Rand*` with a deterministic stream generator.

Recommendation: mark timer-mixed `Rand*` as forbidden input for secure-local sampling. Secure-local inference should accept an explicit seed or precomputed `random_q16_values` stream, log its digest, and fail closed if the provenance tuple is absent.

### WARNING-003: Greedy wrappers reduce randomness but do not close the general sampling contract

holyc-inference includes deterministic greedy/default wrappers, but the public WS7 contract still includes temperature, top-k, and top-p sampling. `InferenceGenerateTokensChecked` requires `random_q16_values` even when wrappers choose deterministic parameters, and `SamplingSelectNextTokenChecked` still validates the supplied `random_q16`.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:104`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:110`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:817`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:829`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2765`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC:2794`

Impact: a TempleOS-side integration could choose greedy mode and appear deterministic, while later enabling non-greedy sampling without adding ledger fields. That would create a regression path where Book-of-Truth token evidence loses the sampler inputs needed to explain token selection.

Recommendation: define one evidence schema that covers both greedy and non-greedy runs. Greedy can set `sampler_mode=greedy`, `top_k=1`, `top_p_q16=65536`, and `random_stream_digest=none`, but the fields should still be present.

### WARNING-004: Per-token Book-of-Truth goal does not specify sampler-input adjacency

holyc-inference WS8-03 requires Book-of-Truth hooks for model load, each token, and anomalies. TempleOS requires ledger entries with sequence, TSC timestamp, event type, source, payload, and previous hash, but it does not define a per-token payload that binds token id to the sampler inputs used for that token.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:115`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:360`

Impact: logging `token_id` alone is insufficient for replay or audit. For non-greedy runs, `random_q16`, `top_k`, `top_p_q16`, `temperature_q16`, `repetition_penalty_q16`, and the selected probability/logit are part of the causal token event. Omitting them weakens Law 8 immediacy because the ledger records the visible result but not the adjacent decision state.

Recommendation: introduce a `BOT_INFERENCE_TOKEN` payload v0 with at least `{run_id, token_index, token_id, token_prob_q16, random_q16, sampler_digest, logits_window_digest, history_digest}`. Emit the record synchronously at token commit.

### WARNING-005: Secure-local policy digest can pass while excluding sampler policy

TempleOS requires attestation evidence plus policy digest match from the worker plane, and holyc-inference lists `InferencePolicyDigest;` as a Sanhedrin-readable policy digest target. The audited surfaces do not show that sampler parameters or RNG provenance are mandatory digest inputs.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:43`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:45`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:277`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:216`

Impact: a policy digest could prove profile/quarantine state while leaving sampling behavior mutable. That is a cross-repo invariant gap because deterministic eval parity depends on prompt+seed+logit-window and sampler settings, not only model trust.

Recommendation: require `InferencePolicyDigest` or its successor to commit to sampler contract version, allowed sampler modes, deterministic seed policy, and whether timer-mixed RNG is banned for secure-local.

## LAWS.md Assessment

- Law 1 HolyC Purity: no violation observed. Audited runtime/core implementation is HolyC.
- Law 2 Air-Gap Sanctity: no networking path was added or exercised. No QEMU/VM command was run.
- Law 4 Integer Purity: no floating-point tensor runtime issue observed in the inference sampling path; sampling uses Q16 integer inputs.
- Law 5 North Star / No Busywork: warning-level drift. Deterministic prompt+seed parity is a stated north-star requirement, but the current cross-repo contract does not yet bind seed/random provenance to trusted-run evidence.
- Laws 8-11 Book-of-Truth / immutable image / local access: no direct violation observed. The risk is incomplete future token-event schema, not a current remote/export path.

## Commands Run

Read-only commands only:

```bash
git status --short --branch
git rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
rg -n "seed|random|entropy|RNG|determin" audits/cross-repo audits/backfill audits/research audits/issues audits/trends
rg -n "random_q16|temperature_q16|top_k|top_p|GenerationStep|Sampling|SpecDecode|seed|draft" src tests MASTER_TASKS.md NORTH_STAR.md LOOP_PROMPT.md
rg -n "Rand|Seed\\(|random|entropy|TSC|GetTSC|Generation|Inference|temperature|top_k|top_p|sample|token|BookTruth.*RNG|BookTruth.*Token|BookTruth.*Inference" Kernel Adam Apps MODERNIZATION automation
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC | sed -n '2148,2248p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC | sed -n '2598,2850p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/sampling.HC | sed -n '7530,7615p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '40,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '200,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KMathB.HC | sed -n '70,160p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '21,52p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '260,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '360,370p'
```

Findings count: 5 warnings, 0 critical violations.
