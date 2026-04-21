# Inference repeat-task loop guardrails (IQ-877 streak)

Trigger: inference agent repeated `IQ-877` for 3 consecutive iterations.

Findings:
- Add explicit retry budget per task (`max_retries_per_task=2`) then force task rotation.
- Split failure handling into transient vs deterministic: only rerun failed job subset for transient CI/runtime noise.
- Add anti-flap timer: require a minimum dwell window before re-alerting same stuck condition.
- Track SLO-style loop health metrics: consecutive-fail streak, same-task streak, and time-since-new-code delta.

Source-backed notes:
- GitHub Actions supports rerunning failed jobs and workflows, but reruns are bounded (avoid infinite rerun loops).
- Prometheus alerting recommends `for` / `keep_firing_for` semantics to reduce flapping and noisy state churn.
- Google SRE workbook recommends SLO-driven alerting and actionable signals over noisy alerts.

Action template for loops:
1) If same task repeats >=3 with no material delta, mark WARNING and rotate task.
2) If repeats >=5, mark STUCK and require external research + architecture pivot.
3) If CI failure is transient, rerun failed jobs once; if deterministic, branch to fix task immediately.
