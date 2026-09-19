# Auto core contract

Contract: `AUTO-CORE-v1`

This is the provider-neutral contract for Claude Code, GitHub Copilot, and
OpenAI Codex adapters. Provider files may add invocation or tool syntax, but may
not weaken these invariants.

## Inputs

- A user request or existing issue number.
- Repository configuration from `workflow.conf`.
- GitHub issue, branch, PR, review, and check state when the phase needs it.
- The invoking context's gate authority: interactive or autonomous.

## Outputs

- One traceable issue and one implementation branch per unit of work.
- Phase results described by the relevant playbook.
- A complete state trail through labels, PR state, CI, review evidence, and the
  final merge or an explicit stopping reason.

## State transitions

`status/draft -> status/researching -> status/planning -> Gate 1 -> status/ready -> status/in-progress -> CI -> status/review -> Gate 2 -> status/done`

Transitions are monotonic except that rejected gates return the issue to
`status/researching`. Creating an issue does not authorize implementation.

## Workflow invariants

1. Issue-first; check for duplicates before creating one.
2. Use `issue/{number}` and never commit directly to `main`. A managed cloud
   branch is the only exception and must close the issue from the PR.
3. Use Red-Green-Refactor and Conventional Commits.
4. Keep documentation in approved locations. `docs/` is the default;
   `README.md`, `CLAUDE.md`, `AGENTS.md`, `CHANGELOG.md`, `.claude/`,
   `.github/`, and `.agents/` are policy/configuration exceptions.
5. Gate preconditions never become optional, including in autonomous mode.
6. A draft PR stays draft until CI and review pass.

## Stopping conditions

Stop with a precise, actionable reason when required input is absent, no GitHub
transport can provide a required capability, a gate is denied, CI or review
fails, the PR conflicts, or an external mutation lacks authority. Work that is
safe and independent of the blocker may continue.

## Gate authority

- Interactive is the default, including ordinary implementation requests that
  implicitly use Auto. Present Gate 1 and Gate 2 to the user.
- Autonomous authority exists only when `$auto` is explicitly invoked or the
  user clearly requests hands-off completion or merge. In that context, the
  agent may self-approve both gates after every precondition is satisfied.
- Delegated authority is scoped; never infer permission for a different issue,
  release, or external system.

