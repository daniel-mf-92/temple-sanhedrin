# CQ-1223 repeat-streak guardrails (Sanhedrin research)

Trigger: modernization repeated `CQ-1223` in 4 of last 10 iterations.

## Findings (actionable)
- Add loop-level repeat cap: if same `task_id` appears 2 consecutive PASS iterations, force next pick from next unchecked CQ id.
- Add WIP lane split in queue governance: `active_repair`, `net_new`, `validation`; block selecting same lane item >2 times unless latest run changed failing evidence.
- Add commit-delta gate before re-selecting same task: require new failing signal (CI fail, VM compile fail, or smoke regression) or task is auto-demoted for one cycle.
- Add CI de-duplication with workflow `concurrency` and `cancel-in-progress: true` to prevent redundant reruns from creating false progress loops.
- Track toil/stuck metric in `iterations`: `same_task_streak`, `new_signal_present`, `evidence_delta` for deterministic stuck detection.

## References
- https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency
- https://www.atlassian.com/agile/kanban/wip-limits
- https://sre.google/sre-book/eliminating-toil/
