# Cross-Repo North-Star Exit-Status Contract Drift Audit

Timestamp: 2026-05-02T07:49:17+02:00

Audit angle: cross-repo invariant check, read-only against TempleOS and holyc-inference current heads.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `9f3abbf263982bf9344f8973a52f845f1f48d109` on `codex/modernization-loop`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726` on `main`
- Sanhedrin laws: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55/LAWS.md`

No TempleOS or holyc-inference files were modified. No live liveness watching, process restart, QEMU/VM command, networking command, package download, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

## Invariant Under Audit

The two builder loops both route "done" through an executable north-star harness. Cross-repo evidence is only comparable if:

- GREEN means the guest path completed under the documented success contract.
- QEMU process status is not normalized away after host cleanup.
- A host-side timeout, SIGTERM, or SIGKILL is recorded as cleanup/failure evidence, not as clean guest halt.
- Inference benchmark reports and TempleOS north-star reports use compatible pass semantics for process completion.

## Findings

### WARNING 1. TempleOS North Star documentation requires QEMU status 0, but the harness accepts killed QEMU exits

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md:22` requires: `QEMU exits with status 0 (clean halt -- no crash, no hang)`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:153` through `156` kills the still-running QEMU process after serial-line collection, then captures `vm_rc`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:194` through `197` treats `vm_rc` values `0`, `143`, and `137` as acceptable.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:199` then prints `GREEN: North Star hit`.

Impact: a host-induced SIGTERM (`143`) or SIGKILL (`137`) can satisfy the same GREEN path as a clean guest halt. That weakens Law 5 north-star evidence because "halt clean" on serial and "QEMU exited cleanly" are no longer independently proven.

### WARNING 2. Serial line order can stand in for clean halt evidence

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:20` through `24` define the required serial lines.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:30` through `40` verifies only line presence and ordering.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:134` through `151` exits the polling loop immediately after required lines are found.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:153` through `156` then kills QEMU if it is still alive.

Impact: the harness can prove that the guest printed `BoT: halt clean`, but it does not require the guest to cause QEMU to exit cleanly. A stuck guest that prints the final marker before hanging can still be converted into GREEN by host cleanup.

### WARNING 3. holyc-inference process pass semantics are stricter than TempleOS harness semantics

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:301` through `304` marks a report `pass` only when every run has `returncode == 0` and `timed_out` is false.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh:35` through `47` accepts success only after the HolyC forward-pass runner emits a token id matching the reference token and the shell pipeline exits successfully.
- TempleOS currently accepts killed QEMU exits (`137`, `143`) in its own north-star harness.

Impact: the same underlying QEMU lifecycle can be green for TempleOS and fail for holyc-inference. Sanhedrin cannot aggregate north-star evidence across the trinity without knowing which pass semantics were used.

### WARNING 4. The accepted cleanup statuses are not reported in the GREEN output

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh:194` through `199` accepts `vm_rc` values `137` and `143`, but the final GREEN line omits `vm_rc`.
- Current iteration logs in TempleOS often record only `bash automation/north-star-e2e.sh` outcome and a short RED/GREEN line, so a future GREEN with `vm_rc=143` could be indistinguishable from `vm_rc=0` in summary evidence.

Impact: retroactive audits lose the ability to distinguish true guest clean halt from host-terminated cleanup unless the raw harness output or stderr is preserved elsewhere.

## Healthy Observations

- The TempleOS North Star harness preserves `-nic none` in its QEMU argument list.
- This audit did not find network enablement, remote services, socket code, DHCP/DNS/TCP/UDP/TLS/HTTP usage, or WS8 networking execution in the inspected north-star path.
- holyc-inference's benchmark report model already records `returncode` and `timed_out` per run, which is the right shape for later trinity-wide evidence normalization.

## Recommended Remediation

- Make TempleOS `automation/north-star-e2e.sh` require `vm_rc == 0` for GREEN, matching `MODERNIZATION/NORTH_STAR.md`.
- If host cleanup must terminate QEMU after the required lines, classify that result separately, for example `YELLOW: serial contract hit but QEMU required host termination`.
- Include `vm_rc`, `found_lines`, and cleanup action in every final harness line so retroactive audits can compare lifecycle outcomes without raw log recovery.
- Align holyc-inference and TempleOS north-star pass semantics around one shared status vocabulary: `pass_clean_exit`, `serial_hit_cleanup_kill`, `timeout`, `guest_fail`, and `host_preflight_fail`.

## Read-Only Commands Used

```text
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh | sed -n '1,120p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '285,312p'
rg -n "137|143|clean halt|QEMU exits|vm_rc|exit status|clean QEMU|kill" audits -S
```

Finding count: 4 warnings, 0 critical findings.
