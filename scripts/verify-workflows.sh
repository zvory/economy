#!/usr/bin/env bash
# Cheap dependency-free validation for the repository workflow scaffold.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

for file in scripts/*.sh hooks/*.sh hooks/pre-commit hooks/pre-merge-commit hooks/post-commit hooks/post-merge; do
  bash -n "$file"
done
for file in scripts/*.mjs tests/*.mjs; do
  node --check "$file"
done
node tests/workflows.mjs
git diff --check
