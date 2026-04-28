# Cross-Repo Scheduler / Worker-Plane Contract Drift Audit

Timestamp: 2026-04-28T08:08:25+02:00

Audit angle: cross-repo invariant check between TempleOS scheduler modernization and holyc-inference continuous batching.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `b61659bc6fc50f625831376aaafaef7254e64fcc`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `d00b791ee4dcb5c65dbeeb9451d058ef72786403`

Safety posture: read-only against TempleOS and holyc-inference. No QEMU/VM command was run. No networking task was executed.

## Scope

This audit checked whether the inference runtime's continuous batching assumptions match the current TempleOS scheduler modernization contract and secure-local worker-plane doctrine.

Primary evidence reviewed:
- TempleOS `Kernel/Sched.HC`
- TempleOS `MODERNIZATION/SCHEDULER_V0.md`
- TempleOS `MODERNIZATION/MASTER_TASKS.md`
- holyc-inference `src/runtime/batch_scheduler.HC`
- holyc-inference `src/runtime/profile.HC`
- holyc-inference `tests/test_runtime_batch_scheduler.py`

## Findings

### WARNING-1: worker scheduler can admit dev-local dispatch without attestation/digest, while TempleOS treats worker-plane evidence as mandatory for trusted flows

TempleOS doctrine states that the high-throughput inference runtime is an untrusted worker plane, and any trusted-load/key-release flow requires attestation evidence plus policy digest match. Missing or invalid evidence must fail closed or force CPU-only safe fallback (`MODERNIZATION/MASTER_TASKS.md:41-47`, `:275-278`).

holyc-inference defaults to secure-local, but `BatchSchedulerSetSecurityGuardsChecked(0, 0)` can disable both scheduler guards under `dev-local`; the batch scheduler only forces both controls when `profile_id == BATCH_SCHED_PROFILE_SECURE_LOCAL` (`src/runtime/batch_scheduler.HC:57-66`, `:99-110`). The test suite explicitly validates that `dev-local` can plan a batch with `policy_digest_match=0` and `attestation_ok=0` (`tests/test_runtime_batch_scheduler.py:188-204`).

Impact: this is not a direct Law 2 or Law 4 violation, but it is a cross-repo contract drift. TempleOS says trusted worker-plane use must fail closed or fall back; the inference scheduler exposes a planning path that can look successful without producing a control-plane-visible "unsafe/dev-only/no trusted release" result.

Recommended closure: add an explicit scheduler result bit or status for `DEV_LOCAL_UNTRUSTED_PLAN`, and require TempleOS control-plane consumers to reject it for trusted-load/key-release dispatch.

### WARNING-2: FIFO contract is ambiguous across repos because holyc-inference ignores `arrival_seq`

TempleOS scheduler v0 documents a future run queue model of "FIFO-with-priority-hints" and scheduler-owned queue operations (`MODERNIZATION/SCHEDULER_V0.md:50-64`). holyc-inference defines both `request_id` and `arrival_seq` in `InferenceBatchRequest`, then selects "stable FIFO array order" by scanning the caller's array index (`src/runtime/batch_scheduler.HC:25-31`, `:134-141`, `:225-238`).

Impact: FIFO means different things in each repo. TempleOS appears to be moving toward scheduler-owned enqueue order, while holyc-inference treats caller-provided array order as the source of truth and never checks monotonic `arrival_seq`. If the control plane compacts, reuses, or priority-sorts the request array, inference fairness can silently diverge from the OS scheduler's FIFO intent.

Recommended closure: define the cross-repo request admission ABI: either `arrival_seq` is authoritative and must be monotonic, or `array index` is authoritative and `arrival_seq` should be removed from the worker-plane contract.

### WARNING-3: continuous batching has no cooperative-yield/quantum boundary despite TempleOS Stage A being cooperative

TempleOS currently documents that tasks run until they voluntarily call `Yield()` (`Kernel/Sched.HC:19-23`), and scheduler modernization v0 explicitly keeps Stage A cooperative with no forced context switch on tick (`MODERNIZATION/SCHEDULER_V0.md:66-70`). The inference batch planner runs prefill and decode loops until `token_budget` is exhausted, with no local yield hook, no max-inner-iteration clamp beyond caller-provided `token_budget`, and no TempleOS scheduler callback (`src/runtime/batch_scheduler.HC:252-294`).

Impact: a large token budget can monopolize a cooperative TempleOS task long enough to delay unrelated scheduler work, including Book-of-Truth tick surfaces that are currently called from task maintenance paths. This is a Law 5 / Law 8 risk if future integration treats "high throughput" as success while starving hardware-proximate audit work.

Recommended closure: make the worker-plane scheduler ABI include a maximum cooperative quantum, or require the TempleOS caller to invoke `BatchSchedulerPlanStepChecked` only with a bounded token budget that maps to a documented scheduler quantum.

### WARNING-4: scheduler evidence covers queue linkage but not worker dispatch latency or policy co-scheduling

TempleOS has a scheduler lifecycle invariant checker that validates circular task queue linkage (`Kernel/Sched.HC:327-414`). That is useful for lifecycle safety, but it does not measure worker-plane dispatch duration, yield cadence, secure-local evidence freshness, or whether inference batches are being planned under the control-plane policy state.

Impact: existing scheduler evidence can pass while cross-repo worker scheduling behavior is still divergent. A future Sanhedrin or release gate could incorrectly treat scheduler health as proven even though the inference worker can run large uninterrupted planning loops or dev-local untrusted plans.

Recommended closure: add a cross-repo scheduler evidence row format with at least `{profile_id, policy_digest_match, attestation_ok, token_budget, active_count, planned_prefill, planned_decode, elapsed_ticks, yielded}`.

### WARNING-5: dispatch planning allocates per call with no resource-class signal for Book-of-Truth supremacy

The batch planner allocates four staging buffers per planning call and returns `BATCH_SCHED_ERR_OVERFLOW` on allocation failure (`src/runtime/batch_scheduler.HC:192-222`, `:307-311`). TempleOS Law 9 requires Book-of-Truth resource supremacy and fail-stop behavior when logging cannot continue; TempleOS WS14 treats the inference runtime as an untrusted worker plane whose performance wins only count with policy gates active (`MODERNIZATION/MASTER_TASKS.md:43-47`).

Impact: this is not a current Law 9 violation inside TempleOS core, but it is an integration gap. The inference scheduler cannot tell the control plane whether an allocation failure was ordinary worker pressure, a pressure condition that should throttle inference, or a pressure condition near Book-of-Truth resource priority boundaries.

Recommended closure: reserve caller-owned staging memory for batch planning or add an explicit resource-pressure status that TempleOS can map to "throttle worker before Book-of-Truth resources are threatened."

## Summary

Findings: 5 warnings, 0 critical violations.

The current implementations remain air-gap-safe and HolyC-only for the audited runtime/core paths. The drift is contractual: holyc-inference's scheduler is internally deterministic, but TempleOS has not yet defined the control-plane ABI needed to bind admission order, policy evidence, cooperative quantum, and resource pressure to OS scheduler guarantees.
