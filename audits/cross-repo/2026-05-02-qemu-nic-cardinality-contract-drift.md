# Cross-Repo Audit: QEMU NIC Cardinality Contract Drift

Timestamp: 2026-05-02T09:25:31+02:00

Scope: cross-repo invariant check across current TempleOS and holyc-inference heads. TempleOS and holyc-inference were read-only. No live liveness watching, process restart, QEMU/VM command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, remote fetch, or trinity source edit was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `d214a4396df64ee606dc869dc4fc0ed5a4d54966` on `codex/templeos-gpt55-testharness`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `a70776642a09de7ed01eb75aaaebbdd3243f84c2` on `codex/holyc-gpt55-bench`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `f7bfa0acfff27a5761a54f3c8439b600f6360a2e`

Audit angle: cross-repo invariant check. Does the TempleOS QEMU launch safety contract match holyc-inference's benchmark artifact assumption that an air-gapped QEMU command has exactly one explicit disabled NIC?

Findings: 4 warning findings

## Summary

holyc-inference now treats `-nic none` as a cardinality contract: each saved top-level, warmup, and measured QEMU benchmark command must include exactly one explicit disabled NIC. TempleOS still treats the air-gap as a presence/absence contract: `-nic none` or `-net none` must appear and forbidden network backends must not appear. A duplicate `-nic none -nic none` command passes TempleOS's guard and strict manifest gate, but fails holyc-inference's artifact audit. This is not a guest networking breach, but it is a cross-repo proof-shape drift around Law 2 evidence.

## Findings

### WARNING-001: TempleOS air-gap guard accepts duplicate disabled NIC declarations

Evidence:
- `TempleOS/automation/qemu-airgap-lib.sh:128-154` implements `qemu_airgap_has_disabled_network_arg` as a boolean search that returns at the first `-nic none`, `-net none`, `-nic=none`, or `-net=none`.
- `TempleOS/automation/qemu-airgap-lib.sh:156-168` makes `qemu_airgap_require_disabled_network` require only no forbidden network args plus the boolean disabled-network predicate.
- Host-only proof: `qemu_airgap_require_disabled_network 'duplicate nic proof' -m 512M -nic none -nic none -serial stdio` returned `0`.

Impact: TempleOS considers duplicate disabled NIC declarations compliant. That is currently air-gap safe, but it allows ambiguous launch evidence that the inference side now rejects as non-canonical.

Recommended issue: add an exact-cardinality helper such as `qemu_airgap_disabled_nic_count` and require exactly one `-nic none` for modern QEMU launchers, while keeping `-net none` as an explicit legacy fallback path with separate evidence.

### WARNING-002: TempleOS strict command manifest does not gate duplicate `-nic none`

Evidence:
- `TempleOS/automation/qemu-command-manifest.py:452-454` records `has_no_network`, `has_nic_none`, and `has_net_none` as per-line booleans.
- `TempleOS/automation/qemu-command-manifest.py:478-486` increments evidence counters once per logical line; it does not count occurrences inside the command.
- `TempleOS/automation/qemu-command-manifest.py:681-733` builds strict gate failures for forbidden network options, missing no-network evidence, legacy-preferred fallback, headless, serial, timeout, daemonize, bounded command, and teardown checks, but has no duplicate-NIC cardinality failure.
- Host-only fixture proof: a synthetic smoke script containing `timeout 30 qemu-system-x86_64 ... -nic none -nic none ...` produced `manifest_exit_code 0`, `gate_failed False`, and empty `gate_failures`.

Impact: TempleOS's strict QEMU launcher evidence can be green even when it emits a command shape that holyc-inference's benchmark artifact audit marks invalid. Cross-repo acceptance should not have one repo normalize evidence that the other repo refuses.

Recommended issue: extend `qemu-command-manifest.py` to parse command tokens for disabled-NIC cardinality and add `smoke_duplicate_nic_none_count` / strict gate failure rows.

### WARNING-003: holyc-inference enforces exact `-nic none` cardinality in benchmark artifacts

Evidence:
- `holyc-inference/bench/qemu_nic_cardinality_audit.py:2-8` documents the invariant: every saved top-level, warmup, and measured command must include exactly one explicit `-nic none` disablement and no networking violations.
- `holyc-inference/bench/qemu_nic_cardinality_audit.py:128-140` counts `-nic none` and `-nic=none` occurrences.
- `holyc-inference/bench/qemu_nic_cardinality_audit.py:186-197` records an error unless `nic_count == 1`.
- `holyc-inference/tests/test_qemu_nic_cardinality_audit.py:64-83` covers missing, duplicate, networked, and non-QEMU command failures. The local host-only test file passed.

Impact: the inference side has a stronger, more canonical air-gap proof than TempleOS's launch-side guard. That is good for benchmark artifacts, but it exposes drift because TempleOS can still generate launch evidence that later fails inference-side replay/audit.

Recommended issue: promote the exact-one disabled-NIC contract into a shared Trinity QEMU launch invariant and reference it from both TempleOS host automation and holyc-inference benchmark docs.

### WARNING-004: holyc-inference argument-fragment policy forbids duplicate disabled NICs, but TempleOS has no matching fragment policy

Evidence:
- `holyc-inference/bench/qemu_args_policy_audit.py:149-157` counts `-nic none` in reusable QEMU argument fragments.
- `holyc-inference/bench/qemu_args_policy_audit.py:194-206` emits a finding when a fragment contains more than one explicit `-nic none`.
- `holyc-inference/tests/test_qemu_args_policy_audit.py:29-60` includes `duplicate_nic.args` and asserts `"duplicate -nic none"` is a finding.
- TempleOS `qemu-command-manifest.py` tracks `files_with_nic_none_count` and `legacy_net_none_only_lines` at `TempleOS/automation/qemu-command-manifest.py:765-798`, but has no equivalent duplicate-fragment or duplicate-command metric.

Impact: holyc-inference prevents both benchmark artifacts and reusable argument fragments from accumulating duplicate disabled-NIC declarations. TempleOS still lacks the same normalization layer, so a TempleOS launcher can pass locally while producing non-canonical inputs for inference benchmark policy.

Recommended issue: either add a TempleOS QEMU args-fragment audit or make `qemu-command-manifest.py` consume final argv fixtures where the same exact-one disabled-NIC rule is enforceable.

## Law Mapping

- Law 2: no guest networking was added or executed in this audit. The drift is evidence shape, not a discovered active air-gap breach.
- Law 5 / North Star Discipline: benchmark and modernization evidence should share the same acceptance semantics so a green TempleOS launch proof cannot become a red holyc-inference artifact proof.

## Validation

Commands run were host-only source or fixture checks:
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-airgap-lib.sh | sed -n '1,240p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-command-manifest.py | sed -n '1,900p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_nic_cardinality_audit.py | sed -n '1,280p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_args_policy_audit.py | sed -n '1,260p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/tests/test_qemu_nic_cardinality_audit.py | sed -n '1,180p'`
- `source automation/qemu-airgap-lib.sh; qemu_airgap_require_disabled_network 'duplicate nic proof' -m 512M -nic none -nic none -serial stdio`
- Synthetic TempleOS manifest fixture with duplicate `-nic none` run through `python3 -B automation/qemu-command-manifest.py --strict`; no QEMU process was launched.
- `python3 -B tests/test_qemu_nic_cardinality_audit.py`

No QEMU/VM command was executed.
