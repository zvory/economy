# Repository guidance

This repository contains **Minister of the Economy**, a new game project.

The project is at its earliest stage. Favor clear foundations, fast learning, and playable
increments. Do not assume the architecture, technology, mechanics, or deployment model of any
other game project; record those decisions here only after they are made for this game.

## Start with relevant context

Read the smallest relevant document in `docs/context/` before exploring broadly. The context index
is `docs/context/README.md`.

Keep durable design decisions in `docs/design/` as the project develops. When changing a contract
that spans multiple files or systems, update its design document and all implementations together.

## Scope and evidence

- For requests to investigate, review, audit, scout, or confirm, inspect and report. Keep the pass
  read-only unless the user also requests a change.
- A request to build, change, or fix authorizes the complete normal delivery workflow: make the
  in-scope edits, run focused non-destructive validation, commit the task, and—when an `origin`
  GitHub remote exists—open an owned PR, arm auto-merge, and wait for the merge.
- Base claims about current gameplay, architecture, tests, deployments, and repository state on
  current evidence rather than memory.
- Ask before destructive actions, direct pushes to the default branch, or material scope expansion.
- Preserve unrelated user changes and stage only files belonging to the task.

## Editing and Git workflow

Read-only inspection may use the current checkout. Before editing an established repository, work
in a clean task-specific worktree based on the current remote default branch. Store task worktrees
under `/tmp/economy-worktrees/`. If no remote exists yet, use a task branch in the local repository
and do not invent remote or pull-request steps.

- Name agent task branches `agent/<short-task-name>`.
- Parallel writers must use separate worktrees and branches.
- Use focused checks during development and the full test suite appropriate to the changed area
  before integration.
- Use clear commit subjects. Add a commit body when gameplay impact, contract changes, testing
  nuance, or non-obvious reasoning deserves explanation.
- Do not claim a push, pull request, deployment, or merge unless current Git or hosting evidence
  confirms it.
- Once the remote PR workflow exists, finish requested builds, changes, and fixes with
  `scripts/agent-pr.sh --verification "<focused checks passed>"`, then
  `scripts/wait-pr.sh <pr>`. See `docs/pr-first-workflow.md`.

## Repository workflow

- Run `scripts/install-hooks.sh` once per clone.
- Tracked pre-commit and pre-merge hooks run cheap staged-diff and workflow checks.
- Post-commit and post-merge hooks clean only clean, merged `agent/*` worktrees beneath
  `/tmp/economy-worktrees/`.
- `scripts/agent-pr.sh` runs configured specialist passes and a final autonomous adversarial review
  before it opens or updates a PR.
- `scripts/agent-pr-passes.json` starts empty. Add game-specific passes only after this project
  establishes the corresponding workflow.
- `scripts/verify-workflows.sh` validates the workflow scaffold locally without GitHub or Codex.

## Documentation

- Keep context capsules concise and navigational; detailed rationale belongs in design documents.
- Keep source-of-truth rules in active documentation, not in archived plans.
- Update documentation in the same change as the behavior or contract it describes.
- Use `plans/` for staged implementation work and follow `docs/context/planning.md`.

## Engineering principles

Until the project chooses more specific conventions:

- Keep game rules and state transitions deterministic where practical.
- Treat external input and persisted data as untrusted; validate and bound them at system edges.
- Keep core game logic separate from presentation, transport, and storage concerns.
- Prefer small, testable units and explicit ownership over hidden global state.
- Make lifecycle and cleanup responsibilities explicit for systems that own listeners, processes,
  files, timers, or graphics resources.
- Add dependencies only when their value outweighs their maintenance and supply-chain cost.

## Early-stage game development

- Put expensive-to-reverse architecture, authority, data ownership, and security decisions on the
  critical path.
- Reach playable, inspectable slices before speculative hardening or content scale-up.
- Use playtests and measured checkpoints when they reduce meaningful uncertainty.
- Record player-facing changes and what should be watched in playtests.
- Keep speculative ideas in a deferred backlog rather than silently expanding active scope.

## Completion

Lead with the outcome. Include the evidence needed to support it, material caveats, and the next
action. For gameplay-affecting changes, explain the player-facing impact.
