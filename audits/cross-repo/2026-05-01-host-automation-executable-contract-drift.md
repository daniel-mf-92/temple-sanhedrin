# Cross-Repo Audit: Host Automation Executable Contract Drift

Audit timestamp: 2026-05-01T04:50:51+02:00
Audit angle: cross-repo invariant check
Repos reviewed read-only:
- `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55`
- `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55`

No trinity source code was modified. No QEMU or VM command was executed. No live liveness watching was performed.

## Invariant

Host-side automation that other agents or CI may invoke directly should have an auditable executable/shebang contract. This is not a HolyC purity exception escape hatch: host tooling may be Python or shell, but the handoff surface still needs deterministic invocation metadata so validation commands are reproducible and do not silently depend on local chmod state.

This invariant supports LAWS.md Law 5 North Star Discipline and Law 7 Blocker Escalation. A missing executable/shebang gate does not directly violate HolyC purity or the air-gap by itself, but it can turn otherwise valid host-only smoke gates into machine-local behavior and repeated `permission denied` / interpreter drift failures.

## Evidence

- TempleOS now has `automation/host-shell-executable-contract.py`, which scans `automation/*.sh`, records executable-bit and exact `#!/usr/bin/env bash` shebang status, emits JSON/Markdown, and returns non-zero in `--strict` mode on findings.
- TempleOS has `automation/host-shell-executable-contract-smoke.sh`, which builds synthetic fixtures for a good script, a non-executable script, and a wrong-shebang script, then verifies both normal and strict-mode behavior.
- TempleOS Makefile exposes `host-shell-executable-contract` at lines 678-681.
- TempleOS latest report `MODERNIZATION/lint-reports/host-shell-executable-contract-latest.md` records 1,288 shell scripts, 1,288 executable scripts, 1,288 bash shebangs, 0 missing executable-bit findings, 0 missing shebang findings, and `gate_failed=false`.
- holyc-inference has 1,765 tracked Python files and 6 tracked shell scripts; all 6 shell scripts are executable.
- holyc-inference has 88 tracked `bench/*_ci_smoke.py` files, but their modes are mixed: 11 are tracked as `100755` and 77 are tracked as `100644`.
- holyc-inference has 40 tracked executable Python files overall.
- A repository search found 0 holyc-inference matches for `executable contract`, `shebang contract`, `missing executable`, `missing shebang`, or `host-shell-executable`.
- holyc-inference has no generated executable/shebang contract artifact under `bench/results/` or `bench/dashboards/`.
- holyc-inference GitHub Actions currently runs only `python3 bench/perf_ci_smoke.py` for the bench perf workflow; it does not run a broad executable/shebang contract gate.

## Findings

### WARNING-001: holyc-inference has no equivalent executable/shebang contract for host automation

TempleOS has promoted direct host-shell invocation metadata into a first-class report and strict gate. holyc-inference has many host-side smoke and audit entrypoints, but no comparable inventory or generated artifact proving which files are expected to be invoked directly versus through `python3`.

Impact: future agents can add a smoke script or Python entrypoint that works on their local filesystem but fails in CI or another worktree due to missing executable bits, missing shebangs, or inconsistent invocation style. That creates Law 5 validation noise and can feed Law 7 repeated-blocker churn.

Suggested remediation: add a host automation contract in holyc-inference that records shell scripts, executable Python entrypoints, shebangs, and expected invocation mode, with a strict CI smoke path that never launches QEMU or touches the guest.

### WARNING-002: `bench/*_ci_smoke.py` has mixed executable-bit semantics

The tracked CI smoke population is split between 11 executable files and 77 non-executable files. Both modes can be valid, but the repo does not encode which smoke files are intentionally direct entrypoints and which must be invoked as `python3 path`.

Impact: dashboard or task generators can infer the wrong execution mode from the filename alone. The risk is especially high because the suffix `*_ci_smoke.py` reads like a uniform class, while the mode bits prove the class is not uniform.

Suggested remediation: either normalize CI smoke Python files to non-executable plus `python3` invocation, or require executable smoke entrypoints to have a Python shebang and document/report that role explicitly.

### WARNING-003: current CI does not exercise the full bench smoke surface

The visible GitHub workflow for bench performance runs `python3 bench/perf_ci_smoke.py` only. It does not discover all `bench/*_ci_smoke.py` files or run a contract check over their modes/shebangs.

Impact: a smoke helper can drift stale or non-runnable while the workflow remains green. This is not a live liveness finding; it is a historical cross-repo gate-coverage gap compared with TempleOS' growing host-report inventory.

Suggested remediation: add a low-cost contract job that enumerates expected smoke files and validates invocation metadata. Keep it host-only and offline.

## Non-Findings

- Law 1 HolyC purity: no core TempleOS or inference runtime source change is implicated by this audit; all evidence is host-side automation.
- Law 2 air-gap sanctity: no QEMU or VM command was executed, and the suggested remediation is host-only/offline.
- Law 10 immutable OS image: no launch command was executed or modified.
- Law 11 local access only: no Book of Truth read/export path was inspected as a live operation or changed.

## Commands Used

```sh
nl -ba automation/host-shell-executable-contract.py | sed -n '1,260p'
nl -ba automation/host-shell-executable-contract-smoke.sh | sed -n '1,220p'
nl -ba MODERNIZATION/lint-reports/host-shell-executable-contract-latest.md | sed -n '1,180p'
nl -ba Makefile | sed -n '670,690p'
git ls-files -s '*.sh' 'bench/*.py' 'tests/*.py' '.github/workflows/*' | head -n 120
git ls-files -s 'bench/*_ci_smoke.py' | awk '{mode[$1]++} END{for (m in mode) print m, mode[m]}' | sort
rg -n "executable contract|shebang contract|missing executable|missing shebang|host-shell-executable" -g '*.py' -g '*.md' -g '*.yml' -g '*.yaml' .
find . -maxdepth 3 -type f \( -path './bench/results/*' -o -path './bench/dashboards/*' \) \( -name '*executable*' -o -name '*shebang*' -o -name '*contract*' \) -print
```

## Verdict

Record 3 warning findings. TempleOS has a concrete executable/shebang contract for host shell automation; holyc-inference has a larger and more mixed host automation surface without an equivalent invariant report or CI gate.
