---
name: agentrun-deploy
description: Deploy an agent to AgentRun — Docker-isolated runtime with scheduled (cron) or event-triggered (webhook) process models, syscall mediator, kill switches. PLANNED — not yet implemented.
status: planned
metadata:
  internal: true  # hide from `npx skills add` until implemented
triggers:
  - deploy this agent
  - run on agentrun
  - schedule this
  - trigger this on a webhook
  - put this on a cron
---

# AgentRun deploy — PLANNED

This skill is planned but not yet written. The intended scope:

1. Detect the agent's entrypoint (`agent.py`, `index.ts`, or user-specified).
2. Generate an `agentrun.yaml` deploy descriptor with:
   - Runtime image (matching the language/framework)
   - Trigger model (cron / webhook / manual)
   - Resource limits (CPU, memory, timeout)
   - Syscall policy (allowed tools, network egress rules)
3. Run `agentrun deploy` (or equivalent control-plane API call) and surface
   the deploy URL + first run trace.
4. Verify the first triggered run completes and emits a `process_exit` event.

Track progress at https://github.com/TheAgentOS/agentos-skills/issues
