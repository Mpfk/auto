---
description: Update documentation for an implemented Auto issue while enforcing placement policy.
argument-hint: issue_number branch "changes summary" "changed files"
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/document.md` completely. Parse `$ARGUMENTS` in the
documented order and stop if any input is missing. Inspect the actual changed
files and update only useful user, API, architecture, setup, or decision docs.
