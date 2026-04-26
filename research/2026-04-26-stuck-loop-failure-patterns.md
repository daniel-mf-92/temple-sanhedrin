# Stuck-loop failure patterns (2026-04-26)

Trigger:
- modernization max same-task streak: 4
- inference max same-task streak: 3

Findings:
- Use bounded retries with jitter and explicit retry budgets for transient errors.
- Promote symptom alerts into cause-labeled events so operators can separate infrastructure noise from deterministic code regressions.
- Enforce small, queueable task slices plus fail-forward reassignment when a task repeats without net file-level progress.
- Add automatic "streak breaker" policy: when same task repeats 3+ times, force one of: scope split, alternative test harness, or dependency unblocking task.

Actions proposed for loop prompts:
- Add explicit `same_task_streak>=3` branch requiring a different implementation path in next iteration.
- Require one measurable progress delta (new code path + test evidence) before allowing another attempt on same task.
- Keep API/network/timeouts tagged as infra-info, not law violations.

Sources consulted:
- https://sre.google/workbook/table-of-contents/
- https://aws.amazon.com (retry/backoff guidance)
