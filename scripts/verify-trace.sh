#!/usr/bin/env bash
# Verify a trace lands in AgentHog for the given workspace.
#
# Usage:
#   AGENTOS_API_KEY=... AGENTOS_WORKSPACE_ID=... ./scripts/verify-trace.sh
#
# Polls /v1/traces?limit=1 every 2s up to 60s. Exits 0 when a trace appears,
# exit 1 on timeout.
set -euo pipefail

: "${AGENTOS_API_KEY:?AGENTOS_API_KEY must be set}"
: "${AGENTOS_WORKSPACE_ID:?AGENTOS_WORKSPACE_ID must be set}"
endpoint="${AGENTOS_ENDPOINT:-https://api.theagentos.space}"

echo "==> polling ${endpoint}/v1/traces for workspace ${AGENTOS_WORKSPACE_ID}"

for i in $(seq 1 30); do
    body="$(curl -fsS -H "Authorization: Bearer ${AGENTOS_API_KEY}" \
        "${endpoint}/v1/traces?limit=1&workspace_id=${AGENTOS_WORKSPACE_ID}" || true)"
    count="$(printf '%s' "$body" | python3 -c '
import json,sys
try:
    d = json.loads(sys.stdin.read())
    print(len(d.get("traces", [])))
except Exception:
    print(0)
' 2>/dev/null || echo 0)"

    if [ "$count" -gt 0 ]; then
        echo "✓ trace received (after $((i*2))s)"
        exit 0
    fi
    printf "  waiting… %ds\n" $((i*2))
    sleep 2
done

echo "✗ no trace received in 60s — check init wiring + AGENTOS_API_KEY" >&2
exit 1
