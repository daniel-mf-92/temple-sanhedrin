# WS8 Networking Task Backfill

Timestamp: 2026-04-28T02:40:49+02:00

Audit owner: gpt-5.5 sibling, retroactive scope only

Repos examined:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

Audit angle: compliance backfill for Law 2's "WS8 networking tasks are frozen/out-of-scope" requirement.

## Scope

This audit checked historical and current evidence for:
- TempleOS WS8 networking task execution.
- Additions of guest networking stack, NIC, sockets, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, tap, bridge, hostfwd, or QEMU user networking patterns.
- Cross-repo ambiguity caused by both repos using the `WS8` workstream label for different meanings.

This audit did not run QEMU, did not inspect live liveness, and did not modify TempleOS or holyc-inference.

## Method

Commands used from the Sanhedrin worktree:

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --all --date=iso-strict --format='%H%x09%ad%x09%s' -S'WS8' -- MASTER_TASKS.md MODERNIZATION MASTER_TASKS.md .github automation
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS grep -n -E 'WS8|networking stack|TCP/IP|UDP|DNS|DHCP|HTTP|TLS|socket|NIC drivers|hostfwd|tap|bridge|user-mode networking' HEAD -- MASTER_TASKS.md MODERNIZATION automation .github README.md
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log --all --date=iso-strict --format='%H%x09%ad%x09%s' -S'WS8' -- MASTER_TASKS.md LOOP_PROMPT.md automation docs bench src tests
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference grep -n -E 'WS8|networking stack|TCP/IP|UDP|DNS|DHCP|HTTP|TLS|socket|NIC drivers|hostfwd|tap|bridge|user-mode networking' HEAD -- MASTER_TASKS.md LOOP_PROMPT.md automation docs bench src tests
```

## Summary

No executed TempleOS WS8 networking implementation was found in the scoped current files. The current TempleOS task file explicitly freezes WS8 networking and marks WS8-01 through WS8-04 as "WON'T DO under air-gap policy". Current automation includes an enforcement script that rejects guest-network patterns and the loop prompt injects the hard no-network guard.

The backfill found 4 findings, all non-critical. The risk is not present guest networking code; it is audit ambiguity that could let future agents misread frozen WS8 policy.

## Findings

### WARNING: TempleOS north-star still lists networking as an outcome

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md` line 15 currently lists `Network stack (IPv4/IPv6, TCP/UDP, TLS strategy)` under North-Star Outcomes.
- The same file lines 123-128 freezes `WS8 - Networking` and marks all WS8 tasks as `WON'T DO under air-gap policy`.
- The same file lines 3598-3602 records the air-gap decision and says WS8 networking tasks remain out-of-scope unless explicitly reversed.

Impact: Future retroactive audits and builder agents have contradictory top-level cues. The deeper and more specific WS8 freeze should control, but the north-star list still advertises networking as a desired outcome.

Severity: WARNING, Law 2 ambiguity.

Recommended follow-up: Update TempleOS planning text to mark networking as "frozen/out-of-scope while air-gap policy stands" wherever it appears as a north-star outcome.

### WARNING: `WS8` means different things across the two audited repos

Evidence:
- TempleOS `MODERNIZATION/MASTER_TASKS.md` defines `WS8 - Networking`.
- holyc-inference `MASTER_TASKS.md` defines `WS8 - Integration & Polish`, with WS8-03 as Book of Truth integration hooks.
- holyc-inference completed IQ-1791 through IQ-1799 cite `(WS8-03, WS16-06)` for Book-of-Truth token event work, not networking.

Impact: The hard safety requirement says "Do not execute WS8 networking tasks". Without repo-qualified labels, a naive grep over `WS8` can confuse valid inference integration work with frozen TempleOS networking work.

Severity: WARNING, Law 2 auditability ambiguity.

Recommended follow-up: In Sanhedrin checks and future reports, refer to `TempleOS WS8 Networking` and `holyc-inference WS8 Integration` explicitly.

### INFO: Current TempleOS scoped files show defensive air-gap enforcement, not networking enablement

Evidence:
- `TempleOS/MODERNIZATION/CI_NOTES.md` forbids NIC devices, sockets, packet forwarding, user-mode networking, bridges, and hostfwd.
- `TempleOS/automation/enforce-templeos-airgap.sh` scans for sockets, TCP/UDP/DNS/DHCP/HTTP/TLS, NIC model names, QEMU `-netdev`, hostfwd, guestfwd, tap, bridge, and user networking.
- `TempleOS/automation/codex-modernization-loop.sh` injects the no-network guard into the builder prompt.

Impact: This is positive backfill evidence that current TempleOS tooling records WS8 networking as blocked and actively rejects common guest-network patterns.

Severity: INFO.

### INFO: Current holyc-inference scoped files preserve air-gap constraints around host-side QEMU tooling

Evidence:
- `holyc-inference/bench/qemu_prompt_bench.py` rejects conflicting QEMU networking arguments and injects `-nic none`.
- `holyc-inference/bench/README.md` documents that the runner always injects `-nic none`.
- `holyc-inference/docs/GGUF_FORMAT.md` says no sockets, HTTP, model downloaders, or VM guest networking.
- `holyc-inference/automation/codex-inference-loop.sh` injects the same no-network guard.

Impact: Inference-side WS8 integration work does not currently appear to execute TempleOS WS8 networking tasks or enable guest networking.

Severity: INFO.

## Backfill Verdict

No critical Law 2 violation found for WS8 networking task execution.

Open audit risk remains: TempleOS planning text still names networking as a north-star outcome, and the cross-repo `WS8` label collision can inflate false positives or hide future regressions unless reports qualify the repo and workstream title.
