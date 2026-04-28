# Cross-Repo Invariant Audit: Queue Floor Doctrine Drift

Timestamp: 2026-04-28T02:58:42+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical / cross-repo scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `93ad594e8bafbeb20a2dd251822b28af09f6bdea`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `e3cdefd5336ff5a117fb41c6328634d8df774951`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No live liveness watching was performed. No QEMU or VM command was executed.

## Summary

Found 5 findings: 1 critical, 3 warnings, 1 info.

The static queue doctrine now has a hard contradiction. `LAWS.md` still defines queue depth below 25 CQ / 15 IQ as a Law 6 violation, but `LOOP_PROMPT.md` now says the queue floor is abolished, builders must not generate new queue items, and a zero-item queue should exit cleanly awaiting human input. That conflict is no longer theoretical: holyc-inference's committed `MASTER_TASKS.md` has 0 unchecked IQ items against a written 15-item minimum.

## Finding CRITICAL-001: holyc-inference committed queue is empty under the current Law 6 floor

Applicable laws:
- Law 6: Queue Health
- Law 6: No Self-Generated Queue Items, as a competing constraint

Evidence:
- `holyc-inference/MASTER_TASKS.md:231` says to keep at least 15 unchecked IQ items at all times.
- Static count over committed `MASTER_TASKS.md`: `open_iq=0`, `done_iq=1807`.
- The highest committed IQ id is `IQ-1799`, and the final visible queue entries `IQ-1785` through `IQ-1799` are all checked.
- `LAWS.md:80-81` says queue depth dropping below minimum is a violation, with the inference minimum set to 15 IQ.

Assessment:
By the letter of `LAWS.md`, holyc-inference is below the queue-health floor by 15 unchecked IQ items. By the later no-self-generated-queue rule, the inference builder should not repair this by appending its own work. This is a doctrine-level contradiction that currently lands as a concrete empty committed queue.

Impact:
The inference loop can be simultaneously correct under the "do not invent work" override and non-compliant under Law 6 queue health. Historical audits need a single precedence rule before scoring this state as either CRITICAL or expected human-input backpressure.

## Finding WARNING-001: Sanhedrin prompt abolishes the queue floor while LAWS still enforces it

Applicable laws:
- Law 6: Queue Health
- Law 6: No Self-Generated Queue Items

Evidence:
- `LAWS.md:78-84` requires deep rolling queues and says dropping below the 25 CQ / 15 IQ floor is a violation.
- `LAWS.md:195-197` also says builders may not add new unchecked CQ/IQ lines and that the queue is append-only by humans or Sanhedrin external sources.
- `LOOP_PROMPT.md:135-139` says "Queue floor abolished", commands builders not to generate new CQ/IQ items, instructs zero-queue exit with `queue empty - North Star not hit, awaiting human input`, and deprecates any `--min N` queue-depth check.

Assessment:
The prompt override is operationally sensible after the self-padding backfills, but `LAWS.md` was not updated to match it. The same state can now be classified as a Law 6 violation by one auditor and as correct loop behavior by another.

Required remediation:
- Replace the old queue-depth floor with a human-sourced backlog invariant, or explicitly mark the floor as suspended when self-generated queue items are forbidden.
- Add a doctrine precedence statement for "empty queue awaiting human input" so retroactive audits do not conflict with live loop instructions.

## Finding WARNING-002: TempleOS is above the CQ floor, but 10 open CQ items are deprecated queue-depth work

Applicable laws:
- Law 5: North Star Discipline
- Law 6: Queue Health

Evidence:
- Static count over `TempleOS/MODERNIZATION/MASTER_TASKS.md`: `open_cq=43`, `done_cq=1800`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:285-288` still says the loop should keep at least 25 unchecked CQ items available.
- Ten current unchecked CQ entries contain queue-depth guard/wrapper work, including `CQ-1893`, `CQ-1894`, `CQ-1897`, `CQ-1900`, `CQ-1903`, `CQ-1904`, `CQ-1905`, `CQ-1906`, `CQ-1907`, and `CQ-1912`.
- `LOOP_PROMPT.md:139` says queue-depth checks are deprecated and should not be run or cited as validation.

Assessment:
TempleOS currently satisfies the old numeric queue floor, but a material slice of that remaining floor is work the current Sanhedrin prompt says not to execute. A naive "43 open CQ" signal overstates usable north-star backlog.

Required remediation:
- Treat deprecated queue-depth CQ items as non-eligible for north-star work selection.
- Report both raw open CQ count and north-star-eligible open CQ count in future static queue audits.

## Finding WARNING-003: Queue-health enforcement lacks a current computable pass condition

Applicable laws:
- Law 6: Queue Health
- Law 6: No Self-Generated Queue Items
- Law 5: North Star Discipline

Evidence:
- `LAWS.md:81` defines numeric minimums.
- `LOOP_PROMPT.md:137-139` forbids builder queue generation and deprecates min-depth checks.
- TempleOS has 43 raw unchecked CQ items, but 10 are queue-depth tasks now deprecated by prompt.
- holyc-inference has 0 raw unchecked IQ items, which is both below the old floor and the expected outcome when no human/external work has been appended.

Assessment:
After the no-self-generated-queue reform, queue health can no longer be measured by raw unchecked line count alone. A pass condition now needs provenance and eligibility: human/external source, WS traceability, north-star relevance, and not deprecated by current prompt.

Required remediation:
- Define `eligible_queue_depth = unchecked items with accepted provenance + WS trace + north-star relevance + not deprecated`.
- Store accepted queue provenance in a file or commit trailer that Sanhedrin can verify without asking builders to self-pad.

## Finding INFO-001: TempleOS remaining open CQ items retain WS traceability

Applicable laws:
- Law 6: Queue Health

Evidence:
- Static scan found no open `CQ-` lines without a `(WS...)` tag in `MODERNIZATION/MASTER_TASKS.md`.
- Open TempleOS CQ distribution includes WS13 Book-of-Truth items, WS0 governance/spec items, and ten WS1-05 queue-depth automation items.

Assessment:
The remaining TempleOS queue is not provenance-clean or north-star-filtered by this audit, but it is at least workstream-tagged. The main issue is eligibility under the new queue-floor abolition, not missing WS tags.

## Non-Findings

- This audit did not inspect or modify live processes, heartbeats, or current-loop liveness.
- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or WS8 networking task was added or executed.
- No QEMU or VM command was executed; therefore no VM launch arguments were needed beyond this report's read-only evidence review.
- No TempleOS or holyc-inference source code was modified.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
awk '/^- \[ \] CQ-[0-9]+/{open++} /^- \[x\] CQ-[0-9]+/{done++} END{print open, done}' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md
awk '/^- \[ \] IQ-[0-9]+/{open++} /^- \[x\] IQ-[0-9]+/{done++} END{print open, done}' /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md
nl -ba LAWS.md | sed -n '76,84p'
nl -ba LAWS.md | sed -n '191,198p'
nl -ba LOOP_PROMPT.md | sed -n '131,143p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '283,292p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '229,245p'
```
