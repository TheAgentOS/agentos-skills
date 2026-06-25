#!/usr/bin/env bash
# Validate the per-editor install commands published in the README and on the
# AgentOS quickstart dashboard.
#
# For each editor we run its exact command in a fresh, empty project (a brand-
# new directory — the worst case, where the editor's config dir does not yet
# exist) and assert two things:
#   1. The skill lands in the directory THAT editor actually reads.
#   2. Only the stable skill installs — no `status: planned` placeholders leak.
#
# The `--agent` / `-y` flags also mean none of these runs should ever show the
# interactive agent picker; we enforce that with a hard timeout so a hung
# prompt fails the check instead of blocking.
#
# Usage:
#   ./scripts/validate-install-commands.sh
#
# Against a local checkout (e.g. before the repo change is merged):
#   SKILLS_SOURCE=/path/to/agentos-skills ./scripts/validate-install-commands.sh
set -uo pipefail

# Source the installer pulls from. Defaults to the public repo (what users
# actually run); override with a local path to test an unmerged branch.
SOURCE="${SKILLS_SOURCE:-TheAgentOS/agentos-skills}"
EXPECTED_SKILL="agenthog-setup"
PLANNED_SKILLS=(agenthog-add-eval agentrun-deploy agentsec-probe-suite agentbuild-init)
RUN_TIMEOUT="${RUN_TIMEOUT:-120}"

pass=0
fail=0

# Portable timeout: prefer GNU `timeout`/`gtimeout`, else run without one.
run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$RUN_TIMEOUT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$RUN_TIMEOUT" "$@"
  else "$@"; fi
}

# check <name> <expected-skill-dir> <flags...>
# Installs into a fresh temp project and asserts the skill is discoverable at
# <expected-skill-dir>/$EXPECTED_SKILL and no planned skills are present.
check() {
  local name="$1" expected_dir="$2"; shift 2
  local dir; dir="$(mktemp -d)"
  ( cd "$dir" && git init -q . )

  echo "── $name"
  echo "   cmd: npx skills add $SOURCE $* </dev/null"
  # stdin from /dev/null: if the CLI tries to prompt, it gets EOF and aborts
  # rather than hanging — so a missing -y/--agent surfaces as a failure.
  if ! ( cd "$dir" && run_with_timeout npx -y skills add "$SOURCE" "$@" </dev/null ) \
      >"$dir/.out" 2>&1; then
    echo "   ✗ install command failed/timed out"
    sed 's/^/     /' "$dir/.out" | tail -8
    fail=$((fail + 1)); rm -rf "$dir"; return
  fi

  local skill_path="$dir/$expected_dir/$EXPECTED_SKILL"
  if [ ! -e "$skill_path/SKILL.md" ]; then
    echo "   ✗ expected skill not found at $expected_dir/$EXPECTED_SKILL/SKILL.md"
    echo "     (editor would NOT discover the skill)"
    fail=$((fail + 1)); rm -rf "$dir"; return
  fi

  local leaked=""
  for planned in "${PLANNED_SKILLS[@]}"; do
    if find "$dir" -type d -name "$planned" 2>/dev/null | grep -q .; then
      leaked="$leaked $planned"
    fi
  done
  if [ -n "$leaked" ]; then
    echo "   ✗ planned/placeholder skills leaked into install:$leaked"
    fail=$((fail + 1)); rm -rf "$dir"; return
  fi

  echo "   ✓ skill at $expected_dir/$EXPECTED_SKILL, no planned skills leaked"
  pass=$((pass + 1)); rm -rf "$dir"
}

echo "Validating install commands against source: $SOURCE"
echo

# Cursor / Codex / most editors read the shared .agents/skills store.
check "Cursor  ( -y )"                    ".agents/skills"   -y
check "Codex   ( -y )"                    ".agents/skills"   -y
# Claude Code reads its own .claude/skills dir.
check "Claude Code ( --agent claude-code -y )" ".claude/skills" --agent claude-code -y
# Windsurf reads its own .windsurf/skills dir.
check "Windsurf ( --agent windsurf -y )" ".windsurf/skills" --agent windsurf -y

echo
echo "Note: the 'Other / not sure' command is the bare \`npx skills add $SOURCE\`."
echo "      It intentionally shows the interactive picker, so it is not asserted here."
echo
echo "Result: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
