# Repeat-task streak guardrails v17 (2026-04-21)

Trigger: recent window shows repeated tasks (modernization: CQ-914 x6; inference: IQ-839/IQ-842/IQ-844/IQ-861 x3).

External findings (quick):
- Atlassian CFD guidance: track widening in-progress bands to detect flow bottlenecks early.
- Google SRE practices: use objective reliability gates and toil reduction to prevent repeated unproductive loops.
- GitHub Actions docs + recent flaky-build literature: distinguish flaky rerunnable failures from deterministic compile failures; treat retries as signal, not resolution.

Applied guardrails for Temple loops:
- If same task repeats >=3, force decomposition into a smaller subtask with a new task ID and explicit done-check.
- If same task repeats >=5 with no net code delta, quarantine task and enqueue alternate slice in same subsystem.
- Tag loop outcomes as {deterministic-fail, flaky-fail, infra-fail, pass}; only deterministic-fail contributes to stuck severity.
- Require one measurable acceptance probe per task (grep/test/harness) to prevent “PASS without progress”.
