#!/usr/bin/env bash
# Validate predictable ownership metadata on agent/* pull requests.
set -euo pipefail

HEAD_REF="${GITHUB_HEAD_REF:-}"
BODY_FILE=""
BODY_TEXT="${ECONOMY_PR_BODY:-}"

usage() {
  cat <<'EOF'
Usage: scripts/check-pr-ownership.sh [options]

For agent/* pull requests, validates the metadata block written by
scripts/agent-pr.sh. Other branch names pass without ownership checks.

Options:
  --head-ref BRANCH      PR head branch. Default: GITHUB_HEAD_REF.
  --body-file FILE       File containing the PR body.
  -h, --help             Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --head-ref) HEAD_REF="${2:?missing --head-ref value}"; shift ;;
    --body-file) BODY_FILE="${2:?missing --body-file value}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "check-pr-ownership: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$BODY_TEXT" ] && [ -n "$BODY_FILE" ]; then
  BODY_TEXT="$(<"$BODY_FILE")"
elif [ -z "$BODY_TEXT" ] && [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
  BODY_TEXT="$(jq -r '.pull_request.body // ""' "$GITHUB_EVENT_PATH")"
fi
if [ -z "$HEAD_REF" ]; then
  echo "check-pr-ownership: missing PR head ref" >&2
  exit 2
fi
case "$HEAD_REF" in
  agent/*) ;;
  *) echo "check-pr-ownership: non-agent branch $HEAD_REF; skipping"; exit 0 ;;
esac

missing=0
require_match() {
  local description="$1"
  local pattern="$2"
  if ! [[ "$BODY_TEXT" =~ $pattern ]]; then
    echo "check-pr-ownership: missing $description" >&2
    missing=1
  fi
}

require_match "metadata marker" '<!-- economy-agent-pr:v1 -->'
require_match "Agent-Owner" $'(^|\n)Agent-Owner:[[:space:]]*[^[:space:]]'
require_match "Lifecycle-Mode" $'(^|\n)Lifecycle-Mode:[[:space:]]*[^[:space:]]'
require_match "Agent-Owned true" $'(^|\n)Agent-Owned:[[:space:]]*true[[:space:]]*(\n|$)'
require_match "Auto-Merge" $'(^|\n)Auto-Merge:[[:space:]]*(requested|armed|disabled-needs-human)[[:space:]]*(\n|$)'
require_match "Focused-Verification" $'(^|\n)Focused-Verification:[[:space:]]*[^[:space:]]'
require_match "Needs-Human" $'(^|\n)Needs-Human:[[:space:]]*(true|false)[[:space:]]*(\n|$)'
require_match "metadata end marker" '<!-- /economy-agent-pr -->'

if [ "$missing" = "1" ]; then
  echo "check-pr-ownership: agent/* PRs must use scripts/agent-pr.sh metadata" >&2
  exit 1
fi
echo "check-pr-ownership: ownership metadata present for $HEAD_REF"
