# Auto — Claude Code adapter

This repository uses Auto. Before any workflow action, read
`docs/auto/playbooks/core.md`; for GitHub state also read
`docs/auto/playbooks/github.md`. The shared playbooks are normative. This file
contains only Claude Code invocation and tool guidance.

## Claude Code interface

| Command | Shared contract |
|---|---|
| `/auto` | `docs/auto/playbooks/auto.md` |
| `/issue` | `docs/auto/playbooks/issue.md` |
| `/merge` | `docs/auto/playbooks/merge.md` |
| `/develop` | `docs/auto/playbooks/develop.md` |
| `/review` | `docs/auto/playbooks/review.md` |
| `/document` | `docs/auto/playbooks/document.md` |
| `/research` | `docs/auto/playbooks/research.md` |

Each command file loads its contract and preserves its existing arguments.
`/issue` and interactive `/merge` use Claude's approval selection UI. Explicit
`/auto` is autonomous and self-approves both gates after all preconditions hold.

## GitHub tools

Prefer authenticated `gh` in local sessions. If it is unavailable or lacks the
required capability, use the available `mcp__github__*` tools. Do not stop merely
because one transport is missing; follow `docs/auto/github-access.md`.

## Local setup

Run `bin/setup-hooks` after cloning and in every new worktree. Read
`workflow.conf` for the full test command and source/test directories.

When spawning an agent, provide the exact issue, branch, bounded task,
acceptance criteria, relevant paths, and definition of done. Parallelize only
file-disjoint work.
