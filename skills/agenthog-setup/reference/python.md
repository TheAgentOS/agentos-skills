# AgentHog Python SDK — reference

Companion reference for the `agenthog-setup` skill. Canonical source:
https://github.com/TheAgentOS/agentos-python

## Install

```bash
pip install agenthog
# or, with extras:
pip install 'agenthog[openai]'         # OpenAI auto-instrumentation
pip install 'agenthog[anthropic]'      # Anthropic auto-instrumentation
pip install 'agenthog[langchain]'      # LangChain / LangGraph auto-instrumentation
pip install 'agenthog[otel]'           # OpenTelemetry passthrough
pip install 'agenthog[audit]'          # Offline audit ledger verifier CLI
pip install 'agenthog[all]'            # Everything
```

Requires Python 3.10+.

## `agenthog.init(...)`

Construct and register the global default client. Call once at app startup.

```python
agenthog.init(
    api_key: str | None = None,        # AGENTOS_API_KEY env var if None
    *,
    endpoint: str | None = None,       # AGENTOS_ENDPOINT or https://api.theagentos.space
    environment: str | None = None,    # AGENTOS_ENV (e.g. "prod", "staging")
    capture_content: bool | None = None,  # default True; set False to redact prompt/response bodies
    flush_interval_ms: int | None = None, # default 250
    flush_batch_size: int | None = None,  # default 100
    buffer_max_size: int | None = None,   # default 10_000
    disable: bool | None = None,       # AGENTOS_DISABLE; true silences all calls
    agent_id: str | None = None,       # AGENTOS_AGENT_ID; descriptive label per service
    workspace_id: str | None = None,   # AGENTOS_WORKSPACE_ID
    kind: str = "sync",                # "sync" or "async" — async returns AsyncClient
)
```

Re-calling `init` replaces the default; shut down the previous client first
if you need clean state.

## Tracing primitives

### `start_task_run` — context manager

Wrap one end-to-end execution. Each call = one `task_run_id`.

```python
with agenthog.start_task_run(
    agent_id: str | None = None,        # override the global default for this run
    task_run_id: str | None = None,     # provide your own ID; auto-generated otherwise
    trace_id: str | None = None,        # W3C trace context inbound
    user_id: str | None = None,         # attribute the run to a specific user
    session_id: str | None = None,      # group runs into a conversation
) as ctx:
    # ctx.task_run_id, ctx.trace_id, ctx.span_id available
    ...
```

Note: there is no `metadata=` kwarg. Attach identifiers via the explicit
kwargs above (`user_id`, `session_id`, `agent_id`, etc.).

### `start_span` — nest spans inside a task run

```python
with agenthog.start_span(name="retrieve_docs", attributes={"k": 5}) as span:
    docs = retrieve(query)
    span.set_attribute("doc_count", len(docs))
```

## Auto-instrumentation

```python
agenthog.autoinstrument(
    only=None,    # list[str] of specific integrations to install
    skip=None,    # list[str] of integrations to skip
    client=None,  # pin to a non-default client (rare)
)
# Returns the list of installed integration names.
```

Detects installed packages and patches in: `openai`, `anthropic`,
`langchain` (and `langgraph` via langchain-core).

## Manual logging

When auto-instrumentation isn't possible (custom LLM client, tool calls
outside any framework), emit events directly:

```python
client = agenthog.get_default_client()

client.log_business_event(name="checkout_completed", revenue=49.99)
client.log_flag_check(flag="new-prompt-v2", variant="treatment", evaluated_as=True)
client.log_eval(name="hallucination_score", score=0.12)
```

## Failure-mode contract

The SDK guarantees no public method raises. Errors are routed to the internal
`agenthog.sdk` logger (Python's `logging` module, namespace
`agenthog.sdk.{transport,ingest,init,...}`).

To surface SDK errors during local dev:

```python
import logging
logging.getLogger("agenthog.sdk").setLevel(logging.DEBUG)
```

## Shutdown

```python
agenthog.shutdown()  # blocking flush, called at app teardown
```

Or per-client: `client.shutdown()`. The sync client also flushes on
`atexit` automatically.

## Environment variables

See [`env-vars.md`](./env-vars.md) for the full list.

## Privacy controls

```python
agenthog.init(..., capture_content=False)
```

When `capture_content=False`, the SDK records call metadata (latency, token
counts, model name) but redacts prompt/response bodies. Use this for
projects under PII / HIPAA constraints.

## Versioning

SemVer with 0.x policy: minor bumps may break; patch bumps are safe. The 0.1.4
release added deprecation aliases for the `project_id → workspace_id` rename;
the aliases are scheduled for removal in 0.2.0.

See https://github.com/TheAgentOS/agentos-python/blob/main/CHANGELOG.md
