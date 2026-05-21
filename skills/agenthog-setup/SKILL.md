---
name: agenthog-setup
description: Install the AgentHog SDK and wire tracing into the project — init at startup, wrap the primary agent loop, add env vars, verify a first trace lands.
triggers:
  - set up agenthog
  - add agenthog tracing
  - instrument with agenthog
  - add observability
  - wire up tracing
  - add tracing to this app
---

# Agenthog setup

You (the AI coding agent reading this skill) are being asked to install and
configure AgentHog tracing in the user's project. Follow this skill end-to-end.
Do NOT skip the verification step.

## 1. Detect the runtime

Look at the project root to determine the language and primary framework:

- **Python** if you see `pyproject.toml`, `requirements.txt`, `setup.py`, or `*.py` files.
- **TypeScript / Node** if you see `package.json` with `"type": "module"` or
  TypeScript files, or `tsconfig.json`.

If both, default to whichever the primary entrypoint uses. Ask the user if
genuinely ambiguous.

Identify the primary framework: FastAPI, Flask, Django, LangGraph, LangChain,
Express, Vercel AI SDK, Next.js, Hono, etc. The framework determines where
`init` belongs and where the per-request loop is.

## 2. Gather configuration

Two values are required from the user. The endpoint is auto-defaulted — do
**NOT** ask the user about it unless one of the override conditions below
fires.

### Required: `AGENTOS_API_KEY` and `AGENTOS_WORKSPACE_ID`

Check, in order:

1. **Environment** — `AGENTOS_API_KEY`, `AGENTOS_WORKSPACE_ID`.
2. **A user-provided file** like `.env`, `.env.local`, `.envrc`.
3. **Ask the user** if neither is found. Direct them to
   https://app.theagentos.space :
   - `AGENTOS_API_KEY` — Settings → API Keys → "New default credential"
   - `AGENTOS_WORKSPACE_ID` — bottom-left of the sidebar (click the chip to
     copy), or top-right of the dashboard

### Endpoint: default silently

`AGENTOS_ENDPOINT` resolves in this order without prompting the user:

1. If `AGENTOS_ENDPOINT` is already set in env or `.env`, use that.
2. Otherwise, use the default: `https://api.theagentos.space`.

**Only prompt the user about the endpoint if** you have *positive evidence*
they want to override it, such as:
- They typed something like "I'm self-hosting" or "we run agenthog on our
  own infra" in their request.
- A previous `.env` file already had a non-default `AGENTOS_ENDPOINT` set.

Otherwise: pick the default and move on. Asking for the endpoint on every
quickstart is annoying friction for the 95% who use the hosted cloud.

**Never commit the plaintext API key.** Always write it to `.env` (gitignored)
and add a placeholder line to `.env.example`.

## 3. Install the SDK

### Python

Detect the package manager (`uv`, `poetry`, `pip`, `pipenv`):

```bash
# uv
uv add agenthog

# poetry
poetry add agenthog

# pip
pip install agenthog
```

For frameworks with first-class auto-instrumentation, install the extras:

```bash
# OpenAI calls
uv add 'agenthog[openai]'

# Anthropic
uv add 'agenthog[anthropic]'

# LangChain / LangGraph
uv add 'agenthog[langchain]'

# OpenTelemetry passthrough
uv add 'agenthog[otel]'
```

### TypeScript

```bash
# pnpm (preferred)
pnpm add agenthog

# npm
npm install agenthog

# yarn
yarn add agenthog

# bun
bun add agenthog
```

Auto-instrumentation in TS is wired via the integrations import — no extras
required at install time. See `reference/typescript.md`.

## 4. Wire `init` at app startup

The `init` call must run **once**, before any LLM/tool call you want traced.
Place it in the app's primary entrypoint:

| Framework | Where to call init |
|---|---|
| FastAPI | `main.py`, before `app = FastAPI()` |
| Flask | `app.py`, before `app = Flask(__name__)` |
| Django | `settings.py` bottom, or an `apps.py` `ready()` hook |
| LangGraph script | top of the script, before graph construction |
| Express | `index.ts`/`server.ts`, before `app.listen` |
| Next.js | `instrumentation.ts` (Next.js's official OTel/tracing hook) |
| Vercel AI SDK | wherever the AI client is constructed |

### Python init pattern

```python
import os
import agenthog

agenthog.init(
    api_key=os.environ["AGENTOS_API_KEY"],
    endpoint=os.environ.get("AGENTOS_ENDPOINT", "https://api.theagentos.space"),
    workspace_id=os.environ["AGENTOS_WORKSPACE_ID"],
    agent_id="<descriptive-agent-name>",  # pick based on what this service is
)

# Optional: auto-instrument supported LLM / framework libraries.
# Detects installed packages (openai, anthropic, langchain) and patches them.
agenthog.autoinstrument()
```

### TypeScript init pattern

```ts
import { init } from "agenthog";

init({
  apiKey: process.env.AGENTOS_API_KEY!,
  endpoint: process.env.AGENTOS_ENDPOINT ?? "https://api.theagentos.space",
  workspaceId: process.env.AGENTOS_WORKSPACE_ID!,
  agentId: "<descriptive-agent-name>",
});

// Auto-instrumentation is per-integration in TS. Import the wrapper for the
// LLM client you use. Examples:
//   import "agenthog/integrations/openai";
//   import "agenthog/integrations/anthropic";
//   import "agenthog/integrations/vercelAI";
//   import "agenthog/integrations/langchain";
```

Pick a `agentId` that describes what the service does, not just the repo
name. Examples: `customer-support-bot`, `code-review-agent`, `etl-pipeline`.

## 5. Wrap the primary agent loop in `start_task_run`

One `task_run` = one end-to-end execution of the agent (one user message → one
final response, or one cron trigger → one job complete). Spans nest inside it.

### Python — context manager

```python
with agenthog.start_task_run(user_id=user_id) as ctx:
    # all LLM calls + tool calls in here are traced under one task_run_id
    result = my_agent.run(user_input)
    return result
```

Available kwargs: `agent_id`, `task_run_id`, `trace_id`, `user_id`,
`session_id`. There is **no** `metadata=` kwarg — attach attribution via
the explicit kwargs above instead.

For an HTTP handler (FastAPI/Flask), wrap the handler body:

```python
@app.post("/chat")
async def chat(req: ChatRequest):
    with agenthog.start_task_run(user_id=req.user_id):
        return await my_agent.run(req.message)
```

### TypeScript — callback

```ts
import { startTaskRun } from "agenthog";

app.post("/chat", async (req, res) => {
  await startTaskRun({ userId: req.body.userId }, async () => {
    const out = await myAgent.run(req.body.message);
    res.json(out);
  });
});
```

Available `StartTaskRunArgs` fields: `agentId`, `taskRunId`, `traceId`,
`userId`, `sessionId`. No `metadata` field.

If the user's framework has a middleware concept (Express, Hono, FastAPI
middleware), prefer wiring `start_task_run` as a middleware so every request
gets a task_run automatically.

## 6. Update `.env` and `.env.example`

Add three lines to `.env.example` (or create it):

```
AGENTOS_API_KEY=agops_replace_me
AGENTOS_WORKSPACE_ID=ws_replace_me
AGENTOS_ENDPOINT=https://api.theagentos.space
```

Add the real values to `.env`. Confirm `.env` is in `.gitignore` (it usually is).

## 7. Verify

Run the app. Exercise one request that hits the wrapped handler. Then:

```bash
# CLI verifier
agenthog audit verify --workspace-id $AGENTOS_WORKSPACE_ID
```

Or visit `https://app.theagentos.space/traces` in a browser — your trace
should appear within a few seconds.

If no trace appears after 30 seconds:

1. Check the app's stdout for `[agenthog.sdk]` warning lines.
2. Confirm `AGENTOS_API_KEY` is loaded (not empty, not the placeholder).
3. Confirm the endpoint is reachable: `curl -I $AGENTOS_ENDPOINT`.
4. Confirm the app actually called `init` before the request hit (sometimes
   `init` is wired after the handler — fix the import order).

## 8. Report back

Once a trace is verified visible, tell the user:

- What you installed (which extras)
- Where you put the `init` call (file + line)
- Where you wrapped the loop (file + line)
- The trace_id of your verification trace (so they can open it directly)

## Rules

- **Never throw.** The user's agent must keep running even if AgentHog is
  misconfigured. The SDK guarantees its own calls don't raise; your wiring
  should match that contract.
- **Don't auto-instrument secrets.** If the user has prompts containing PII
  or API keys, mention the privacy controls (`capture_content=False`) in
  the report — don't change the default silently.
- **Don't refactor unrelated code.** Only touch what's necessary to wire
  tracing. If the user wants broader observability work, let them ask
  explicitly.
- **Use uv if it's already in the project.** Otherwise use whatever package
  manager the project already uses. Don't introduce a new one.
