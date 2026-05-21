---
name: agenthog-add-eval
description: Add an evaluator that scores agent outputs and surfaces the score on traces in the AgentHog dashboard. PLANNED — not yet implemented.
status: planned
triggers:
  - add an evaluator
  - score outputs
  - add a quality check
  - add an llm-as-judge
---

# Agenthog add eval — PLANNED

This skill is planned but not yet written. The intended scope:

1. Pick an evaluator template (hallucination, helpfulness, format-correctness,
   custom LLM-as-judge).
2. Wire the eval to run on a sample of incoming traces (e.g. 10%) or on a
   dataset on demand.
3. Surface the eval score as a `agent.eval` event on the trace.
4. Verify the score shows up in the AgentHog Evaluators tab.

Track progress at https://github.com/TheAgentOS/agentos-skills/issues
