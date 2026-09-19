---
description: Implement one approved Auto task using a strict Red-Green-Refactor cycle.
argument-hint: issue_number branch "task description" "acceptance criteria"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/develop.md` completely. Parse `$ARGUMENTS` in the documented
order and stop if any input is missing.

Read `workflow.conf`, verify the exact branch, commit RED before GREEN, refactor
only while tests pass, then post the required numbered retrospective through
authenticated `gh` or available GitHub MCP tools. Keep any PR draft and do not
approve a gate.
