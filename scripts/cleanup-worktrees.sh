#!/usr/bin/env bash
# Remove clean, merged agent worktrees from the repository's dedicated temp root.
set -euo pipefail

WORKTREE_ROOT="${ECONOMY_WORKTREE_ROOT:-/tmp/economy-worktrees}"
MODE="manual"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/cleanup-worktrees.sh [--auto] [--dry-run]

Removes clean agent/* worktrees located directly beneath the configured
worktree root when their heads are reachable from main or origin/main.

Options:
  --auto       Run only when the current checkout is on main.
  --dry-run    Print removable worktrees without changing them.
  -h, --help   Show this help.

Environment:
  ECONOMY_WORKTREE_ROOT=/tmp/economy-worktrees
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --auto) MODE="auto" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "cleanup-worktrees: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
current_branch="$(git branch --show-current)"
if [ "$MODE" = "auto" ] && [ "$current_branch" != "main" ]; then exit 0; fi
if ! git show-ref --verify --quiet refs/heads/main; then
  echo "cleanup-worktrees: local main is missing; skipping" >&2
  exit 0
fi

is_managed_path() {
  local candidate="$1"
  case "$candidate" in
    "$WORKTREE_ROOT"/*) return 0 ;;
    /private"$WORKTREE_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_merged() {
  local head="$1"
  git merge-base --is-ancestor "$head" main 2>/dev/null && return 0
  git rev-parse --verify origin/main >/dev/null 2>&1 \
    && git merge-base --is-ancestor "$head" origin/main 2>/dev/null
}

worktree_path=""
while IFS= read -r line; do
  case "$line" in
    "worktree "*) worktree_path="${line#worktree }" ;;
    "")
      if [ -z "$worktree_path" ] || [ ! -d "$worktree_path" ] || ! is_managed_path "$worktree_path"; then
        worktree_path=""
        continue
      fi
      branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
      case "$branch" in agent/*) ;; *) worktree_path=""; continue ;; esac
      if [ -n "$(git -C "$worktree_path" status --porcelain=v1 2>/dev/null)" ]; then
        worktree_path=""
        continue
      fi
      head="$(git -C "$worktree_path" rev-parse HEAD)"
      if is_merged "$head"; then
        if [ "$DRY_RUN" = "1" ]; then
          echo "cleanup-worktrees: would remove $worktree_path ($branch)"
        else
          echo "cleanup-worktrees: removing $worktree_path ($branch)"
          git worktree remove "$worktree_path"
          git branch -d "$branch" >/dev/null 2>&1 || true
        fi
      fi
      worktree_path=""
      ;;
  esac
done < <(git worktree list --porcelain; printf '\n')
