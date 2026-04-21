# Repeat-task stuck remediation playbook (Sanhedrin)

Trigger: repeated task IDs (>=3 in 6h) across builder loops.

Findings (online + ops synthesis):
- Use explicit circuit-breakers: after N repeat attempts on same task, force dequeue and quarantine task for manual triage.
- Add retry budgets per task ID (time-windowed), not only per loop iteration; this prevents local infinite retries.
- Use alerting with severity bands: single failures=INFO, repeated failures without progress=WARNING, long consecutive failure streaks=CRITICAL.
- Add runbook-driven escalation with clear owner + ETA for blocked tasks to reduce alert fatigue and no-owner loops.
- Require progress signal checks (new code files, diff entropy, test delta) before allowing same task ID to requeue.

Temple-specific controls to enforce now:
- Keep Law 5 gate as hard input to scheduler (code-file delta required).
- Auto-open research mode when repeat count reaches 3 and no code delta appears within 2 iterations.
- Keep VM/QEMU checks air-gapped (`-nic none`; legacy `-net none`).
