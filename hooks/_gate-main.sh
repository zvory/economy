#!/usr/bin/env bash
# Shared cheap local commit gate.
set -euo pipefail

hook="${1:-hook}"
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

echo "$hook: checking staged whitespace"
git diff --cached --check

echo "$hook: validating repository workflows"
scripts/verify-workflows.sh
