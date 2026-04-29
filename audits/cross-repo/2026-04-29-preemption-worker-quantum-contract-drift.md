# Cross-Repo Preemption / Worker Quantum Contract Drift Audit

Timestamp: 2026-04-29T13:42:33+02:00

Audit angle: cross-repo invariant check between the latest TempleOS timer-preemption hooks and holyc-inference worker batching/yield assumptions.

Repositories audited:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `ada76461a008bb46731359fdf2e7ab1708d15d92`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Safety posture: read-only against TempleOS and holyc-inference. No TempleOS guest, QEMU, VM, liveness watcher, process restart, WS8 networking task, socket, TCP/IP, UDP, TLS, DHCP, DNS, or HTTP work was executed.

## Summary

Found 5 findings: 0 critical, 5 warnings.

TempleOS has crossed from pure cooperative-scheduler doctrine into an initial timer-preemption hook: `IRQ_TIMER` now calls `IRQTimerPreemptHook`, which calls `SchedPreemptTick`, and advances to `CTask.next_task` when the hook returns true. holyc-inference still treats worker planning as a caller-bounded token-budget loop with no explicit OS quantum, yield cadence, preemption eligibility, or Book-of-Truth scheduler event tuple. The result is not a Law 1, Law 2, or Law 4 violation; it is Law 5/Law 8 contract drift that can make future throughput evidence ambiguous.

## Findings

### Finding WARNING-001: TempleOS enabled default-on tick preemption before a cross-repo worker quantum contract exists

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `TempleOS/Kernel/Sched.HC:38-49` defines `SCHED_PREEMPT_QUANT_DFT=4` and initializes `sched_preempt_on=TRUE`, `sched_preempt_quant=4`, and `sched_preempt_budget=4`.
- `TempleOS/Kernel/Sched.HC:93-118` decrements the budget on eligible timer ticks and returns true when the budget expires.
- `TempleOS/Kernel/KInts.HC:37-43` calls `IRQTimerPreemptHook`, tests `RAX`, and advances `RSI` to `CTask.next_task` when preemption fires.
- `TempleOS/MODERNIZATION/SCHEDULER_V0.md:22-26` still says enabling default forced preemption before guardrails and tracing gates are in place is out of scope for v0.

Assessment:
The code is HolyC/assembly and local-only, but the policy state is ahead of the cross-repo integration contract. holyc-inference has no documented way to map a batch planning step or forward-pass phase to the new four-tick default quantum.

Required closure:
- Define an OS/worker quantum ABI before counting inference throughput as scheduler-safe: `{preempt_on, preempt_quant, max_worker_ticks, yielded, resumed, profile_id}`.
- Decide whether inference workers are eligible for timer preemption by default or must remain cooperative until a yield callback exists.

### Finding WARNING-002: holyc-inference batch planning consumes arbitrary token budgets without a TempleOS yield/preemption handshake

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- `holyc-inference/src/runtime/batch_scheduler.HC:142-153` accepts `token_budget` as a caller input.
- `holyc-inference/src/runtime/batch_scheduler.HC:256-294` spends that budget in prefill and decode loops until exhausted, with no yield hook, jiffy counter, or scheduler callback.
- `TempleOS/Kernel/Sched.HC:16-23` still documents legacy tasks as running until they voluntarily call `Yield()`.
- `TempleOS/Kernel/Sched.HC:93-118` now adds timer preemption accounting, but exposes no worker-plane callback to report forced preemptions back to inference.

Assessment:
Preemption may prevent total CPU monopoly, but the worker plane still cannot report whether a plan respected a TempleOS scheduling quantum or was interrupted mid-phase. Future performance reports can therefore show token progress without proving scheduler fairness or audit proximity.

Required closure:
- Add a worker-visible bounded-step contract: `max_tokens_per_quantum` or `max_ticks_per_step`.
- Emit or return `yield_required`, `preempted`, or `elapsed_jiffies` fields from trusted worker planning evidence.

### Finding WARNING-003: scheduler smoke proves hook presence, not runtime safety around Book-of-Truth timing

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `TempleOS/automation/sched-preempt-smoke.sh:16-23` only checks for `IRQTimerPreemptHook`, the hook call, the `next_task` advance, and the four exported `SchedPreempt*` functions.
- `TempleOS/Kernel/KInts.HC:32-39` calls `IRQTimerHook` and then `IRQTimerPreemptHook`; `IRQTimerHook` routes to `BookTruthIRQHook` at `KInts.HC:115-118`.
- `TempleOS/Kernel/Sched.HC:78-90` reports preemption counters, but the smoke script does not assert counter behavior, Book-of-Truth ordering, or no-preempt critical sections.

Assessment:
The smoke guard is a useful structural test, but it cannot prove that Book-of-Truth hooks remain synchronous and hardware-proximate under preemptive task switching. This matters because Law 8 treats logging proximity as a core invariant, not a best-effort telemetry side effect.

Required closure:
- Add replay/compile evidence that timer IRQ logging occurs before any preemptive task advance and records the sequence boundary.
- Add a negative fixture proving no Book-of-Truth write path is preempted between event composition and UART output.

### Finding WARNING-004: no shared evidence row connects preemption state to inference throughput claims

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `TempleOS/Kernel/Sched.HC:78-90` emits `SchedPreemptStatus` with preemption counters and quantum fields.
- `holyc-inference/src/bench/q4_0_dot_bench.HC` emits cycles/dot and dots/sec fields, but these are benchmark-local timing fields, not OS scheduler state.
- `holyc-inference/src/runtime/batch_scheduler.HC:303-305` returns active count, prefill tokens, and decode tokens, but not TempleOS quantum, preempt count, or yield count.

Assessment:
Performance can improve or regress because of inference kernels, TempleOS preemption, Book-of-Truth hooks, or timer behavior. Without one combined evidence tuple, Sanhedrin cannot attribute throughput changes or enforce that performance wins happened with scheduler and audit controls enabled.

Required closure:
- Require north-star/benchmark rows to include `{templeos_commit, inference_commit, preempt_on, preempt_quant, preempt_switch_ticks_delta, bot_irq_seq_delta, token_budget, tokens_planned}`.
- Treat throughput rows without scheduler state as non-north-star-eligible.

### Finding WARNING-005: preemption eligibility is not tied to secure-local policy state

Applicable laws:
- Law 5: North Star Discipline
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/src/runtime/batch_scheduler.HC:69-112` gates planning on profile, policy digest, and attestation flags.
- `TempleOS/Kernel/Sched.HC:60-76` allows `SchedPreemptSet(quantum,on)` without profile, attestation, policy digest, or Book-of-Truth resource-pressure inputs.
- `TempleOS/Kernel/KExts.HC:1625-1628` exports the preemption controls generally.

Assessment:
Preemption is a kernel scheduler feature, but trusted inference needs to know whether the scheduler state is compatible with `secure-local` evidence. A future run could pass secure-local worker gates while the OS scheduler was switched to an unreviewed quantum or disabled mode, or conversely enforce preemption during a path that assumes cooperative atomicity.

Required closure:
- Include scheduler policy state in `InferencePolicyDigest` or its TempleOS successor.
- Log `SchedPreemptSet` changes to Book of Truth with profile/context so inference evidence can prove which scheduler policy governed a run.

## Non-Findings

- No air-gap breach was found or induced.
- No WS8 networking task was executed or recommended.
- No TempleOS or holyc-inference source file was modified.
- The audited code remains HolyC/assembly in core paths; this report flags integration contract drift, not foreign-language implementation.
- The preemption hook itself is not rejected here; the missing piece is cross-repo evidence and policy binding.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show --name-status --oneline ada76461a008bb46731359fdf2e7ab1708d15d92
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC | sed -n '1,140p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KInts.HC | sed -n '1,130p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-preempt-smoke.sh | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/SCHEDULER_V0.md | sed -n '1,115p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/runtime/batch_scheduler.HC | sed -n '1,380p'
rg -n "SchedPreempt|IRQTimerPreempt|token_budget|Yield\\(|preempt|jiff|policy_digest|attestation" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src -g '*.HC' -g '*.HH' -g '*.md'
```
