# Review contract

Contract: `AUTO-REVIEW-v1`

## Inputs

- Issue number, PR and branch, current head SHA, and acceptance criteria.
- Green CI status and the configured test suite.
- Native review state and finding links when Codex performs the review.

## Outputs

- Deterministic preflight output from `bin/auto-review-preflight`.
- A semantic review verdict covering correctness, security, regressions, tests,
  docs, and every acceptance criterion.
- An issue comment in this normalized form:

```markdown
## Review: PASS|FAIL
- Provider: `codex-native|codex-local|claude|copilot`
- Reviewed head SHA: `<40-character SHA>`
- Preflight: `PASS|FAIL`
- Finding links: `<links or None>`
```

Add a concise summary and actionable failing checks below the record.

## Codex review routing

For a Codex-driven PR, post `@codex review` and wait at most five minutes for a
completed review of the current head. Native PASS additionally requires no
unresolved P0/P1 findings. If native review is unavailable, errors, or times
out, run this local review workflow and record provider `codex-local`.

## State transitions

Only a draft PR with green CI enters `status/review`. PASS permits the PR to be
readied and Gate 2 to be presented. FAIL returns to development without
advancing the gate.

## Stopping conditions

Fail on stale head, non-green CI, non-Conventional commits, TDD ordering
violations, misplaced docs, failing configured tests, missing acceptance
coverage, unresolved P0/P1 findings, or substantive semantic defects.

## Gate authority

Review supplies Gate 2 evidence but cannot approve Gate 2 or merge. Gate 2 must
reject absent records, `FAIL`, a non-PASS preflight, or a reviewed SHA different
from the PR's current head.

