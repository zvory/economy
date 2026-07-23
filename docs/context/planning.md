# Multi-phase planning capsule

Use this capsule whenever a task asks for a multi-phase plan, phased implementation sequence, or
similar staged handoff. Phased plans live under `plans/<short-name>/`, where the directory name is
lowercase, concise, and descriptive.

Reusable analysis methods and durable product rules belong in `docs/`, not in active plan
directories. Create a phased plan only when current evidence supports implementation work.

## Scope-driven early development

For an early-stage feature, prototype, or learning-oriented vertical slice, distinguish
architecture that is expensive to reverse from hardening that can follow evidence. Authority,
security, shared data boundaries, state ownership, persistence semantics, lifecycle cleanup, and
bounded failure may block the first playable slice. Exhaustive tooling, generalized abstractions,
performance certification, device matrices, and polished content normally do not.

Let the evidence-backed scope determine the phase count. Use a playtest or measured checkpoint when
it materially reduces uncertainty, not after an arbitrary number of phases. Preserve genuinely
speculative ideas in a concise deferred backlog rather than using the backlog as overflow from a
numeric phase cap.

## Required shape

- Create `plans/<short-name>/plan.md` as the entry point.
- Split implementation phases into separate files in the same directory, such as `phase-1.md`,
  `phase-2.md`, and `phase-3.md`.
- In `plan.md`, include a plain-language three-sentence summary of each phase.
- In `plan.md`, include the overall constraints and important considerations that apply across
  every phase.
- State dependencies and ordering explicitly. A phase should be independently reviewable and
  should leave the repository in a coherent state.
- Each phase file must describe scope, expected touch points, acceptance criteria, automated
  verification, manual testing focus, and handoff expectations.
- After implementing a phase, the implementing agent must provide a handoff describing what the
  next agent should do, what changed, what was verified, and which core features should be manually
  tested. Manual testing notes should focus on important behavior, not an exhaustive matrix.
- Implement and commit each phase on its own task branch. Integrate one phase before starting a
  dependent phase.
- When a remote and pull-request workflow exist, push each phase as its own pull request and wait
  for a definite merge before starting the dependent phase. Verify that the phase commit is
  reachable from the remote default branch before reporting it complete.
- When a phase is complete, mark its phase document done in that phase's implementation commit.
- After every phase is complete, move the plan to `plans/archive/<short-name>/` as part of the final
  integration or a small follow-up commit. Once the remote PR workflow is active,
  `scripts/agent-pr.sh` detects and commits this transition automatically.

See [`plans/README.md`](../../plans/README.md) for the full convention and a phase-file template.
