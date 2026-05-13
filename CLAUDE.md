# Auto — Claude Code Workflow Guide

This repository uses the **Auto** multi-agent workflow. All work flows through GitHub Issues with two human approval gates. See `docs/auto/agent-flow.md` for the full specification.

`gh` CLI is fully available in Claude Code (unlike Copilot cloud where it returns 403) — commands use `gh` as the primary tool.

## Non-Negotiable Rules

1. **Issue-first.** No code, no branches, no PRs without a GitHub Issue. Check for duplicates first.
2. **Branch naming.** Always `issue/{number}`. Never `copilot/...` or any other convention.
3. **No direct commits to `main`.** All work on `issue/{number}` branches. The branch guard hook enforces this.
4. **Strict TDD.** Red-Green-Refactor. Tests written before implementation. No exceptions.
5. **Conventional Commits.** `type(scope): description`. Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`. The commit-msg hook enforces this.
6. **Docs in `docs/` only.** The only permitted root-level doc is `README.md`. No `.md` files in `src/`, project root, or elsewhere.
7. **Gate compliance.** Gate 1 (plan approval) and Gate 2 (merge approval) require human confirmation. Never auto-approve or skip them.

## Workflow Status Flow

```
status/draft → status/researching → status/planning → [Gate 1] → status/ready → status/in-progress → [CI gate] → status/review → [Gate 2] → status/done
```

Gate 1 and Gate 2 require your explicit approval. Everything between them is automated.

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/issue [description or issue#]` | Create issue, run parallel research, write plan, present Gate 1 |
| `/auto [issue_number]` | **Auto-drive the full workflow.** Reads current state, chains all phases. Pauses only at Gate 1 and Gate 2 |
| `/develop <issue> <branch> <task> <criteria>` | One Red-Green-Refactor cycle with retrospective |
| `/review <issue> <branch> <criteria>` | Pre-merge validation: TDD compliance, quality, tests, docs |
| `/document <issue> <branch> <changes> <files>` | Update `docs/` for completed work |
| `/research <issue> <strategy> <scope>` | Single-strategy investigation: `codebase`, `docs`, `external`, or `constraints` |

### Typical Full Workflow

```
# Step 1: Create issue, research, plan — presents Gate 1
/issue "add user authentication with email/password"
# → Review the research, plan, and acceptance criteria.
# → Reply "approve" to continue, or give feedback to revise.

# Step 2: Drive implementation all the way to Gate 2
/auto 42
# → Implements via develop + document agents in parallel
# → Monitors CI; re-invokes develop on failure
# → Runs /review when CI green
# → Pauses at Gate 2 with review summary and diff
# → Reply "approve" to merge.
```

### Resuming an In-Flight Issue

```
/auto 42
# Reads current status label and continues from exactly where it left off.
# Safe to run multiple times — idempotent.
```

### Auto-Polling CI

```
/loop 2m /auto 42
# Re-invokes /auto every 2 minutes until CI completes and the workflow advances.
```

## Git Hooks

Activate once after cloning:

```
git config core.hooksPath .githooks
```

Enforces locally:
- **Pre-commit:** branch guard (no commits to `main`), doc placement (docs in `docs/`), TDD cycle (test commits before source-only commits on issue branches)
- **Commit-msg:** Conventional Commits format; auto-appends `Closes #N` on `issue/*` branches
- **Pre-push:** issue status consistency (must be `status/in-progress` or beyond), full test suite gate

## Configuration

- `workflow.conf` — TEST_CMD, SRC_DIRS, TEST_DIRS, MAIN_BRANCH. Auto-detected from project markers; edit manually if needed.
- `.claude/settings.json` — Project-level permissions and doc-freshness hook. Scoped to this repo only.
- `.github/agents/` — Copilot agent definitions for GitHub-native mode. Do not modify.

## Spawning Sub-agents

When invoking any sub-agent, provide **fully materialized context** — not references like "read the issue":
- Exact issue number and branch name
- Task description (specific and actionable)
- Acceptance criteria (verbatim, not a reference)
- Relevant file paths
- What "done" looks like for this invocation

Run research sub-agents in parallel (independent strategies). Run develop + documentation agents in parallel during implementation.

## GitHub Tools

`mcp__github__*` tools are globally available. Use `gh` CLI for issue/PR management in straightforward cases — it works fully in Claude Code. Use MCP tools for complex operations (batch updates, searching, etc.).
