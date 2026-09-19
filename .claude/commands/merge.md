---
description: Validate Gate 2, merge an approved Auto PR, and verify the final GitHub state.
argument-hint: Optional issue or PR number
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/merge.md` completely. Use `$ARGUMENTS` or the current
`issue/{number}` branch to identify the work.

Prefer authenticated `gh`; use GitHub MCP tools otherwise. Re-read the PR head,
CI, mergeability, issue status, and latest normalized review record immediately
before Gate 2. When a human invoked `/merge`, use Claude's approval selection UI.
When `/auto` invoked these steps, inherit only its scoped autonomous authority.
After merging, verify PR `MERGED`, issue closed at `status/done`, and `main`
advanced.
