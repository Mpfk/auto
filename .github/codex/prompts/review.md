# Auto PR review

Review the checked-out pull request without modifying files or GitHub state.
Use the current `HEAD` and evaluate only the diff from the configured base.

Report P0 and P1 findings with precise file/line evidence and a stable finding
URL when available. Return `PASS` only when there are no unresolved P0/P1
findings. This semantic verdict supplements, and never replaces,
`bin/auto-review-preflight`.

Emit JSON matching `.github/codex/schemas/review-result.json`. Set
`reviewed_head_sha` to `git rev-parse HEAD` and `provider` to `codex-native`.

