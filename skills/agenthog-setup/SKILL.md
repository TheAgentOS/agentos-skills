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

These are resolved at **runtime from the environment** — the SDK reads them
from env vars (see the `init` examples below). Your job is to wire the code to
those env vars, not to obtain or store the secret yourself.

1. **Already in the environment?** (`AGENTOS_API_KEY`, `AGENTOS_WORKSPACE_ID`
   set) — good, nothing to gather. Wire the code to read them and move on.
2. **Not set? The user provides them — you never handle the secret.** Ask the
   user to set the two values in **their own shell**, in the terminal where
   they'll run the app:

   ```bash
   export AGENTOS_API_KEY=<their key>
   export AGENTOS_WORKSPACE_ID=<their workspace id>
   ```

   The quickstart page gives them a ready-to-paste `export` block pre-filled
   with both values. Once exported, re-check the environment and continue — the
   code reads `AGENTOS_API_KEY` / `AGENTOS_WORKSPACE_ID` at runtime. Get values
   from https://app.theagentos.space (API key: Settings → API Keys; workspace
   ID: sidebar chip / top-right).

   **Persistence (optional, Python):** `export` lasts only for that shell
   session. If the user wants it persisted to a gitignored `.env`, they can run
   `agenthog init` (`agenthog >= 0.5.0`) — it prompts for the values, writes
   `.env` (`0600`), and gitignores it. The user runs it and types the key; you
   do not.

**Credential safety (do not deviate):**

- **Never accept the API key pasted into the chat.** If a user offers to paste
  it, decline and tell them to `export` it in their shell (or run `agenthog
  init`) instead — you reference `AGENTOS_API_KEY` by name, never the value.
- **Never search the filesystem or read files hunting for a key.** Don't grep
  `.env`/`.envrc`/config files for secrets. If the value isn't already in the
  environment, ask the user to export it (or run `agenthog init`) — don't go
  looking.
- **Never hardcode the key** in source, and **never print or echo it.** The
  code references `AGENTOS_API_KEY` via the environment, never a literal.
- **The agent never writes the plaintext secret to disk.** `agenthog init`
  (driven by the user typing their key) or the user does that. You may create or
  update `.env.example` with a **placeholder** (Step 6); the real value is never
  yours to handle.

### Endpoint: default silently

`AGENTOS_ENDPOINT` resolves in this order without prompting the user:

1. If `AGENTOS_ENDPOINT` is already set in the environment, use that.
2. Otherwise, use the default: `https://api.theagentos.space`.

**Only prompt the user about the endpoint if** you have *positive evidence*
they want to override it — e.g. they said something like "I'm self-hosting" or
"we run agenthog on our own infra" in their request.

Otherwise: pick the default and move on. Asking for the endpoint on every
quickstart is annoying friction for the 95% who use the hosted cloud.

**Never commit the plaintext API key**, and don't write it to disk yourself —
the user places the real value (Step 6 wires the code + the `.env.example`
placeholder).

## 3. Install the SDK (a new-enough version is mandatory)

> **Minimum supported version: Python `agenthog >= 0.5.0`, TypeScript
> `agenthog >= 0.3.0`.** The ingestion API **rejects events from older SDKs**
> (HTTP 426), and the `log_tool_call` / `log_flag_check` / feature-flag
> resolver APIs need ≥ 0.3.0. The Python floor is 0.5.0 because Step 2 uses the
> `agenthog init` credential command, which shipped in 0.5.0. Below the floor,
> setup won't work.

Install (or upgrade) `agenthog` as part of setup, using the project's existing
package manager — the same one already managing its dependencies. Tell the user
what you're adding, and pin the floor so an existing older install is bumped
rather than left as-is. If you can't determine the package manager, ask before
installing.

### Python

Detect the package manager (`uv`, `poetry`, `pip`, `pipenv`) and install with the
version floor + upgrade:

```bash
# uv  (uv add always resolves to the newest allowed; the floor guarantees ≥0.5.0)
uv add 'agenthog>=0.5.0'

# poetry
poetry add 'agenthog@>=0.5.0'

# pip  (-U upgrades an already-installed older copy)
pip install -U 'agenthog>=0.5.0'
```

For frameworks with first-class auto-instrumentation, install the extras:

```bash
# OpenAI calls
uv add 'agenthog[openai]>=0.5.0'

# Anthropic
uv add 'agenthog[anthropic]>=0.5.0'

# LangChain / LangGraph
uv add 'agenthog[langchain]>=0.5.0'

# OpenTelemetry passthrough
uv add 'agenthog[otel]>=0.5.0'
```

### TypeScript

```bash
# pnpm (preferred)
pnpm add agenthog@latest

# npm
npm install agenthog@latest

# yarn
yarn add agenthog@latest

# bun
bun add agenthog@latest
```

Auto-instrumentation in TS is wired via the integrations import — no extras
required at install time. See `reference/typescript.md`.

### Verify the installed version satisfies the floor (do not skip)

After installing, confirm the version (Python `>= 0.5.0`, TypeScript `>= 0.3.0`).
If it isn't, upgrade and re-check before continuing — the rest of the setup (and
the ingestion API) assumes it.

```bash
# Python — prints the installed version; exits non-zero if below the floor.
python -c "import agenthog, sys; from importlib.metadata import version; \
v=version('agenthog'); print('agenthog', v); \
sys.exit(0 if tuple(map(int, v.split('.')[:2])) >= (0,5) else 1)"

# TypeScript — same idea.
node -e "const v=require('agenthog/package.json').version; const [a,b]=v.split('.').map(Number); \
console.log('agenthog', v); process.exit((a>0||b>=3)?0:1)"
```

If the check reports a version below `0.3.0`, upgrade it the same way you
installed it (the package manager's upgrade for `agenthog`) and re-run the
check. If the floor still can't be met (e.g. the registry hasn't published
`0.3.0` yet), **stop and tell the user** rather than proceeding on an
unsupported version — their telemetry would be rejected at ingest.

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
    # Auto-instrumented LLM calls in here are traced under one task_run_id.
    # Tool calls are NOT auto-traced unless they go through a framework
    # (LangChain/LangGraph) — see Step 5b for hand-written tool loops.
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

## 5b. Instrument tool calls (hand-written agent loops)

`autoinstrument()` patches LLM SDKs (`openai`/`anthropic`/`langchain`) and
LangChain/LangGraph tool nodes — but **not** tool calls you execute yourself in
a raw OpenAI/Anthropic tool-calling loop. Those run untraced, so the trace shows
only LLM steps; evals that look for tool usage then wrongly report "the agent
never used a tool / hallucinated."

If the agent executes tools in its own loop, log each one explicitly so it shows
up as a `tool_call` step:

```python
# Python — inside the loop, where you dispatch the model's tool call:
result = run_tool(name, **args)
agenthog.get_default_client().log_tool_call(name=name, input=args, output=result)
```

```ts
// TypeScript — same idea:
const result = await runTool(name, args);
await getDefaultClient()!.logToolCall({ name, input: args, output: result });
```

`log_tool_call` / `logToolCall` take `name` plus optional `input`, `output`,
`status`, `duration_ms`, `error`. Skip this step only when every tool runs
through an auto-instrumented framework.

## 6. Document the config (placeholders only — never the real key)

Add three **placeholder** lines to `.env.example` (or create it). This file is
committed, so it must never contain a real key:

```
AGENTOS_API_KEY=agops_replace_me
AGENTOS_WORKSPACE_ID=ws_replace_me
AGENTOS_ENDPOINT=https://api.theagentos.space
```

For the **real** values:

- **Python (used `agenthog init` in Step 2):** the gitignored `.env` is already
  written and ignored — nothing more to do here except the committed
  `.env.example` placeholders above (for teammates).
- **Otherwise:** **tell the user to set the real values themselves** — in their
  shell environment, secret manager, or a gitignored `.env`. Do **not** write
  the plaintext key to any file on their behalf. If they use a `.env`, confirm
  it's listed in `.gitignore` (add it if missing) so the secret can't be
  committed.

### Make the `.env` actually load (do not skip)

A `.env` file does **not** populate `os.environ` / `process.env` on its own.
The SDK reads the keys from the environment at runtime (Step 4), so if the app
doesn't load `.env` the user will set everything correctly and still see **no
trace** with an empty/missing key. Wire the load step to match the runtime:

| Runtime | How `.env` reaches the environment |
|---|---|
| **Next.js** | Automatic — Next loads `.env` / `.env.local`. Nothing to add. |
| **Node (non-Next)** | Run with `node --env-file=.env …` (Node 20+), or add `import "dotenv/config";` as the first import. |
| **Python — FastAPI / Flask / script** | Add `from dotenv import load_dotenv; load_dotenv()` **before** `agenthog.init(...)` (add the `python-dotenv` dep), or use `pydantic-settings`, or run via `uv run --env-file .env …`. |
| **Any runtime** | Or just export in the shell before launching: `export AGENTOS_API_KEY=… AGENTOS_WORKSPACE_ID=…`. |

Pick the one matching the project. If you add `load_dotenv()`, place it at the
top of the entrypoint, before `init` runs. Confirm the var is actually populated
(Step 7's "Confirm `AGENTOS_API_KEY` is loaded" check) before declaring done.

## 7. Verify

Run the app. Exercise one request that hits the wrapped handler. Then
verify via **one** of these paths, in order of simplicity:

### Path A — Dashboard (always works)

Open in a browser:

```
https://app.theagentos.space/traces
```

Sign in if needed. A trace from the request you just exercised should
appear within a few seconds. **Use this path by default.**

### Path B — CLI verifier (offline, cryptographic)

The `agenthog` CLI ships as an installed entrypoint, NOT as `python -m
agenthog`. There is no `__main__.py`. Invoke the entrypoint directly:

```bash
# If agenthog[audit] is installed in the active env:
agenthog audit verify --workspace-id $AGENTOS_WORKSPACE_ID

# Or, ephemerally without modifying the project's deps:
uvx --with 'agenthog[audit]' agenthog audit verify --workspace-id $AGENTOS_WORKSPACE_ID

# Or, with uv run from outside any project (mirrors `uv run --no-project`):
uv run --no-project --with 'agenthog[audit]' agenthog audit verify \
    --workspace-id $AGENTOS_WORKSPACE_ID
```

**Do not** run `python -m agenthog audit verify` — that fails with
`'agenthog' is a package and cannot be directly executed`. The CLI is
invoked via the `agenthog` console-script entrypoint, not the module
runner.

Note: `agenthog audit verify` requires the `[audit]` extra (pulls in
`cryptography` for Ed25519 verification). If you only installed
`agenthog[openai]` for tracing, add `[audit]` for verification or use
Path A.

### If no trace appears after 30 seconds

1. Check the app's stdout for `[agenthog.sdk]` warning lines.
2. Confirm `AGENTOS_API_KEY` is loaded (not empty, not the placeholder).
3. Confirm the endpoint is reachable: `curl -I $AGENTOS_ENDPOINT`.
4. Confirm the app actually called `init` before the handler runs
   (sometimes `init` is wired after the handler import — fix the import
   order so `init` runs first at module load).

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
- **Credentials stay in the environment.** The API key is read from an env var
  at runtime. Never hardcode it, never print or echo it, never write the
  plaintext value to a file, and never scan the filesystem for it. Wire the
  code to the env var and let the user place the secret (Step 2).
- **Don't auto-instrument secrets.** If the user has prompts containing PII
  or API keys, mention the privacy controls (`capture_content=False`) in
  the report — don't change the default silently.
- **Don't refactor unrelated code.** Only touch what's necessary to wire
  tracing. If the user wants broader observability work, let them ask
  explicitly.
- **Use uv if it's already in the project.** Otherwise use whatever package
  manager the project already uses. Don't introduce a new one.
