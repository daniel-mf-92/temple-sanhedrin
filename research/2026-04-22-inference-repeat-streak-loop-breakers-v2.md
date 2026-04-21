# Inference repeat-task streak loop breakers

Trigger: inference task ID streak observed (`IQ-990` repeated 4 consecutive passes in recent iterations).

## Practical interventions (for loop controller prompts)

1. Add explicit **streak guard**: if same `task_id` appears 3 times consecutively, force task reselection from top-N unblocked queue items.
2. Add **failure-memory reflection** block to prompt (short: what changed since last run, why previous attempt wasn't enough).
3. Use **reason+act traces** with observable checkpoints (must emit one concrete code delta target before editing).
4. Maintain a small **skill/method cache** (successful patterns) and require selecting either "reuse pattern" or "explore new pattern" each run.
5. Enforce **novelty score** gate before commit (reject pure rewording/doc-only output when code target exists).

## Evidence from literature

- Reflexion: episodic verbal feedback improves subsequent trial decisions by learning from prior mistakes.
- ReAct: interleaving reasoning and actions improves exception handling and reduces ungrounded repetition.
- Voyager: automatic curriculum + growing skill library helps avoid narrow local loops and drives broader progress.

## Suggested metrics to monitor

- Max consecutive same-task streak (target <=2)
- Distinct task IDs per 10 iterations
- Code-touch ratio (`.HC/.sh/.py` vs docs-only)
- Retry-without-novel-diff count

Sources: arXiv 2303.11366 (Reflexion), arXiv 2210.03629 (ReAct), arXiv 2305.16291 (Voyager)
