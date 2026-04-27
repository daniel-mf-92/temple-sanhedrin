# Law 8 Backfill: TSC/MSR Hardware-Proximity Evidence

Timestamp: 2026-04-27T23:14:24Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Scope: historical compliance backfill for LAWS.md Law 8's TSC/MSR hardware-proximity clause. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS: `7dda2fe708d103d591b2e93d8e4e65c43a1569e0`
- holyc-inference: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin: branch `codex/sanhedrin-gpt55-audit`

## Rule Under Audit

Law 8 requires Book-of-Truth hardware evidence to touch the metal with zero bypassable software layers. It explicitly calls out:

- MSR/TSC reads going through a wrapper library instead of raw `rdmsr`/`rdtsc`
- MSR monitoring using `rdmsr`/`wrmsr` directly, with no wrapper library
- TSC reads using `rdtsc` directly, with no OS timer abstraction

Compliance score for the audited TSC/MSR evidence surface: **0/3 compliant**.

## Finding CRITICAL-001: MSR baseline evidence was implemented through `GetMSR`, a wrapper layer forbidden by Law 8

Historical introduction:
- Commit `608d61e37ca647d3e330718797b7bbf0e10fd55c` on 2026-04-12 added `BookTruthMSRBaseline`.
- The same commit added `_GET_MSR` in `Kernel/KUtils.HC`, exported it as `GetMSR` in `Kernel/KernelB.HH`, and used `value=GetMSR(msr);` inside `BookTruthMSRSample`.

Current evidence:
- `Kernel/KernelB.HH:270-271` still exports `GetMSR` as a "read helper."
- `Kernel/KUtils.HC:467-475` implements `_GET_MSR` as an assembly helper around `RDMSR`.
- `MODERNIZATION/MASTER_TASKS.md:182` says MSR monitoring must use `rdmsr`/`wrmsr` directly with no wrapper library.

Assessment:
The helper itself eventually executes `RDMSR`, but Law 8's prohibition is about the layer between the monitored hardware fact and the Book-of-Truth entry. The baseline evidence path introduced a reusable `GetMSR` wrapper and routed Book-of-Truth MSR sampling through it, so the commit is non-compliant with the later explicit Law 8 wording.

Required remediation:
- Treat `GetMSR` as acceptable for non-Book-of-Truth general kernel code only, if needed.
- For Book-of-Truth MSR evidence paths, inline the `RDMSR` instruction sequence in the append path or use a tightly scoped macro that cannot be redirected independently from Book-of-Truth code.

## Finding CRITICAL-002: TSC gap evidence was implemented through `GetTSC`, not inline `rdtsc`

Historical introduction:
- Commit `5c859a17920b5fe3219a80423a30bee21fdc4316` on 2026-04-12 added `BookTruthTSCGapTick`.
- The implementation reads the timestamp with `now=GetTSC;` before deciding whether to append `BOT_EVENT_TSC_GAP`.

Current evidence:
- `Kernel/BookOfTruth.HC:11101-11131` still shows `BookTruthTSCGapTick` using `GetTSC` and then calling `BookTruthAppend`.
- `Kernel/KernelB.HH:294` exposes `GetTSC()` as an internal `IC_RDTSC` helper.
- `MODERNIZATION/MASTER_TASKS.md:183` states that TSC reads must use `rdtsc` directly, with no OS timer abstraction.

Assessment:
`GetTSC` is closer to the instruction than a wall-clock timer API, but it is still a shared intrinsic/helper boundary. Law 8 says the Book-of-Truth path must not route TSC reads through a wrapper library. This creates a bypassable or replaceable layer between the hardware counter and the ledger decision.

Required remediation:
- Replace Book-of-Truth TSC evidence reads with an inline `RDTSC` sequence in the same HolyC/assembly path that composes and appends the event.
- Keep ordinary `GetTSC` uses outside Book-of-Truth evidence out of this violation scope.

## Finding WARNING-001: MSR watchdog was marked complete but current HEAD retains only stale callsites/externs

Historical evidence:
- Commit `edbefe0307bede3ec6fe6de2d8f386285cd34f81` on 2026-04-15 added `BookTruthMSRWatchSet`, `BookTruthMSRWatchStatus`, and `BookTruthMSRWatchTick`; the tick path used `current=GetMSR(msr);`.
- `MODERNIZATION/MASTER_TASKS.md:3520` records CQ-124 as complete for the Book-of-Truth MSR drift watchdog.

Current evidence:
- `Kernel/KExts.HC:27-29` still declares `BookTruthMSRWatchSet`, `BookTruthMSRWatchStatus`, and `BookTruthMSRWatchTick`.
- `Kernel/KTask.HC:755-770` still defines `TaskBookTruthMSRWatchTick` and calls `BookTruthMSRWatchTick`.
- A current-head grep of `Kernel/BookOfTruth.HC` finds MSR drift status readers and constants, but no definitions for `BookTruthMSRWatchSet`, `BookTruthMSRWatchStatus`, `BookTruthMSRWatchTick`, or `BookTruthMSRBaseline`.
- Commit `5f64ffc89375d92fcc78eaf1505ee2325af2705d` on 2026-04-21 deleted 21,559 lines from `Kernel/BookOfTruth.HC`; after that commit, grepping the tree shows the stale extern/tick references but not the producer definitions.

Assessment:
This is not only a hardware-proximity concern. The historical task ledger says the MSR watchdog is complete, but current HEAD no longer contains the producer definitions required for the periodic task to execute. That makes any compliance score for MSR monitoring worse than "uses a wrapper": at current HEAD, the committed watchdog surface appears incomplete or stale.

Required remediation:
- Restore or intentionally retire the MSR watchdog producer path.
- If restored, rebuild it with direct `RDMSR` semantics under Law 8 rather than reviving the historical `GetMSR` wrapper pattern.
- Add a Sanhedrin static check that exported Book-of-Truth watchdog symbols have matching definitions before a completed CQ can count as active evidence.

## Finding WARNING-002: Task history accepted wrapper-based validation despite the existing modernization hardware-proximity rule

Evidence:
- `MODERNIZATION/MASTER_TASKS.md:176-186` already contained the hardware-proximity doctrine, including "MSR monitoring uses `rdmsr`/`wrmsr` instructions directly" and "TSC reads use `rdtsc` directly."
- `MODERNIZATION/MASTER_TASKS.md:3486` then accepted CQ-090 as done while explicitly saying it added an MSR read primitive `GetMSR`.
- `MODERNIZATION/MASTER_TASKS.md:3499` accepted CQ-103 TSC-gap work with symbol-search validation rather than checking for inline `RDTSC` in the Book-of-Truth path.
- `MODERNIZATION/MASTER_TASKS.md:3520` accepted CQ-124 MSR drift work without recording a direct-`RDMSR` proximity check.

Assessment:
The rule existed in the modernization plan before the cited completions, but the completion evidence relied on symbol presence and smoke scripts. It did not validate the exact instruction-proximity invariant. This is historical audit drift: the task ledger overstates completion for the Law 8 metal-touching part of WS13-06/WS13-09.

Required remediation:
- Add a backfill checklist for completed Book-of-Truth hardware tasks: direct UART `OUT`, direct `RDTSC`, direct `RDMSR`, direct `WRMSR`, and no helper function boundary in the audited path.
- Mark CQ-090/CQ-103/CQ-124 as requiring Law 8 proximity follow-up unless the builders replace the helper-based evidence paths.

## Non-Findings

- This audit did not inspect or modify live liveness state.
- No TempleOS guest was launched.
- No networking, package manager, VM, QEMU, or WS8 networking command was run.
- holyc-inference was not flagged by this backfill because the audited Law 8 TSC/MSR producer surface is TempleOS Book-of-Truth-specific.

## Read-Only Verification Commands

- `rg -n "rdtsc|RDTSC|rdmsr|RDMSR|MSR|TSC|GetMSR|GetTSC|BookTruth.*MSR|BookTruth.*TSC" TempleOS/Kernel TempleOS/MODERNIZATION TempleOS/automation`
- `git -C TempleOS show --patch 608d61e37ca647d3e330718797b7bbf0e10fd55c -- Kernel/BookOfTruth.HC Kernel/KUtils.HC Kernel/KernelB.HH`
- `git -C TempleOS show --patch 5c859a17920b5fe3219a80423a30bee21fdc4316 -- Kernel/BookOfTruth.HC Kernel/KTask.HC Kernel/KExts.HC`
- `git -C TempleOS show --patch edbefe0307bede3ec6fe6de2d8f386285cd34f81 -- Kernel/BookOfTruth.HC Kernel/KTask.HC Kernel/KExts.HC`
- `git -C TempleOS grep -n "BookTruthMSRWatchSet\\|BookTruthMSRWatchTick\\|GetMSR\\|BookTruthMSRBaseline" HEAD -- Kernel/BookOfTruth.HC Kernel/KExts.HC Kernel/KTask.HC Kernel/KUtils.HC Kernel/KernelB.HH`
