# Loop stuck-pattern mitigation (CQ-1191/IQ repeats)

- Trigger: repeated task IDs in recent history (`modernization:CQ-1191x5`, several 3x repeats), despite high pass rate.
- Source-backed pattern: move from pass/fail-only to eval-driven gates with explicit regression graders and automated review loops (OpenAI cookbook).
- CI control pattern: enforce GitHub Actions `concurrency` groups per branch/task family to prevent overlapping runs from masking real progression.
- Reliability pattern: classify alerts by actionability and user-impact symptom first; repeated non-actionable failures should be demoted and deduplicated.
- Test-signal pattern: treat flaky/non-deterministic checks as quarantined side lane with owner + SLA, not as primary merge signal.

## Suggested enforcement for builders
- Add `stuck_score` to loop state: +1 for same task_id repeat without net new code surface; reset on materially new code path.
- Auto-switch mode at score >=3: force “alternative approach” prompt template + narrower acceptance criteria.
- At score >=5: mandatory research pull + one implementation variance branch before retrying same task.

## References
- OpenAI cookbook: autonomous eval/retraining loop and LLM-as-judge workflow.
- GitHub docs: workflow/job concurrency controls.
- Google SRE incident/alerting guidance: alerts must be actionable and symptom-oriented.
- ACM survey on flaky tests: non-deterministic tests degrade trust and velocity.
