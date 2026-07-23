#!/usr/bin/env bash
# Install the tracked repository hooks into this checkout.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

git config core.hooksPath hooks
git config branch.main.mergeOptions --no-ff

echo "Installed repository hooks:"
echo "  core.hooksPath=$(git config --get core.hooksPath)"
echo "  branch.main.mergeOptions=$(git config --get branch.main.mergeOptions)"
echo "  pre-commit/pre-merge validation=enabled"
echo "  post-commit/post-merge merged-worktree cleanup=enabled on main"
