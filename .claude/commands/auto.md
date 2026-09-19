---
description: Autonomously drive one Auto issue from its current state through verified merge.
argument-hint: Optional issue number (auto-detects from issue/{number})
---

Read `docs/auto/playbooks/core.md`, `docs/auto/playbooks/github.md`, and
`docs/auto/playbooks/auto.md` completely. Treat `$ARGUMENTS` as the optional
issue number; otherwise derive it from `issue/{number}`.

This explicit `/auto` invocation grants autonomous Gate 1 and Gate 2 authority
for the identified issue only. Resume from current GitHub state, invoke the
specialist phases as needed, and self-approve gates only after every contract
precondition is verified. If GitHub Actions are unavailable and return no
checks, use the shared CI fallback contract rather than stalling. Prefer
authenticated `gh`; use available GitHub MCP tools for any capability `gh`
cannot provide. Return a precise resumable reason if stopped.
