# agentos-skills

Agent skills for the **AgentOS** platform. One skill per task, organized by
the four AgentOS surfaces: AgentHog (observability), AgentRun (runtime),
AgentSec (security), and AgentBuild (authoring).

Works with Claude Code, Cursor, Codex, Windsurf, Aider, Continue, and any
agent that reads `AGENTS.md` or the
[open skills spec](https://github.com/vercel-labs/skills).

## Install

```bash
npx skills add TheAgentOS/agentos-skills
```

Drops the skill files into your project's agent-config locations (`.claude/`,
`.cursor/`, `AGENTS.md`, etc.) so whatever IDE agent you're using picks them
up automatically.

Direct install (no npx):

```bash
curl -fsSL https://raw.githubusercontent.com/TheAgentOS/agentos-skills/main/install.sh | bash
```

Windows PowerShell:

```powershell
iwr -useb https://raw.githubusercontent.com/TheAgentOS/agentos-skills/main/install.ps1 | iex
```

## Skill catalog

| Surface | Skill | Status | Triggers |
|---|---|---|---|
| **AgentHog** | [`agenthog-setup`](./skills/agenthog-setup/) | ✅ stable | "set up agenthog", "add tracing", "add observability" |
| **AgentHog** | [`agenthog-add-eval`](./skills/agenthog-add-eval/) | 🚧 planned | "add an evaluator", "score outputs" |
| **AgentRun** | [`agentrun-deploy`](./skills/agentrun-deploy/) | 🚧 planned | "deploy this agent", "run on AgentRun", "schedule this" |
| **AgentSec** | [`agentsec-probe-suite`](./skills/agentsec-probe-suite/) | 🚧 planned | "add probes", "security audit", "red-team this" |
| **AgentBuild** | [`agentbuild-init`](./skills/agentbuild-init/) | 🚧 planned | "scaffold an agent", "create a new agent project" |

Only `agenthog-setup` (✅ stable) is installed by `npx skills add` today. The
🚧 planned skills are on the roadmap and are intentionally hidden from install
(`metadata.internal: true`) until they're implemented — so they won't clutter
your agent or dead-end on a placeholder. Their trigger phrases above are the
*intended* shape; they don't activate yet.

After install, open your IDE agent and ask in plain English. Each skill's
`SKILL.md` lists exact trigger phrases.

## After install

Open your IDE agent (Claude Code, Cursor, etc.) and say what you want. The one
skill available today is `agenthog-setup`:

> Set up AgentHog tracing in my application.

The agent picks up the matching skill and walks you through it. You'll need
your AgentOS credentials ready — get them from https://app.theagentos.space :

- `API_KEY` — Settings → API Keys
- `WORKSPACE_ID` — top-right of the dashboard
- `ENDPOINT` — `https://api.theagentos.space` (override only for self-hosted)

## Repo layout

```
agentos-skills/
├── AGENTS.md                  # cross-agent entrypoint — read first
├── README.md                  # you are here
├── LICENSE                    # MIT
├── install.sh                 # curl-pipe-bash installer
├── install.ps1                # Windows PowerShell installer
├── .claude-plugin/            # Claude Code-specific plugin manifest
├── scripts/                   # helper scripts the skills can invoke
└── skills/
    ├── agenthog-setup/        # ✅ stable
    ├── agenthog-add-eval/     # 🚧 planned
    ├── agentrun-deploy/       # 🚧 planned
    ├── agentsec-probe-suite/  # 🚧 planned
    └── agentbuild-init/       # 🚧 planned
```

Each skill is a self-contained directory: a `SKILL.md` with the
instructions, plus optional `reference/` (deeper SDK docs) and `examples/`
(framework-specific templates).

## Contributing

Open a [discussion](https://github.com/TheAgentOS/agentos-skills/discussions)
to propose a new skill before implementing — that keeps trigger phrases and
file layouts consistent.

To work on an existing skill: each `skills/<name>/SKILL.md` is the source of
truth for what the agent reads. Test changes in a real Claude Code / Cursor
session against a sample project before opening a PR.

## License

MIT. See [LICENSE](./LICENSE).
