# Autonomous state progression contract

Contract: `AUTO-AUTO-v1`

## Inputs

- An issue number or a concrete request.
- Explicit `$auto` invocation or clear hands-off completion/merge language.
- Current issue, branch, PR, CI, and review state.

## Outputs

- The issue advanced as far as its verified state allows, ideally through a
  verified merge and `status/done`.
- Exact next action when blocked, with enough state to resume idempotently.

## State transitions

Detect the current label and resume at the matching phase. Chain `issue`,
`research`, `develop`, `document`, `review`, and `merge` without repeating
completed work. Fan out only independent tasks and serialize overlapping files.

## Stopping conditions

Stop on missing capability, failed tests/CI/review, conflicts, exhausted bounded
waits, or a scope decision not covered by the autonomy grant. A running CI job
is a resumable pause, not permission to skip the CI gate.

## Gate authority

Explicit `$auto` or unmistakable hands-off completion/merge language grants
self-approval of Gate 1 and Gate 2 for the scoped issue after their preconditions
hold. An ordinary implementation request does not.

