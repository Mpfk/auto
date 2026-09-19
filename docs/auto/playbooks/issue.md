# Issue and planning contract

Contract: `AUTO-ISSUE-v1`

## Inputs

- A concrete request or existing issue number.
- Duplicate-search results and relevant code, docs, external, and constraint
  research.

## Outputs

- A Conventional-Commit-style issue title.
- Problem statement, synthesized research, constraints, open questions,
  independently testable plan, and acceptance criteria in the issue body.
- Optional sub-issues only when work divides into independently mergeable units.

## State transitions

Create at `status/draft`, then move through `status/researching` and
`status/planning`. After Gate 1 approval, set `status/ready`.

## Stopping conditions

Stop before issue creation if scope is materially ambiguous. Stop before Gate 1
if research, a testable plan, or acceptance criteria are missing. On rejection,
incorporate feedback and resume research/planning.

## Gate authority

Present Gate 1 interactively unless `core.md` grants autonomous authority.
Approval authorizes the planned implementation, not unrelated work.

