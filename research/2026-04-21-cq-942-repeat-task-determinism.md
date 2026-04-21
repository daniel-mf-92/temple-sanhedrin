# CQ-942 repeat-task determinism notes

Trigger: modernization repeated `CQ-942` for 3 consecutive iterations.

Findings:
- Flaky CI often comes from non-deterministic behavior; recurring reruns hide true progress if not split into smaller deterministic checks.
- Stabilize ranking checks by enforcing explicit total-order tie-break keys (e.g., `(primary_metric, secondary_metric, source_id)`), not implicit iteration order.
- Keep one invariant per assertion block so failures localize quickly; avoid mega-assert blocks that encourage repeated patch churn on one task.
- For repeated failures with low signal, mark flaky edge assertions as quarantine-only and continue advancing adjacent queue items.

Practical guardrails for loop prompt:
- If same task repeats 3x, require branch to alternate to a sibling CQ with shared subsystem and return after one successful commit.
- Require each retry to add exactly one new invariant and one minimal reproducer before touching prior assertions.
- Persist deterministic seed/fixture ordering in smoke harness to keep diffs meaningful.

Sources:
- https://arxiv.org/abs/2602.02307
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.pytest.org/en/stable/reference/reference.html
