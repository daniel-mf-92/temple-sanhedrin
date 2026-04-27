# The Laws — TempleOS Purity Doctrine

These are the immutable laws that the two builder agents must follow.
The Sanhedrin agent audits compliance. Violations are logged in `audits/`.

## The Agents Under Audit

| Agent | Repo | Purpose |
|-------|------|---------|
| Modernization Loop | `~/Documents/local-codebases/TempleOS` | TempleOS kernel modernization |
| Inference Loop | `~/Documents/local-codebases/holyc-inference` | Pure HolyC LLM runtime |

## Law 1 — HolyC Purity (Both Agents)

Core OS subsystems and inference engine runtime MUST be HolyC-only.

Violations:
- `.c`, `.cpp`, `.rs`, `.go`, `.py`, `.js`, `.ts` files appearing in `src/`, `Kernel/`,
  `Adam/`, `Apps/`, `Compiler/`, `0000Boot/` directories
- `#include` of C standard library headers in core paths
- Foreign language build systems (Makefile, CMakeLists, Cargo.toml) in core paths

Exceptions:
- Host-side tooling in `automation/`, `tests/`, `.github/` may use any language
- The inference repo `tests/` directory is explicitly for Python/C validation scripts

## Law 2 — Air-Gap Sanctity (Modernization Agent)

The TempleOS guest must remain permanently air-gapped.

Violations:
- Any QEMU/VM command missing `-nic none` or `-net none`
- Addition of TCP/IP, UDP, DNS, DHCP, HTTP, TLS, socket code in core paths
- WS8 networking tasks being executed (they are frozen)
- Network-dependent package managers or build steps

## Law 3 — Book of Truth Immutability (Modernization Agent)

The Book of Truth (WS13) can NEVER be deleted, modified after write, or disabled.

Violations:
- Any code path that could clear, truncate, or overwrite sealed log pages
- Removal of serial port exfiltration logic
- Addition of a "disable logging" flag, config, or API
- Changes that make the hash chain skippable

## Law 4 — Integer Purity (Inference Agent)

The inference engine uses integer-only math for all runtime tensor operations.

Violations:
- `F32`, `F64`, `float`, `double` types in `src/` HolyC files
- x87 FPU instructions in inline assembly (allowed: SSE/AVX integer ops)
- Floating-point math libraries imported into the runtime

Exceptions:
- Float16 scale factors in Q4_0/Q8_0 blocks are converted to fixed-point
  integer representation at load time — the runtime never operates on floats

## Law 5 — No Busywork (Both Agents)

Every iteration must produce meaningful progress toward the north-star outcomes.

Violations:
- Repeated reformatting/rewording of existing docs without adding substance
- Queue items that are pure bookkeeping with no technical content
- 5+ consecutive iterations touching only doc structure without code or specs
- Circular task generation (creating tasks that generate more tasks about tasks)

Indicators of good work:
- New .HC source files with actual HolyC code
- Specs that define concrete data structures, algorithms, or byte layouts
- Test harnesses that validate correctness
- Architecture docs that make implementation decisions (not just list options)

## Law 6 — Queue Health (Both Agents)

Rolling queues must stay deep and derived from real workstream tasks.

Violations:
- Queue depth dropping below minimum (25 CQ for TempleOS, 15 IQ for inference)
- Queue items that don't trace back to a WS task
- Duplicate or near-duplicate queue items
- Queue IDs not monotonically increasing

## Law 7 — Process Liveness (Both Agents)

Both loops must be running at all times.

Checks:
- Loop shell script process must be alive
- Heartbeat file must be updated within last 10 minutes
- At least 1 commit in the last 30 minutes during active hours
- No stuck Codex process (running > 25 minutes = likely hung)

## Law 8 — Book of Truth Immediacy & Hardware Proximity (Modernization Agent)

The Book of Truth must record each act SYNCHRONOUSLY and as close to hardware as possible.

Violations:
- Log entries written in a deferred/async callback instead of inline with the operation
- Buffered writes that batch multiple events before serial output
- Log queue or ring buffer that decouples the event from the serial `out` instruction
- Driver abstraction layer between the log code and the UART port (0x3F8)
- Interrupt logging that happens AFTER the ISR returns instead of INSIDE the IDT handler
- MSR/TSC reads going through a wrapper library instead of raw `rdmsr`/`rdtsc`
- Page table change logging that hooks above the PTE modification instead of inline with it
- Any software layer between the hardware event and the `out 0x3F8` that could be
  bypassed, disabled, or compromised independently of the logging code

Required pattern:
```
Hardware event occurs
  → Log entry composed (same instruction sequence)
    → `out 0x3F8` emits bytes to serial (same instruction sequence)
      → Entry written to in-memory ring buffer (same instruction sequence)
        → Page sealed if buffer page full (same instruction sequence)
```
Zero software layers between event and record. The log touches the metal.

## Law 9 — Resource Supremacy / Crash on Log Failure (Modernization Agent)

The Book of Truth has ABSOLUTE priority over all system resources. The OS dies before the log dies.

Violations:
- Code that skips a log entry due to memory pressure instead of reclaiming from other subsystems
- Code that allows continued execution after a log write failure
- Any config flag, boot parameter, or API that disables the halt-on-failure behavior
- Memory reclamation that frees unsealed (unconfirmed) log pages before user/cache pages
- Disk reclamation that deletes log files before all non-log files are exhausted

Required behavior:
- Priority order: Book of Truth > kernel core > process memory > file cache > user files > swap
- If log cannot be written after exhausting all reclamation: `HLT` instruction, unconditional
- The HLT is in the log write path itself — not a separate error handler that could be removed
- Serial port liveness must be checked; dead UART = immediate HLT

The machine that cannot record must not run.

## Law 10 — Immutable OS Image (Modernization Agent)

Once installed, the OS cannot be modified on the device. Full reinstall required for any change.

Violations:
- Any code path that remounts the OS partition as writable
- Any update/patch/hotfix mechanism in the kernel
- Self-modifying kernel code, runtime patching, or kexec
- Module loading that alters kernel behavior post-boot
- QEMU launch commands missing `-drive readonly=on` for the OS image

## Law 11 — Book of Truth Local Access Only (Modernization Agent)

The Book of Truth can only be read with direct physical access. No remote viewing ever.

Violations:
- Any network-accessible API, endpoint, or protocol for reading the log
- Log export commands (dump to USB, print to file, copy to removable media)
- Serial port output being forwarded, streamed, or proxied to a remote host
- Any code path that makes log contents available outside the local console

The Ark is in the Holy of Holies. You must be present to see it.

## Sanhedrin Enforcement

The Sanhedrin agent does NOT modify the other repos. It:
1. Reads recent commits and diffs from both repos
2. Reads recent iteration logs
3. Checks process liveness
4. Audits changes against the Laws
5. Writes audit reports to `audits/YYYY-MM-DD-HHMMSS.md`
6. If a loop is dead, restarts it via ssh localhost
7. If violations are found, logs them with severity and evidence

Severity levels:
- **CRITICAL** — Law violated, immediate attention needed (air-gap breach, non-HolyC in core)
- **WARNING** — Drift toward violation (busywork pattern, queue thinning)
- **INFO** — Healthy observation, no action needed

The Sanhedrin never sleeps. It watches. It judges. It restores.

## Law 4 — Identifier Compounding Ban (Both Builder Agents)

Forbidden:
- Function/script/file names longer than 40 characters
- Names with more than 5 hyphen- or underscore-separated tokens
- Names that are existing-name + suffix (chained-helper anti-pattern)

Detection: `automation/check-no-compound-names.sh HEAD` in the offending repo.
Enforcement: Sanhedrin reverts the commit + pushes the revert. See `automation/enforce-laws.sh`.

## Law 5 — North Star Discipline

Every iteration must justify how its commit advances `NORTH_STAR.md`. Iterations that don't change the output of `automation/north-star-e2e.sh` must explain why work was still on-path. Iterations that fail this test 5 times in a row trigger an escalation to `audits/blockers-escalated.log`.

## Law 6 — No Self-Generated Queue Items

Builder agents may NOT add new `- [ ] CQ-` or `- [ ] IQ-` lines to MASTER_TASKS.md. The queue is append-only by humans (or by Sanhedrin from external sources). Self-padding the queue is grounds for revert.

## Law 7 — Blocker Escalation

If the same error string (e.g. "readonly database", "command not found") appears in 3+ consecutive iteration logs, Sanhedrin escalates to `audits/blockers-escalated.log` for human action. Builders must NOT continue retrying the same blocked path silently.
