# Law 9 Serial Fail-Stop Config Backfill

Date: 2026-04-27T22:03:57Z
Scope: TempleOS historical/current source; holyc-inference not applicable
Audit type: Compliance backfill report
Laws: Law 9, Law 11 adjacency

## Summary

Backfilled Law 9 against the Book-of-Truth serial liveness/fail-stop implementation. The audit found that TempleOS introduced and still retains public HolyC paths that make "dead UART = immediate HLT" conditional on mutable runtime parameters. This conflicts with Law 9's required behavior: "Serial port liveness must be checked; dead UART = immediate HLT" and "Any config flag, boot parameter, or API that disables the halt-on-failure behavior" is a violation.

Findings: 4 total, 3 critical and 1 warning.

## Method

- Read `LAWS.md` for the Law 9 requirement.
- Searched TempleOS source and modernization task history for `halt_on_dead`, `BookTruthSerialLivenessSet`, `BookTruthSerialLivenessCheck`, `SysHlt`, and serial liveness task entries.
- Used `git log -S 'bot_serial_liveness_halt_on_dead' -- Kernel/BookOfTruthSerialCore.HC` and `git blame -L 1180,1260 -- Kernel/BookOfTruthSerialCore.HC` to locate introduction and persistence.
- Did not execute QEMU, VM, live liveness watching, or any write action in TempleOS/holyc-inference.

## Historical Introduction

The current bypass shape traces to TempleOS commit:

- `12a499520445018d44416c853be8a71d37a9f904` (`2026-04-21T23:40:41+02:00`) `feat(modernization): codex iteration 20260421-230527`

That commit added `Kernel/BookOfTruthSerialCore.HC` and introduced:

- `BookTruthSerialLivenessSet(..., Bool halt_on_dead=TRUE)`
- `BookTruthSerialLivenessCheck(..., Bool halt_on_dead=TRUE, ...)`
- `bot_serial_liveness_halt_on_dead`
- `BookTruthSerialLivenessSweep(..., Bool halt_on_dead=FALSE)`

Current `HEAD` still blames the relevant fail-stop control lines to `12a49952`.

## Findings

### CRITICAL: Law 9 fail-stop is runtime-configurable

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1180`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1189`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:159`

`BookTruthSerialLivenessSet(I64 spin=1000, Bool log_on_pass=TRUE, Bool halt_on_dead=TRUE)` assigns caller-controlled `halt_on_dead` into global state:

```text
bot_serial_liveness_halt_on_dead=halt_on_dead;
```

Because the function is public/exported, the Book-of-Truth fail-stop behavior can be disabled at runtime by calling the API with `halt_on_dead=FALSE`. Law 9 explicitly forbids "Any config flag, boot parameter, or API that disables the halt-on-failure behavior."

Recommended remediation for builder loop:

- Remove `halt_on_dead` from the public setter and from mutable global state.
- Make serial-dead behavior unconditional in the fail-stop path.
- If non-halting diagnostics are needed, isolate them under names that cannot be called by scheduled/live liveness enforcement and cannot mutate global halt behavior.

### CRITICAL: Dead UART path can append evidence and continue execution

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1197`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1218`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1225`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1229`

`BookTruthSerialLivenessCheck(..., Bool halt_on_dead=TRUE, ...)` has two gates before halt:

```text
if (!result && halt_on_dead) {
  ...
  if (bot_serial_liveness_halt_on_dead)
    SysHlt;
}
return result;
```

If either the call argument or the global is false, the function returns to the caller instead of halting. This violates Law 9's "dead UART = immediate HLT" and "The machine that cannot record must not run."

Recommended remediation for builder loop:

- In the real liveness/write-path function, replace conditional halt with unconditional `SysHlt` after serial failure is detected and recorded.
- Avoid routing mandatory liveness enforcement through a helper with no-halt modes.

### CRITICAL: Scheduled liveness tick inherits mutable no-halt state

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1232`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1237`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1239`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KTask.HC:732`

The scheduled tick path calls:

```text
BookTruthSerialLivenessCheck(period_jiffies,
                             bot_serial_liveness_spin,
                             bot_serial_liveness_halt_on_dead,
                             bot_serial_liveness_log_on_pass);
```

This means a prior call to `BookTruthSerialLivenessSet(..., halt_on_dead=FALSE)` can cause future scheduled watchdog ticks to check liveness without halting on dead serial. That turns the Law 9 invariant into mutable runtime policy.

Recommended remediation for builder loop:

- Make scheduled tick pass no halt parameter at all; it should always fail-stop.
- Treat `bot_serial_liveness_halt_on_dead` as a historical violation to remove, not as an accepted runtime setting.

### WARNING: Queue/task history normalized a no-bypass requirement as runtime tuning

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:255`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:256`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:901`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:905`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:3076`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:3666`

The modernization plan states WS13-22 as "Unconditional HLT on log write failure -- no bypass, no config, no workaround" and WS13-23 as "HLT if serial is dead." Later completed queue entries accepted `BookTruthSerialLivenessCheck(period_jiffies,spin,halt_on_dead,log_on_pass)` and `BookTruthSerialLivenessSet(...,halt_on_dead=TRUE)` as done work.

This is not a separate code violation beyond the critical findings, but it explains how the bypass entered: the task wording itself carried `halt_on_dead` as an accepted parameter despite the parent invariant saying no config/no bypass.

Recommended remediation for builder loop:

- Add a follow-up queue item that explicitly removes `halt_on_dead` controls from mandatory fail-stop paths.
- Update any future WS13 task text to distinguish diagnostic replay/no-halt simulations from live fail-stop enforcement.

## Current Compliance Score

- Law 9 serial fail-stop API/config surface: 0/1 compliant.
- Historical introduction identified: yes, `12a499520445018d44416c853be8a71d37a9f904`.
- Current-state violation still present: yes.
- holyc-inference impact: none found; Law 9 is modernization-specific.

## Non-Actions

- No TempleOS or holyc-inference source was modified.
- No live loop/liveness checks were performed.
- No QEMU/VM command was run.
- No networking task was executed.
