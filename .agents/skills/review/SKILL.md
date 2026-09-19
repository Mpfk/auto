---
name: review
description: Review an Auto PR at its current head using deterministic preflight plus native Codex review or the bounded local fallback, and record normalized evidence.
---

# Review

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/review.md` completely, then follow them.

Run `bin/auto-review-preflight`. For Codex-driven PRs, request `@codex review`
and wait no more than five minutes. If native review is unavailable, errors, or
times out, perform the semantic review locally and record `codex-local`.

