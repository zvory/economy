#!/usr/bin/env bash
# Run final quality checks, open or update an agent-owned PR, and arm auto-merge.
set -euo pipefail

if [ "${ECONOMY_ADVERSARIAL_QUALITY_PASS:-}" = "1" ]; then
  echo "agent-pr: refusing recursive PR lifecycle call from quality pass" >&2
  exit 2
fi

# Keep the lifecycle driver stable if a quality pass edits this file.
if [ "${ECONOMY_AGENT_PR_STABLE_COPY:-0}" != "1" ]; then
  stable_copy="$(mktemp -t economy-agent-pr.XXXXXX)"
  cp "${BASH_SOURCE[0]}" "$stable_copy"
  chmod +x "$stable_copy"
  ECONOMY_AGENT_PR_STABLE_COPY=1 \
    ECONOMY_AGENT_PR_STABLE_COPY_PATH="$stable_copy" \
    exec bash "$stable_copy" "$@"
fi

STABLE_COPY_PATH="${ECONOMY_AGENT_PR_STABLE_COPY_PATH:-}"
GH_BIN="${GH_BIN:-gh}"
BASE_BRANCH="main"
HEAD_BRANCH=""
TITLE=""
OWNER=""
LIFECYCLE_MODE="normal"
FOCUSED_VERIFICATION=""
BODY_FILE=""
AUTO_MERGE=1
DRY_RUN=0
DRAFT=0
EXTRA_LABELS=()
QUALITY_CONTEXT="adversarial-quality-pass"

usage() {
  cat <<'EOF'
Usage: scripts/agent-pr.sh [options]

Archives a plan newly completed by the branch, runs configured specialist
passes and the adversarial quality pass, pushes the branch, opens or updates
its pull request, writes ownership metadata, and arms auto-merge.

Options:
  --base BRANCH          Base branch. Default: main.
  --head BRANCH          Head branch. Default: current branch.
  --title TITLE          PR title. Default: latest commit subject.
  --owner OWNER          PR owner. Default: GitHub or Git identity.
  --lifecycle MODE       Lifecycle descriptor. Default: normal.
  --verification TEXT    Focused local verification summary.
  --body-file FILE       Markdown appended to the generated PR body.
  --label LABEL          Extra label. Repeatable.
  --draft                Create a new PR as draft.
  --no-auto-merge        Do not arm auto-merge; mark needs-human.
  --dry-run              Print intended actions without GitHub changes.
  -h, --help             Show this help.

Requirements for a live run:
  - A clean agent/* branch.
  - An origin remote with the base branch.
  - git, Node.js, Codex CLI, GitHub CLI, and GitHub authentication.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base) BASE_BRANCH="${2:?missing --base value}"; shift ;;
    --head) HEAD_BRANCH="${2:?missing --head value}"; shift ;;
    --title) TITLE="${2:?missing --title value}"; shift ;;
    --owner) OWNER="${2:?missing --owner value}"; shift ;;
    --lifecycle) LIFECYCLE_MODE="${2:?missing --lifecycle value}"; shift ;;
    --verification) FOCUSED_VERIFICATION="${2:?missing --verification value}"; shift ;;
    --body-file) BODY_FILE="${2:?missing --body-file value}"; shift ;;
    --label) EXTRA_LABELS+=("${2:?missing --label value}"); shift ;;
    --draft) DRAFT=1 ;;
    --no-auto-merge) AUTO_MERGE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "agent-pr: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

quality_report_json="$(mktemp -t economy-quality-json.XXXXXX)"
quality_report_md="$(mktemp -t economy-quality-md.XXXXXX)"
passes_report_md="$(mktemp -t economy-passes-md.XXXXXX)"
pr_body="$(mktemp -t economy-pr-body.XXXXXX)"
cleanup_files=("$quality_report_json" "$quality_report_md" "$passes_report_md" "$pr_body")
cleanup() {
  rm -f "${cleanup_files[@]}"
  if [ -n "$STABLE_COPY_PATH" ]; then rm -f "$STABLE_COPY_PATH"; fi
}
trap cleanup EXIT

CURRENT_BRANCH="$(git branch --show-current)"
if [ -z "$CURRENT_BRANCH" ]; then
  echo "agent-pr: detached HEAD is unsupported" >&2
  exit 2
fi
if [ -z "$HEAD_BRANCH" ]; then HEAD_BRANCH="$CURRENT_BRANCH"; fi
if [ "$HEAD_BRANCH" != "$CURRENT_BRANCH" ]; then
  echo "agent-pr: current branch '$CURRENT_BRANCH' does not match --head '$HEAD_BRANCH'" >&2
  exit 2
fi
case "$HEAD_BRANCH" in
  agent/*) ;;
  *)
    echo "agent-pr: head branch must start with agent/: $HEAD_BRANCH" >&2
    exit 2
    ;;
esac

if [ -z "$TITLE" ]; then TITLE="$(git log -1 --format=%s)"; fi
if [ -z "$OWNER" ] && [ "$DRY_RUN" != "1" ]; then
  OWNER="$("$GH_BIN" api user --jq .login 2>/dev/null || true)"
fi
if [ -z "$OWNER" ]; then OWNER="$(git config user.name || true)"; fi
if [ -z "$OWNER" ]; then OWNER="unknown"; fi
if [ -z "$FOCUSED_VERIFICATION" ]; then FOCUSED_VERIFICATION="Not recorded."; fi

status="$(git status --porcelain=v1)"
if [ -n "$status" ]; then
  echo "agent-pr: clean worktree required:" >&2
  printf '%s\n' "$status" >&2
  exit 1
fi

have_origin=1
if ! git remote get-url origin >/dev/null 2>&1; then have_origin=0; fi
if [ "$have_origin" = "0" ] && [ "$DRY_RUN" != "1" ]; then
  echo "agent-pr: origin remote is not configured" >&2
  exit 1
fi

if [ "$DRY_RUN" = "1" ] && [ "$have_origin" = "0" ]; then
  echo "agent-pr: would fetch origin/$BASE_BRANCH and archive newly completed plans"
  echo "agent-pr: would run configured passes and adversarial quality pass"
else
  git fetch origin "+refs/heads/$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH"
  node scripts/archive-completed-plans.mjs --base "origin/$BASE_BRANCH" --commit
  pass_args=(
    --base "origin/$BASE_BRANCH"
    --head-branch "$HEAD_BRANCH"
    --markdown-report-file "$passes_report_md"
    --repo "$repo_root"
  )
  if [ "$DRY_RUN" = "1" ]; then pass_args+=(--dry-run); fi
  node scripts/agent-pr-passes.mjs "${pass_args[@]}"

  changed_files=()
  while IFS= read -r file; do
    [ -n "$file" ] && changed_files+=("$file")
  done < <(git diff --name-only --no-renames "origin/$BASE_BRANCH...HEAD")

  docs_only=0
  if [ "${#changed_files[@]}" -gt 0 ]; then
    docs_only=1
    for file in "${changed_files[@]}"; do
      case "$file" in
        *.md) ;;
        *) docs_only=0; break ;;
      esac
    done
  fi

  if [ "$DRY_RUN" = "1" ]; then
    if [ "$docs_only" = "1" ]; then
      echo "agent-pr: would skip adversarial review for Markdown-only diff"
    else
      scripts/adversarial-quality-pass.mjs \
        --base "origin/$BASE_BRANCH" \
        --head-branch "$HEAD_BRANCH" \
        --report-file "$quality_report_json" \
        --markdown-report-file "$quality_report_md" \
        --gh-bin "$GH_BIN" \
        --dry-run
    fi
  elif [ "$docs_only" = "1" ]; then
    cat >"$quality_report_md" <<'EOF'
## Adversarial quality pass

Verdict: skipped_docs_only

The autonomous code-quality pass was skipped because every changed file is Markdown.
EOF
    git push -u origin "HEAD:refs/heads/$HEAD_BRANCH"
    final_head="$(git rev-parse HEAD)"
    "$GH_BIN" api -X POST "repos/:owner/:repo/statuses/$final_head" \
      -f state=success \
      -f "context=$QUALITY_CONTEXT" \
      -f "description=skipped for Markdown-only changes"
  else
    scripts/adversarial-quality-pass.mjs \
      --base "origin/$BASE_BRANCH" \
      --head-branch "$HEAD_BRANCH" \
      --report-file "$quality_report_json" \
      --markdown-report-file "$quality_report_md" \
      --gh-bin "$GH_BIN" \
      --push \
      --post-status
  fi
fi

needs_human="false"
auto_merge_text="requested"
if [ "$AUTO_MERGE" = "0" ]; then
  needs_human="true"
  auto_merge_text="disabled-needs-human"
fi

{
  cat <<EOF
<!-- economy-agent-pr:v1 -->
Agent-Owner: $OWNER
Lifecycle-Mode: $LIFECYCLE_MODE
Agent-Owned: true
Auto-Merge: $auto_merge_text
Focused-Verification: $FOCUSED_VERIFICATION
Needs-Human: $needs_human
<!-- /economy-agent-pr -->

EOF
  if [ -s "$quality_report_md" ]; then cat "$quality_report_md"; printf '\n'; fi
  if [ -s "$passes_report_md" ]; then cat "$passes_report_md"; printf '\n'; fi
  if [ -n "$BODY_FILE" ]; then cat "$BODY_FILE"; printf '\n'; fi
} >"$pr_body"

if [ "$DRY_RUN" = "1" ]; then
  echo "agent-pr: would ensure agent-owned/automerge/needs-human labels"
  echo "agent-pr: would push $HEAD_BRANCH and open or update PR to $BASE_BRANCH"
  if [ "$AUTO_MERGE" = "1" ]; then echo "agent-pr: would arm auto-merge"; fi
  echo "agent-pr: dry run complete for $HEAD_BRANCH -> $BASE_BRANCH"
  exit 0
fi

ensure_label() {
  "$GH_BIN" label create "$1" --color "$2" --description "$3" >/dev/null 2>&1 || true
}
ensure_label "agent-owned" "0E8A16" "Owned by an automated agent with lifecycle metadata"
ensure_label "automerge" "5319E7" "Auto-merge should run after required checks pass"
ensure_label "ci-failed" "D73A4A" "CI failed and needs investigation"
ensure_label "needs-human" "FBCA04" "Human review or a decision is required"

existing_number="$("$GH_BIN" pr list \
  --base "$BASE_BRANCH" \
  --head "$HEAD_BRANCH" \
  --state open \
  --json number \
  --jq '.[0].number // empty')"

labels=(--add-label agent-owned)
if [ "$AUTO_MERGE" = "1" ]; then labels+=(--add-label automerge)
else labels+=(--add-label needs-human); fi
for label in "${EXTRA_LABELS[@]}"; do labels+=(--add-label "$label"); done

if [ -n "$existing_number" ]; then
  "$GH_BIN" pr edit "$existing_number" --title "$TITLE" --body-file "$pr_body" "${labels[@]}"
  pr_number="$existing_number"
  pr_url="$("$GH_BIN" pr view "$pr_number" --json url --jq .url)"
else
  create_args=(pr create --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$TITLE" --body-file "$pr_body")
  for label in "${labels[@]}"; do create_args+=("$label"); done
  if [ "$DRAFT" = "1" ]; then create_args+=(--draft); fi
  pr_url="$("$GH_BIN" "${create_args[@]}")"
  pr_number="${pr_url##*/}"
fi

if [ "$AUTO_MERGE" = "1" ]; then
  "$GH_BIN" pr merge "$pr_number" --auto --merge
fi
echo "agent-pr: PR $pr_number ready: $pr_url"
