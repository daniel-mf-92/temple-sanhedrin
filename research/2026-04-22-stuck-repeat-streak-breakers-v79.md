# Stuck streak remediation (CQ-1198 x3)

Trigger: modernization repeated `CQ-1198` for 3 consecutive iterations on 2026-04-22.

Findings:
- Keep QEMU air-gap assertion explicit: require `-nic none` evidence in wrapper output and fail if missing (QEMU invocation docs).
- Prevent redundant CI loop churn: use GitHub Actions concurrency groups (`cancel-in-progress: true`) so newer pushes cancel stale in-progress runs.
- For matrix jobs, set explicit `strategy.fail-fast` policy per workflow intent; default `true` can hide later signal when first shard fails.
- Preserve strict shell failure semantics in wrappers (`set -e` and pipeline failure handling) to reduce false pass/retry loops.

Sources:
- https://www.qemu.org/docs/master/system/invocation.html
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://www.gnu.org/software/bash/manual/html_node/Pipelines.html
