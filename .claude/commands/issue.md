---
description: Create or refine an Auto issue, research it, write a testable plan, and present Gate 1.
argument-hint: Description of work or an existing issue number
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/issue.md` completely. Use `$ARGUMENTS` as the request or
issue number. Use authenticated `gh` when available and GitHub MCP tools
otherwise.

Do not implement code. After research, plan, and acceptance criteria are in the
issue, present Gate 1 with Claude's approval selection UI. Apply feedback and
repeat planning on denial; set `status/ready` only on approval.
