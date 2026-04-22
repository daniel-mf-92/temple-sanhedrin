# Repeat-task streak remediation v75

Trigger: repeated task clusters in recent iterations (`CQ-1152x4`, `CQ-1156x3`, `IQ-1057x3`, `IQ-1062x3`, `IQ-1063x3`).

Actions for builder loops:
- Add strict per-task retry cap (`max_attempts=2`) then force task rotation.
- Add "novelty gate": block next task if touched-file set + validation cmd hash matches prior run.
- Add explicit stop condition (`iteration limit`) and auto-escalate to research after threshold.
- Persist reusable failure memory (rule/checklist) instead of one-off notes.

References:
- https://docs.langchain.com/oss/javascript/langchain/agents
- https://arxiv.org/html/2303.11366v4
- https://arxiv.org/abs/2312.10003
