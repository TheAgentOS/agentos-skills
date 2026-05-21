# AgentOS skills — entrypoint for AI coding agents

This file is the canonical entrypoint for any AI coding agent (Claude Code,
Cursor, Codex, Windsurf, Aider, Continue, …) working in a project that has
the `agentos-skills` package installed.

When the user asks for something AgentOS-related, find the matching skill
below, then open its `SKILL.md` for the full instructions.

## Skills by surface

AgentOS has four product surfaces. Skills are namespaced by surface so the
right one loads only when relevant.

### AgentHog — observability

For instrumenting LLM apps with tracing, evals, datasets, and dashboards.

| Skill | Trigger phrases | File |
|---|---|---|
| `agenthog-setup` | "set up agenthog", "add agenthog tracing", "instrument with agenthog", "add observability", "wire up tracing" | [`skills/agenthog-setup/SKILL.md`](./skills/agenthog-setup/SKILL.md) |
| `agenthog-add-eval` | "add an evaluator", "score outputs", "add a quality check" | [`skills/agenthog-add-eval/SKILL.md`](./skills/agenthog-add-eval/SKILL.md) (planned) |

### AgentRun — runtime + deployment

For deploying agents to the AgentOS runtime (Docker isolation, scheduled +
event-triggered process models, syscall mediator, kill switches).

| Skill | Trigger phrases | File |
|---|---|---|
| `agentrun-deploy` | "deploy this agent", "run on agentrun", "schedule this", "trigger this on a webhook" | [`skills/agentrun-deploy/SKILL.md`](./skills/agentrun-deploy/SKILL.md) (planned) |

### AgentSec — security + probes

For pre-prod red-team probing, inline injection detection, output PII /
secrets filtering, and policy-driven kill switches.

| Skill | Trigger phrases | File |
|---|---|---|
| `agentsec-probe-suite` | "add probes", "security audit this agent", "red-team this", "add OWASP LLM probes" | [`skills/agentsec-probe-suite/SKILL.md`](./skills/agentsec-probe-suite/SKILL.md) (planned) |

### AgentBuild — agent authoring

For scaffolding new agent projects with the AgentOS contract baked in.

| Skill | Trigger phrases | File |
|---|---|---|
| `agentbuild-init` | "scaffold an agent", "create a new agent project", "start a new agentos project" | [`skills/agentbuild-init/SKILL.md`](./skills/agentbuild-init/SKILL.md) (planned) |

## Universal conventions

When invoking *any* of these skills:

1. **Never commit secrets.** Add API keys to `.env.example` with placeholder
   values, real keys to `.env` (and confirm `.env` is gitignored).
2. **Honor the SDK / SDK-equivalent never-raise invariant.** AgentOS
   libraries don't throw from public methods; your wiring should match —
   wrap integration code defensively so a misconfigured AgentOS surface
   degrades gracefully rather than crashing the user's agent.
3. **Verify before declaring done.** Each skill has a verification step
   (run the thing, exercise one request, confirm a trace / probe result /
   deploy is visible in the dashboard). Don't skip it.
4. **Ask before installing dependencies.** Confirm the package manager
   (pip / uv / poetry / npm / pnpm / yarn / bun) before running install
   commands.
5. **Don't refactor unrelated code.** Touch only what's necessary for the
   requested skill. If the user wants broader changes, let them ask
   explicitly.

## Configuration shared across surfaces

All four surfaces use the same auth + tenancy model. These env vars work
everywhere:

| Var | Purpose |
|---|---|
| `AGENTOS_API_KEY` | Workspace API key. Same key works across Hog, Run, Sec, Build. |
| `AGENTOS_WORKSPACE_ID` | Workspace UUID (the tenant). |
| `AGENTOS_ENDPOINT` | Control-plane URL. Default `https://api.theagentos.space`. |

The user gets these from https://app.theagentos.space → top-right
"Workspace ID" / Settings → API Keys.
