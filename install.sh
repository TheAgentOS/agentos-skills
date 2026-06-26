#!/usr/bin/env bash
# AgentOS skills — direct installer.
#
# Pulls the latest agentos-skills repo and drops the installable skill files
# into the current project's agent-config locations. Use this when
# `npx skills add` isn't an option (no Node.js available, restricted
# networks, etc.).
#
# Mirrors the `npx skills add` layout: skills land in the shared
# `.agents/skills/` store (read natively by Cursor, Codex, Gemini CLI,
# Copilot, Amp, Zed, …) plus the editor-specific dirs for Claude Code and
# Windsurf, which read their own locations.
#
# Skills marked `internal: true` in their SKILL.md frontmatter (e.g. planned,
# not-yet-implemented skills) are skipped — same as the npx installer.
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

# Returns 0 if the SKILL.md frontmatter marks the skill internal (hidden from
# install), matching the `metadata.internal: true` flag the npx installer
# honors. Only inspects the frontmatter block (up to the second `---`).
is_internal() {
  awk '
    /^---[[:space:]]*$/ { fence++; if (fence == 2) exit; next }
    fence == 1 && $0 ~ /^[[:space:]]*internal:[[:space:]]*true([[:space:]]|$)/ { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

# Destination stores: the shared universal store plus the two editors that
# read their own directories.
agents_dir="./.agents/skills"
claude_dir="./.claude/skills"
windsurf_dir="./.windsurf/skills"
mkdir -p "$agents_dir" "$claude_dir" "$windsurf_dir"

installed=0
skipped=0
for skill_md in "$src/skills"/*/SKILL.md; do
  [ -e "$skill_md" ] || continue
  skill_dir="$(dirname "$skill_md")"
  name="$(basename "$skill_dir")"

  if is_internal "$skill_md"; then
    echo "    skip ${name} (internal / not yet implemented)"
    skipped=$((skipped + 1))
    continue
  fi

  for dest in "$agents_dir" "$claude_dir" "$windsurf_dir"; do
    rm -rf "${dest:?}/${name}"
    cp -R "$skill_dir" "${dest}/${name}"
  done
  echo "    wrote ${name}"
  installed=$((installed + 1))
done

if [ "$installed" -eq 0 ]; then
  echo "error: no installable skills found in ${REPO}@${REF}" >&2
  exit 1
fi

# AGENTS.md at the project root — the cross-agent entrypoint many tools read.
cp "$src/AGENTS.md" ./AGENTS.md.agentos
echo "    wrote ./AGENTS.md.agentos (merge into AGENTS.md if you have one)"

echo ""
echo "✓ Installed ${installed} skill(s) ($skipped skipped) into .agents/skills, .claude/skills, .windsurf/skills"
echo "  Open your IDE agent and ask, e.g.:"
echo "    Set up AgentHog tracing in my application."
echo ""
echo "See ./AGENTS.md.agentos for the full skill catalog."
