# Pull-request-first delivery workflow

This workflow applies after the repository has an `origin` GitHub remote, a protected default
branch, and required checks configured. Before that setup exists, work on local task branches and
do not claim remote delivery.

## Normal delivery

1. Start from current `origin/main` in a clean task-specific worktree.
2. Create an `agent/<short-task-name>` branch.
3. Implement the requested scope and run focused verification.
4. Commit only task files and leave the worktree clean.
5. Run `scripts/agent-pr.sh --verification "<checks that passed>"`.
6. Run `scripts/wait-pr.sh <PR number or URL>`.
7. Report completion only after the waiter confirms that the PR head is reachable from
   `origin/main`.

The PR helper first archives any multi-phase plan completed by the branch. It then runs specialist
passes configured in `scripts/agent-pr-passes.json`, followed by the autonomous adversarial quality
pass. The pass may improve and commit the branch before the helper pushes the final head, posts the
`adversarial-quality-pass` commit status, creates or updates the PR, adds ownership labels, and arms
auto-merge.

Markdown-only branches skip the autonomous code review but still receive a successful
`adversarial-quality-pass` status explaining the skip. This prevents documentation changes from
spending an autonomous review run while preserving a consistent required-status contract.

## Specialist passes

`scripts/agent-pr-passes.json` is intentionally empty at project creation. Add a pass only when the
project establishes a repeatable concern that should run before final review—for example release
notes, schema generation, asset manifests, or migration validation.

Each configured command receives:

- `--base <ref>`
- `--head-branch <branch>`
- `--markdown-report-file <path>`
- `--repo <path>`
- `--dry-run` when the lifecycle is being previewed

A mutating pass must commit its work and leave the same branch clean. Its Markdown report is
included in the PR body.

## Final adversarial quality pass

`scripts/adversarial-quality-pass.mjs` launches a fresh ephemeral Codex review against the complete
branch diff. The reviewer can fix and commit correctness, security, lifecycle, verification,
architecture, or documentation problems without expanding product scope.

The outer PR helper owns all pushing and GitHub operations. The quality-pass environment prevents a
reviewer from recursively invoking the PR lifecycle.

## Failure and recovery

- If a focused check fails, repair locally and rerun it before calling the PR helper.
- If a specialist or adversarial pass fails, inspect its output, repair the branch, commit, and
  rerun `scripts/agent-pr.sh`.
- If GitHub checks fail, leave the PR open, investigate the exact failing check, repair the same
  branch, and rerun the helper.
- If auto-merge cannot be armed, use `--no-auto-merge` and report the human decision required.
- If the PR closes without merging or the merged head is not reachable from `origin/main`, the
  waiter fails. Do not report the task complete.

## Required local tools

- Git
- Node.js
- Codex CLI authenticated for autonomous review
- GitHub CLI (`gh`) authenticated for the repository
- `jq` for GitHub response parsing

Run `scripts/install-hooks.sh` once per clone. Run `scripts/verify-workflows.sh` to validate this
workflow scaffold without contacting GitHub or invoking Codex.
