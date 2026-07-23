#!/usr/bin/env bash
# Wait until a pull request merges or reaches a definite failure state.
set -euo pipefail

GH_BIN="${GH_BIN:-gh}"
INTERVAL_SECONDS="${ECONOMY_WAIT_PR_INTERVAL_SECONDS:-300}"
TIMEOUT_SECONDS="${ECONOMY_WAIT_PR_TIMEOUT_SECONDS:-0}"
MAIN_REF="${ECONOMY_WAIT_PR_MAIN_REF:-origin/main}"
ONCE=0
PR=""

usage() {
  cat <<'EOF'
Usage: scripts/wait-pr.sh <pr> [options]

Waits for GitHub to report a PR merged, verifies that its head is reachable
from origin/main, fast-forwards a local main worktree, and opportunistically
cleans merged agent worktrees.

Options:
  --interval SECONDS     Poll interval. Default: 300.
  --timeout SECONDS      Overall timeout; 0 means no timeout.
  --once                 Check once and return 2 if still pending.
  --main-ref REF         Ref that must contain the head. Default: origin/main.
  -h, --help             Show this help.

Test fixtures:
  ECONOMY_WAIT_PR_VIEW_JSON
  ECONOMY_WAIT_PR_CHECKS_JSON
  ECONOMY_WAIT_PR_SKIP_FETCH=1
  ECONOMY_WAIT_PR_SKIP_REFRESH=1
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL_SECONDS="${2:?missing --interval value}"; shift ;;
    --timeout) TIMEOUT_SECONDS="${2:?missing --timeout value}"; shift ;;
    --once) ONCE=1 ;;
    --main-ref) MAIN_REF="${2:?missing --main-ref value}"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "wait-pr: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -n "$PR" ]; then
        echo "wait-pr: only one PR is supported" >&2
        exit 2
      fi
      PR="$1"
      ;;
  esac
  shift
done
if [ -z "$PR" ]; then
  echo "wait-pr: missing PR number or URL" >&2
  usage >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
started_at="$(date +%s)"

load_view_json() {
  if [ -n "${ECONOMY_WAIT_PR_VIEW_JSON:-}" ]; then
    printf '%s\n' "$ECONOMY_WAIT_PR_VIEW_JSON"
  else
    "$GH_BIN" pr view "$PR" \
      --json number,url,state,mergedAt,headRefOid,headRefName,mergeStateStatus
  fi
}

load_checks_json() {
  if [ -n "${ECONOMY_WAIT_PR_CHECKS_JSON:-}" ]; then
    printf '%s\n' "$ECONOMY_WAIT_PR_CHECKS_JSON"
  else
    "$GH_BIN" pr checks "$PR" --json name,workflow,state,bucket,link 2>/dev/null \
      || printf '[]\n'
  fi
}

main_worktree_path() {
  local path=""
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) path="${line#worktree }" ;;
      "branch refs/heads/main") printf '%s\n' "$path"; return 0 ;;
    esac
  done < <(git worktree list --porcelain)
  return 1
}

refresh_main() {
  if [ "${ECONOMY_WAIT_PR_SKIP_REFRESH:-0}" = "1" ]; then return 0; fi
  local path
  path="$(main_worktree_path || true)"
  if [ -z "$path" ] || [ ! -d "$path" ]; then
    echo "wait-pr: merged head verified; no local main worktree to refresh" >&2
    return 0
  fi
  git -C "$path" pull --ff-only origin main
  (cd "$path" && scripts/cleanup-worktrees.sh --auto) || {
    echo "wait-pr: main refreshed, but worktree cleanup failed" >&2
  }
}

while true; do
  view_json="$(load_view_json)"
  checks_json="$(load_checks_json)"
  number="$(jq -r '.number // empty' <<<"$view_json")"
  url="$(jq -r '.url // empty' <<<"$view_json")"
  state="$(jq -r '.state // empty' <<<"$view_json")"
  merged_at="$(jq -r '.mergedAt // empty' <<<"$view_json")"
  head_sha="$(jq -r '.headRefOid // empty' <<<"$view_json")"
  head_ref="$(jq -r '.headRefName // empty' <<<"$view_json")"
  merge_state="$(jq -r '.mergeStateStatus // empty' <<<"$view_json")"
  failed_count="$(jq '[.[] | select((.bucket // "" | ascii_downcase) == "fail" or (.bucket // "" | ascii_downcase) == "cancel")] | length' <<<"$checks_json")"
  pending_count="$(jq '[.[] | select((.bucket // "" | ascii_downcase) == "pending")] | length' <<<"$checks_json")"

  if [ "$failed_count" -gt 0 ]; then
    echo "wait-pr: PR #$number has failed or canceled checks: $url" >&2
    jq -r '.[] | select((.bucket // "" | ascii_downcase) == "fail" or (.bucket // "" | ascii_downcase) == "cancel") | "- \(.workflow // "workflow") / \(.name): \(.state // .bucket) \(.link // "")"' <<<"$checks_json" >&2
    exit 1
  fi
  if [ "$state" = "CLOSED" ] && [ -z "$merged_at" ]; then
    echo "wait-pr: PR #$number closed without merge: $url" >&2
    exit 1
  fi
  if [ -n "$merged_at" ] || [ "$state" = "MERGED" ]; then
    if [ -z "$head_sha" ]; then
      echo "wait-pr: merged PR #$number has no head SHA" >&2
      exit 1
    fi
    if [ "${ECONOMY_WAIT_PR_SKIP_FETCH:-0}" != "1" ]; then
      git fetch --quiet origin main
    fi
    if ! git merge-base --is-ancestor "$head_sha" "$MAIN_REF"; then
      echo "wait-pr: merged head $head_sha is not reachable from $MAIN_REF" >&2
      exit 1
    fi
    refresh_main
    echo "wait-pr: PR #$number merged; $head_sha is reachable from $MAIN_REF"
    exit 0
  fi
  if [ "$ONCE" = "1" ]; then
    echo "wait-pr: PR #$number pending (head=$head_ref checks=$pending_count merge=$merge_state): $url" >&2
    exit 2
  fi
  if [ "$TIMEOUT_SECONDS" -gt 0 ]; then
    elapsed=$(( $(date +%s) - started_at ))
    if [ "$elapsed" -ge "$TIMEOUT_SECONDS" ]; then
      echo "wait-pr: timed out after ${elapsed}s: $url" >&2
      exit 1
    fi
  fi
  echo "wait-pr: PR #$number pending; sleeping ${INTERVAL_SECONDS}s"
  sleep "$INTERVAL_SECONDS"
done
