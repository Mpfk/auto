# Project Instructions

This project uses a multi-agent software development workflow. Read `docs/auto/agent-flow.md` for the complete specification — it is the **source of truth** for all workflow rules, agent behaviors, and state transitions.

## Non-Negotiable Rules

1. **Documentation in `docs/` only.** All project docs live in `docs/`. Only `README.md` at root. Never create documentation files in `src/`, project root, or elsewhere.
2. **Issue-based work.** No work begins without a GitHub Issue. Check existing issues before creating new ones.
3. **Branch-per-issue.** All code on feature branches (`issue/{issue-number}`). Direct commits to `main` are forbidden.
4. **Test-driven development.** Strict Red-Green-Refactor. Tests are written before implementation. No merge without passing tests.
5. **Conventional Commits.** All commits follow: `type(scope): description`. Types: feat, fix, test, refactor, docs, chore.

## How to Run the Workflow

The **main conversation** (you + the user) coordinates the workflow. Agents are short-lived workers for specific phases — no single agent runs the entire lifecycle.

### Phase 1: Init
Invoke the **orchestrator** agent. It creates the GitHub Issue, checks for duplicates, and creates the feature branch. Returns when the issue is in `status/draft`.

### Phase 2: Research
Invoke the **orchestrator** agent again (or invoke research agents directly). It updates status to `status/researching`, launches parallel research agents, synthesizes findings, and writes the plan. Returns when the plan and acceptance criteria are ready.

### Phase 3: Gate 1 — Plan Approval
**You handle this in the main conversation.** Present the research, plan, and acceptance criteria to the user. Update label to `status/ready` on approval. Revise if requested.

### Phase 4: Implement
Update label to `status/in-progress`. Invoke **tdd** agents (one per independent task) and **documentation** agent in parallel. Each tdd agent receives fully materialized context (see "Spawning Agents" below). If this is the first implementation on the project (no package.json / no build tool), include scaffold instructions in the tdd agent prompt.

### Phase 5: Review
Update issue label to `status/review`. Invoke the **review** agent with the issue number, branch, and acceptance criteria. Wait for it to complete. If it fails, fix issues and re-run.

### Phase 6: Gate 2 — Merge Approval
**You handle this in the main conversation.** The issue **MUST have the `status/review` label before presenting Gate 2** — this is a hard prerequisite. Present the review summary, retrospective, diff, and proposed merge commit. On rejection: write retrospective as issue comment, update label to `status/researching`, go to Phase 2.

### Phase 7: Merge
Merge the branch with a Conventional Commits message. Update issue label to `status/done` and close the issue.

## Spawning Agents

When invoking any agent, provide **fully materialized context** in the prompt — not references to files or placeholders. Every agent prompt must include:

- The exact issue number and branch name
- The specific task description (not "read the issue")
- Acceptance criteria verbatim
- Relevant file paths
- What "done" looks like for this invocation

### Parallel Execution Rules

- Launch concurrent agents when tasks are independent
- **Never** invoke an agent and then duplicate its work in the main conversation

### Scope Budget

Each agent invocation should complete in one shot:

| Agent | Target tool calls | Scope |
|-------|------------------|-------|
| Research (per angle) | ~10 | One research strategy |
| TDD (per component) | ~15-20 | One RED-GREEN-REFACTOR cycle |
| Documentation | ~10-15 | Update docs for one feature |
| Review | ~15-20 | Validate one branch |

If a TDD task requires multiple components, invoke **multiple tdd agents** rather than asking one to do everything.

## Agents

Five specialist agents in `.github/agents/`:

| Agent | Purpose | Invoked by |
|-------|---------|------------|
| `orchestrator` | Creates GitHub Issues, runs research, synthesizes findings, writes plans. Handles init through Gate 1. | Main conversation |
| `research` | Investigates one angle of a problem (codebase, docs, external, constraints). Multiple run in parallel. | Orchestrator or main conversation |
| `tdd` | Implements one component via Red-Green-Refactor. | Main conversation |
| `documentation` | Maintains `docs/` directory. Creates/updates docs, ADRs, README. | Main conversation |
| `review` | Pre-merge validation. Checks TDD compliance, code quality, docs, tests. Read-only. | Main conversation |

## Configuration

- `workflow.conf` — Project-specific settings (test command, source/test directories). Edit this per project.
- `.githooks/` — Git hooks enforce workflow rules locally. Activated via `git config core.hooksPath .githooks`.
- `.github/workflows/` — GitHub Actions enforce rules in CI.

## Issue Status Flow

Issues use GitHub labels for status tracking:

`status/draft` → `status/researching` → `status/planning` → **Gate 1** → `status/ready` → `status/in-progress` → `status/review` → **Gate 2** → `status/done`

On Gate 2 rejection: retrospective → back to `status/researching` (full loop with learnings).

See `docs/auto/agent-flow.md` for the complete state machine and gate definitions.
