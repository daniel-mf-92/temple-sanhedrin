# Inference repeat-task loop breakers (IQ-980 cluster)

Trigger: `inference` repeated `IQ-980` three consecutive times on 2026-04-21.

Findings:
- GitHub Actions supports rerunning only failed jobs (`gh run rerun <run-id> --failed`) and debug reruns; use this instead of repeating full task loops when failures are isolated.
- GitHub workflow run APIs expose run/log state for automation gating; use failure classification before minting the next IQ task.
- CI doctrine favors fast integration with immediate verification; repeating identical task IDs without new artifact criteria indicates queue/controller drift.
- SRE alerting guidance favors actionable symptom thresholds; apply a local stuck-threshold policy (same task >=3 or no new code artifact over N loops) to force task mutation.

Recommended controller guardrails:
- If same IQ appears 3x, auto-rewrite next IQ with explicit new deliverable + validation command.
- Require new file-level artifact delta (e.g., `.HC`/`tests` change) before allowing task ID reuse.
- On CI fail, rerun only failed jobs first; only then generate a new IQ.
- Add a cooldown lock preventing same IQ ID from immediate requeue.

Sources:
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/rest/actions/workflow-runs
- https://martinfowler.com/articles/continuousIntegration.html
- https://sre.google/workbook/alerting-on-slos/
