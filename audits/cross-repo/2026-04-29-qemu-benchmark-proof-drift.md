# Cross-Repo QEMU Benchmark Proof Drift Audit

- Audit timestamp: `2026-04-29T09:46:24+02:00`
- Audit owner: `gpt-5.5 sibling`
- Scope: cross-repo invariant check, historical/deep audit only
- TempleOS worktree observed: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
- holyc-inference worktree observed: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`
- Repos treated as read-only: yes
- QEMU/VM commands executed: none

## Question

Does holyc-inference QEMU benchmark evidence prove the same guest safety invariants that TempleOS now expects from its QEMU command manifest, especially air-gap, serial capture, timeout bounds, and immutable image handling?

## Finding Count

- Critical: 1
- Warning: 3
- Info: 1
- Total: 5

## Findings

### CRITICAL-001: Inference QEMU benchmark drives omit `readonly=on`

Law 10 says QEMU launch commands for the OS image must include `-drive readonly=on`. The current holyc-inference benchmark command builder adds:

```text
-drive file=<image>,format=raw,if=ide
```

without `readonly=on`. The committed/latest benchmark artifacts also do not contain `readonly=on`.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py` `build_command(...)` constructs `-drive` as `file={image},format=raw,if=ide`.
- `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/qemu_prompt_bench_latest.json` records benchmark commands with `-drive file=bench/fixtures/airgap-smoke.img,format=raw,if=ide`.
- `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/qemu_prompt_bench_dry_run_latest.json` records `-drive file=/tmp/TempleOS.synthetic.img,format=raw,if=ide`.

Impact:
- The inference benchmark lane can pass its local air-gap checks while still failing the immutable-image invariant TempleOS enforces for guest launches.
- This is cross-repo drift because the inference runner exercises a TempleOS-style guest image but does not encode TempleOS's read-only image policy in its command contract.

Recommended closure:
- Add `readonly=on` to holyc-inference QEMU benchmark drive construction, or explicitly classify synthetic non-OS fixture images separately and gate real TempleOS image paths on `readonly=on`.

### WARNING-002: holyc-inference air-gap audit is narrower than TempleOS QEMU manifest policy

TempleOS `qemu-command-manifest.py` tracks `-nic none`, legacy `-net none`, serial evidence, serial capture evidence, headless evidence, concrete timeout budgets, timeout budget failures, and smoke-launcher missing-evidence counts. holyc-inference `airgap_audit.py` only evaluates recorded benchmark commands for explicit `-nic none` and forbidden network devices/backends.

Evidence:
- TempleOS report fields include `serial_capture_evidence_lines`, `concrete_timeout_budget_lines`, `smoke_missing_serial_capture_count`, `smoke_timeout_budget_ok_count`, and `max_timeout_budget_allowed_sec`.
- holyc-inference `bench/airgap_audit.py` `command_violations(...)` checks `-nic none`, rejects `-net`, `-netdev`, and network devices, but does not check immutable drive mode, serial capture, timeout budget, headless mode, or teardown evidence.
- holyc-inference `bench_result_index.py` reduces this to `command_airgap_status` only.

Impact:
- A benchmark artifact can be `command_airgap_status=pass` while missing proof surfaces that TempleOS treats as mandatory for QEMU launcher evidence.

Recommended closure:
- Split `command_airgap_status` into a multi-field QEMU safety contract, at minimum: `network_status`, `image_readonly_status`, `serial_capture_status`, `headless_status`, and `timeout_budget_status`.

### WARNING-003: Trend dashboards report pass status without preserving command proof

The current holyc-inference benchmark trend export reports `latest_airgap_status=pass` for seven latest trend rows, but the latest dashboard rows do not preserve the command string, command hash, read-only image status, or per-command safety evidence.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboards/bench_trend_export_latest.json` has `status: pass` and `findings: []`.
- The same report's latest rows expose `latest_airgap_status`, but not command text, `latest_command_sha256`, or any `readonly` field.
- The top-level `trend_points` value is an integer count (`89`), not a row array carrying command-level provenance.

Impact:
- Historical trend consumers can see "airgap pass" without being able to reproduce or inspect the command proof that produced the pass.
- This weakens retroactive auditability compared with TempleOS host reports, which keep explicit command-manifest metrics.

Recommended closure:
- Include `latest_command_sha256`, `latest_command_airgap_findings`, `latest_image_readonly_status`, and source artifact references in `latest` and `windows` trend rows.

### WARNING-004: Synthetic fixture commands are treated as QEMU-like but not labelled as synthetic

holyc-inference current dry-run and measured benchmark artifacts use `bench/fixtures/qemu_synthetic_bench.py` as the executable while retaining QEMU-like options such as `-nic none`, `-serial stdio`, `-display none`, and `-drive ...`. The air-gap audit intentionally treats any command with `-drive` as QEMU-like, so synthetic and real QEMU launches share the same pass/fail field.

Evidence:
- `bench/airgap_audit.py` `qemu_like(...)` returns true if the command executable contains `qemu-system` or any argument starts with `-drive`.
- Latest holyc-inference benchmark artifacts include synthetic fixture commands with `-drive`.
- Trend rows do not distinguish synthetic fixture proof from real QEMU proof.

Impact:
- Dashboard readers may interpret synthetic fixture pass status as equivalent to real QEMU launch proof.
- This is not a direct LAWS.md violation, but it blurs the evidence boundary for cross-repo release gates.

Recommended closure:
- Add an explicit `launcher_kind` field such as `real_qemu`, `synthetic_qemu_fixture`, or `non_qemu`, and prevent synthetic rows from satisfying real guest-launch gates.

### INFO-005: Network air-gap direction is mostly aligned

holyc-inference `qemu_prompt_bench.py` does default to `-nic none`, `-serial stdio`, and `-display none`, and `reject_network_args(...)` rejects non-`none` NIC/net settings plus known virtual NIC devices. The current gap is not network enablement; it is incomplete proof parity with TempleOS's broader QEMU safety policy.

## Static Verification

Read-only commands and inspections used:

```bash
python3 - <<'PY'
import json, pathlib
for name in ["qemu_prompt_bench_latest.json", "qemu_prompt_bench_dry_run_latest.json"]:
    p = pathlib.Path("/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results") / name
    text = p.read_text()
    print(name, "readonly=on" in text, "-nic" in text and "none" in text)
PY

python3 - <<'PY'
import json, pathlib
p = pathlib.Path("/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/dashboards/bench_trend_export_latest.json")
d = json.loads(p.read_text())
print(d["status"], d["findings"], type(d["trend_points"]).__name__, d["trend_points"])
for row in d["latest"]:
    print(row["latest_source"], row["latest_airgap_status"], "latest_command_sha256" in row, "readonly" in json.dumps(row).lower())
PY

rg -n "command_airgap|airgap|nic none|net none|serial|timeout|readonly" \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/bench_result_index.py \
  /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/airgap_audit.py \
  /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-command-manifest.py
```

No QEMU, VM, networking, or trinity source-modifying command was executed.
