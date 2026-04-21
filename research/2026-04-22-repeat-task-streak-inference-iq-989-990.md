# Repeat-task streak remediation (inference IQ-989/IQ-990)

Trigger: inference agent hit repeat-task streaks (>=3) on IQ-989 and IQ-990.

Findings:
- Apply strict WIP limit of 1 active inference task until merge+validation closes; this reduces context switching and unfinished churn.
- Treat repeated same-task retries as toil once no code-path delta appears in consecutive attempts; force a pivot task or root-cause experiment.
- Require small-batch trunk integration (short-lived branch, frequent green merges) so retries are incremental and observable.
- Add streak guard: if same task appears 3x consecutively with pass/no net queue burn-down, auto-insert blocker-analysis task before continuing.
- Track toil ratio for inference loop (repeat/manual/reactive work) and cap to preserve engineering throughput.

Sources:
- https://www.atlassian.com/agile/kanban/wip-limits
- https://sre.google/sre-book/eliminating-toil/
- https://cloud.google.com/blog/products/management-tools/identifying-and-tracking-toil-using-sre-principles
- https://trunkbaseddevelopment.com/
- https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development
