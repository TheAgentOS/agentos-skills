---
name: agentbuild-init
description: Scaffold a new agent project with the AgentOS contract baked in — tracing, runtime, security primitives wired from line one. PLANNED — not yet implemented.
status: planned
metadata:
  internal: true  # hide from `npx skills add` until implemented
triggers:
  - scaffold an agent
  - create a new agent project
  - start a new agentos project
  - new agent from template
---

# AgentBuild init — PLANNED

This skill is planned but not yet written. The intended scope:

1. Pick a template (Python + FastAPI, Python + LangGraph, TypeScript +
   Vercel AI SDK, TypeScript + Hono, multi-agent / supervisor pattern).
2. Generate the project structure with AgentHog tracing pre-wired, AgentSec
   probe stubs in CI, AgentRun deploy descriptor at the root.
3. Drop a starter prompt + tool set so the agent can be run end-to-end
   immediately.
4. Verify by running the local dev server and confirming a first trace lands
   in AgentHog.

Track progress at https://github.com/TheAgentOS/agentos-skills/issues
