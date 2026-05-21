---
name: agentsec-probe-suite
description: Add the AgentSec probe library (200+ adversarial probes — injection, PII exfil, refusal evasion, destructive-tool-intent) to CI for pre-prod red-teaming. PLANNED — not yet implemented.
status: planned
triggers:
  - add probes
  - security audit this agent
  - red-team this
  - add owasp llm probes
  - add adversarial tests
---

# AgentSec probe suite — PLANNED

This skill is planned but not yet written. The intended scope:

1. Pick a probe pack (`owasp-llm-top10`, `pii-exfil`, `destructive-tool-intent`,
   `refusal-evasion`, or `all`).
2. Wire `agentsec probe` as a CI job (GitHub Actions / GitLab CI / circle.yml).
3. Configure the agent under test — endpoint, auth, sample inputs.
4. Set a pass threshold (default: ≥95% probe pass rate on the reference
   suite, matching the AgentOS v1 success metric).
5. Surface probe failures as CI annotations + AgentHog `security.alert` events.

Track progress at https://github.com/TheAgentOS/agentos-skills/issues
