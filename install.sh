#!/usr/bin/env bash
# AgentOS skills — direct installer.
#
# Pulls the latest agentos-skills repo and drops the skill files into the
# current project's agent-config locations. Use this when `npx skills add`
# isn't an option (no Node.js available, restricted networks, etc.).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/TheAgentOS/agentos-skills/main/install.sh | bash
#
# Or pinned to a release:
#   curl -fsSL https://raw.githubusercontent.com/TheAgentOS/agentos-skills/v0.1.0/install.sh | bash
set -euo pipefail

REPO="${AGENTOS_SKILLS_REPO:-TheAgentOS/agentos-skills}"
REF="${AGENTOS_SKILLS_REF:-main}"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${REF}"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "error: tar is required" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "==> downloading ${REPO}@${REF}"
curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir"

# Tarball extracts to <repo>-<ref>/, find that directory.
src="$(find "$tmpdir" -maxdepth 1 -mindepth 1 -type d | head -1)"
if [ -z "$src" ] || [ ! -d "$src/skills" ]; then
  echo "error: unexpected tarball layout under $tmpdir" >&2
  exit 1
fi

echo "==> installing into $(pwd)"

# AGENTS.md at the project root — the cross-agent entrypoint many tools read.
cp "$src/AGENTS.md" ./AGENTS.md.agentos
echo "    wrote ./AGENTS.md.agentos (merge into AGENTS.md if you have one)"

# .claude/agents/ — Claude Code reads SKILL.md files from here too.
mkdir -p ./.claude/skills
cp -R "$src/skills/." ./.claude/skills/
echo "    wrote ./.claude/skills/{agenthog-setup,…}"

# .cursor/rules — Cursor's rules dir mirrors the same content.
mkdir -p ./.cursor/rules
for skill in "$src/skills"/*/SKILL.md; do
  name="$(basename "$(dirname "$skill")")"
  cp "$skill" "./.cursor/rules/${name}.md"
done
echo "    wrote ./.cursor/rules/*.md"

echo ""
echo "✓ Done. Open your IDE agent and ask, e.g.:"
echo "    Set up AgentHog tracing in my application."
echo ""
echo "See ./AGENTS.md.agentos for the full skill catalog."
