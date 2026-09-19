# Merge contract

Contract: `AUTO-MERGE-v1`

## Inputs

- Issue and PR identity, current head SHA, labels, checks, mergeability, latest
  normalized review record, diff, commits, and latest retrospective.

## Outputs

- A Conventional merge subject matching the issue type.
- A verified merged PR, closed issue with `status/done`, and advanced `main`.
- On denial, a numbered retrospective containing the user's verbatim feedback.

## State transitions

Gate 2 requires `status/review`, green CI, a mergeable PR, and a PASS review
record whose reviewed SHA equals the current PR head and whose preflight is
PASS. Approval merges and verifies `status/done`; denial returns to
`status/researching`.

## Stopping conditions

Stop on any missing or stale prerequisite, a draft that cannot be readied,
conflicts, merge failure, or failed post-merge verification. Never infer merge
success from the mutation response alone.

## Gate authority

Present Gate 2 interactively unless `core.md` grants autonomous authority. A
capable merge tool is not itself approval.

