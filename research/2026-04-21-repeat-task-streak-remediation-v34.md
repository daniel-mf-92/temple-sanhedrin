# Repeat-task streak remediation (v34)

Trigger: recent80 shows repeated task IDs (`inference: IQ-920 x3`, `modernization: CQ-965 x3`).

External guidance synthesized:
- Use retry backoff with jitter (not fixed retries) to avoid synchronized re-attempt storms in agent loops.
- Use workflow/job concurrency groups so duplicate runs collapse to one active execution path.
- Use dual-threshold alerting: INFO for isolated failures; WARNING only when repeated streak + no file-progress signal.
- Gate retries by progress evidence: require changed code surface or task-id advancement before re-running same task.

Actionable policy update for loops:
1) Max same-task repeats per rolling 20 iterations: 2 (third repeat triggers forced task diversification).
2) Add randomized cooldown (jittered) before repeat execution.
3) Auto-open a new queue item when repeat threshold trips, referencing failed/stalled task ID.

References: AWS Architecture Blog (Exponential Backoff and Jitter), GitHub Actions Concurrency docs, Google SRE Workbook (Alerting on SLOs).
