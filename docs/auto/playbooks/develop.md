# Development contract

Contract: `AUTO-DEVELOP-v1`

## Inputs

- Approved issue, `issue/{number}` branch, one bounded task, and verbatim
  acceptance criteria.
- Relevant paths and the configured test command.

## Outputs

- A Red-Green-Refactor change with meaningful tests and focused Conventional
  Commits.
- A numbered `## Retrospective — Iteration N` issue comment describing the
  attempt, result, and recommendations.
- A pushed branch and draft PR once the first implementation is available.

## State transitions

`status/ready -> status/in-progress`. Keep the PR draft throughout development.
Failed CI remains `status/in-progress` and starts another development iteration
with the exact failure output and prior retrospective.

## Stopping conditions

Stop if Gate 1 is not approved, the branch is wrong, tests cannot demonstrate
the requested behavior, or implementation would exceed the approved scope.

## Gate authority

This phase cannot approve either gate and cannot ready or merge the PR.

