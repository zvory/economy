# Phased plan convention

Use this directory for multi-phase implementation plans. Each plan gets a
`plans/<short-name>/` directory with a concise lowercase name that is easy to reference later.

Each active plan directory contains:

- `plan.md`, the entry point and whole-plan overview.
- One document per implementation phase, normally `phase-1.md`, `phase-2.md`, and so on.
- An optional deferred backlog for ideas that are explicitly outside the approved implementation
  chain.

## Plan entry point

`plan.md` must include:

- The objective and evidence motivating the work.
- Overall constraints, invariants, risks, and important considerations.
- Dependencies and the order in which phases must land.
- A plain-language three-sentence summary of each phase.
- A definition of the final coherent outcome.
- A requirement for verification, manual-testing notes, and a next-agent handoff after each phase.

## Phase documents

Use this shape for each phase:

```markdown
# Phase N: Short title

Status: Not started

## Outcome

Describe the coherent result this phase must leave behind.

## Scope

List the work included in this phase and explicitly name important exclusions.

## Expected touch points

Identify likely code, content, test, and documentation areas without turning the plan into a
line-by-line patch prescription.

## Acceptance criteria

State observable conditions that must be true when the phase is complete.

## Verification

List focused automated checks and any broader suite required before integration.

## Manual testing

Name the core player or developer flows that need human inspection.

## Handoff

Describe what evidence and context the implementing agent must give the next agent.
```

Mark `Status: Done` in the implementation commit that completes a phase. Keep incomplete work and
follow-ups visible; do not mark a phase done merely because its branch or pull request exists.

## Integration

Implement each phase on its own task branch and commit it as an independently reviewable unit.
Dependent phases begin only after the preceding phase is integrated. If the repository has a
remote pull-request workflow, confirm the merge and verify the phase commit is reachable from the
remote default branch before continuing.

## Archive policy

When every phase is done, move the complete directory to `plans/archive/<short-name>/`. Archived
plans are historical evidence, not source-of-truth product policy. If an archived rule remains
valid, place it in the relevant active document under `docs/` and make automation depend on that
active source. During PR delivery, `scripts/agent-pr.sh` automatically archives a plan when the
branch changes at least one phase to `Status: Done` and every phase in that plan is done.
