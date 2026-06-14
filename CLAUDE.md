# Auto — Claude Code Workflow Guide

This repository uses the **Auto** multi-agent workflow. All work flows through GitHub Issues with two approval gates. Those gates are human-driven in the standalone `/issue` and `/merge` commands and self-approved by the fully autonomous `/auto` command. See `docs/auto/agent-flow.md` for the full specification.

GitHub access depends on the environment: in **local** Claude Code sessions the `gh` CLI is available and is the primary tool; in **cloud/remote** sessions (claude.ai/code, mobile, GitHub Actions) `gh` is not installed and all GitHub operations go through the `mcp__github__*` MCP tools instead. Every Auto command starts with a Step 0 detection check and maps `gh` invocations to MCP equivalents per `docs/auto/github-access.md`. Both modes are first-class — never treat a missing `gh` CLI as a blocker.

## Non-Negotiable Rules

1. **Issue-first.** No code, no branches, no PRs without a GitHub Issue. Check for duplicates first.
2. **Branch naming.** Always `issue/{number}`. Never `copilot/...` or any other convention. *Exception:* when a managed cloud session assigns and enforces its own push branch (e.g. `claude/...`), develop on that branch and link the issue via `Closes #N` in the PR body (see `docs/auto/github-access.md`).
3. **No direct commits to `main`.** All work on `issue/{number}` branches. The branch guard hook enforces this.
4. **Strict TDD.** Red-Green-Refactor. Tests written before implementation. No exceptions.
5. **Conventional Commits.** `type(scope): description`. Types: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`. The commit-msg hook enforces this.
6. **Docs in `docs/` only.** Permitted root-level files: `README.md` and `CLAUDE.md`. No other `.md` files in `src/`, project root, or elsewhere. `.claude/` command files are also allowed.
7. **Gate integrity.** Gate 1 (plan) and Gate 2 (merge) are decision points with hard preconditions that must always hold — Gate 1 needs a synthesized plan + acceptance criteria; Gate 2 needs `status/review`, a Review PASS, CI green, and a mergeable PR. Who approves depends on the command: the standalone `/issue` and `/merge` commands present the gates for **human confirmation** via the Approve/Deny selection UI, while `/auto` runs **fully autonomously and self-approves both** (it never waits for input). Autonomy removes the human pause, never the preconditions — never merge with a gate's preconditions unmet.

## Workflow Status Flow

```
status/draft → status/researching → status/planning → [Gate 1] → status/ready → status/in-progress → [CI gate] → status/review → [Gate 2] → status/done
```

Everything between the gates is automated. `/auto` also self-approves both gates and drives the flow end-to-end without pausing; the standalone `/issue` (Gate 1) and `/merge` (Gate 2) commands stop for your explicit approval via the selection UI.

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/issue [description or issue#]` | Create issue, run parallel research, write plan, optionally split into sub-issues, present Gate 1 (selection UI) |
| `/auto [issue_number]` | **Auto-drive the full workflow to merge.** Reads current state, chains all phases, self-approves both gates. Fully autonomous — never pauses. Fans out per sub-issue |
| `/merge [issue#/PR#]` | Validate merge prerequisites, present Gate 2 (selection UI), merge, and verify the merge landed |
| `/develop <issue> <branch> <task> <criteria>` | One Red-Green-Refactor cycle with retrospective |
| `/review <issue> <branch> <criteria>` | Pre-merge validation: TDD compliance, quality, tests, docs |
| `/document <issue> <branch> <changes> <files>` | Update `docs/` for completed work |
| `/research <issue> <strategy> <scope>` | Single-strategy investigation: `codebase`, `docs`, `external`, or `constraints` |

### Typical Full Workflow

**Hands-off (fully autonomous):**
```
/auto "add user authentication with email/password"
# → Creates the issue, researches, plans, implements, reviews, and merges —
#   self-approving both gates. Monitor CI with /loop 2m /auto <issue#> if it pauses on a running CI run.
```

**Human at each gate:**
```
# Step 1: Create issue, research, plan — presents Gate 1 via the selection UI
/issue "add user authentication with email/password"
# → Review the research, plan, and any proposed sub-issues. Press Approve, or pick Other to give feedback.

# Step 2: Drive implementation up to review
/auto 42
# → Implements via develop + document agents, monitors CI, runs /review when CI is green.

# Step 3: Approve and merge — presents Gate 2 via the selection UI
/merge 42
# → Verifies prerequisites, then press Approve to merge (or Other to send it back with feedback).
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

Activate once after cloning **and once in every new worktree**:

```
bin/setup-hooks
```

This runs `git config core.hooksPath .githooks` idempotently. The relative
`.githooks` path is what makes hooks fire correctly inside `git worktree`
checkouts: worktrees share the main repo's `.git/config`, and a relative
`core.hooksPath` is resolved against each working tree's own root. An absolute
value (e.g. pointing at the main checkout's empty `.git/hooks`) would silently
bypass all hooks in every worktree. **`git worktree add` does not run this for
you** — agents and humans creating a worktree must run `bin/setup-hooks` in it.

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

## Managing Autonomous Sub-agent Teams

When the user grants broad autonomy ("manage a team", "automatically complete all open issues", "auto-merge", or equivalent), apply this management pattern. The user's grant is the source of authority — it does not override the Non-Negotiable Rules; it delegates gate approval within an agreed scope (see "When to ask vs proceed" below).

### Per-issue workflow

1. **Issue-first.** File a GitHub Issue before any code (Non-Negotiable Rule 1). Use `mcp__github__create_issue` so it works regardless of `gh` CLI auth state.
2. **One `/auto` sub-agent per issue**, spawned with `isolation: "worktree"` so concurrent sub-agents don't collide and the user's main checkout stays clean.
3. **Materialized context in every prompt** — verbatim plan and acceptance criteria, file paths with line numbers, dependencies on other issues, and explicit coordination notes when other sub-agents are in flight on overlapping files.
4. **Gate authority is delegated, not skipped.** A `/auto` sub-agent runs to completion without pausing, so it cannot stop at a gate interactively. The spawn prompt must state explicitly which gates the sub-agent may self-approve, based on the scope the user authorized. Features still surface Gate 1 to the user *before* the sub-agent is spawned. Never grant a sub-agent gate authority the user has not delegated.

### Concurrency strategy

- **File-disjoint issues:** spawn in parallel. Each sub-agent rebases on `main` before its final push.
- **File-overlapping issues:** serialize. File the dependent issue now, but spawn its sub-agent only after the parent issue merges.
- **Same file, different regions:** parallel is acceptable. Tell each sub-agent that if its pre-push rebase reports a conflict, it should resolve by keeping BOTH branches' additions.

### After each merge

1. **Pull `main` locally and verify it landed.** Append a sentinel (e.g. `&& echo _PULL_DONE_`) to the pull command and confirm the sentinel appears in the output — interrupted pulls silently leave a stale local tree.
2. **Reinstall dependencies** if the dependency manifest changed.
3. **Restart any long-running dev process** so it serves the merged code.
4. **Smoke-test the merged work** — run the relevant subset of `TEST_CMD` (from `workflow.conf`) or exercise the affected entry point to confirm it actually works.

### Friction handling

- When a sub-agent hits friction (tooling bug, infrastructure outage, workflow gap), file a GitHub Issue for it. Never accumulate undocumented workarounds.
- Before re-discovering a known problem, search existing open issues for prior friction reports.

### When to ask vs proceed

- **Features (`feat`):** file the issue, present Gate 1 with the plan and acceptance criteria, and wait for explicit user approval before spawning the `/auto` sub-agent.
- **Fixes and chores (`fix`, `chore`, `docs`, `refactor`) under a standing autonomy grant:** spawn the `/auto` sub-agent without further prompting, including Gate 2 auto-merge within the granted scope.
- **Ambiguous scope:** ask via `AskUserQuestion` before filing — don't file an issue you can't precisely scope.

## GitHub Tools

`mcp__github__*` tools are globally available in every environment. Use `gh` CLI for issue/PR management in straightforward cases when it is installed and authenticated (local sessions). In cloud/remote sessions — or whenever `command -v gh` fails — use the MCP tools exclusively; `docs/auto/github-access.md` maps every `gh` operation used by the Auto commands to its MCP equivalent. MCP tools are also preferred for complex operations (batch updates, searching, etc.) in any environment.
