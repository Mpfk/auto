---
description: Run Auto's deterministic and semantic pre-merge review and record normalized evidence.
argument-hint: issue_number branch "acceptance criteria"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/review.md` completely. Parse `$ARGUMENTS` in the documented
order and stop if any input is missing.

Confirm green CI, run `bin/auto-review-preflight`, inspect the complete diff and
acceptance coverage, and post the normalized issue record with provider
`claude`. Review is read-only except for tests and the evidence comment. Do not
ready or merge the PR.
