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
