# Project Instructions

This project uses a structured software development workflow. Every piece of work is tracked as a GitHub Issue, developed on its own branch, implemented test-first, and documented before it reaches `main`. See `docs/auto/agent-flow.md` for the full specification.

## MANDATORY: Create a GitHub Issue Before Any Code

**DO NOT write code, create branches, or open PRs until a GitHub Issue exists.**

When a user asks you to build something, your FIRST action is to create a GitHub Issue — not to start coding. This applies in ALL contexts: VS Code, GitHub.com cloud agent, and any other environment.

### Step-by-step (follow this exactly):

1. **Check for duplicates.** List open issues and check for overlap.
2. **Create the GitHub Issue** with these fields:
   - **Title:** `<type>(<scope>): <description>` (Conventional Commits style)
   - **Labels:** `["status/draft"]`
   - **Body:** Use this template:
     ```
     ## Problem Statement
     {what the user asked for}

     ## Description
     {details and context}

     ## Research
     ### Key Findings
     ### Constraints
     ### Open Questions

     ## Plan

     ## Acceptance Criteria
     ```
3. **Research** the codebase and problem. Update the issue body with findings.
4. **Write a plan** with independently testable tasks and acceptance criteria in the issue body.
5. **Update issue labels** to `status/researching` → `status/planning` → `status/ready` as you progress.
6. **Present the plan to the user** for approval before implementing.
7. **After plan approval**, set issue label to `status/ready`.
8. **Use native automation for implementation kickoff**: branch `issue/{issue-number}` is created and status moves to `status/in-progress` when Copilot is assigned. If automation is unavailable, do this manually.
9. **Only after approval**, begin implementation on the `issue/{number}` branch using TDD.

If you cannot create issues (missing tools or permissions), STOP and tell the user: "This workflow requires GitHub issue creation. See `docs/auto/copilot-cloud-setup.md` for setup instructions."

**Never use branch names like `copilot/...`** — always use `issue/{number}`.

## Non-Negotiable Rules

1. **Documentation in `docs/` only.** All project docs live in `docs/`. Only `README.md` at root. Never create documentation files in `src/`, project root, or elsewhere.
2. **Issue-based work.** No work begins without a GitHub Issue. Check existing issues before creating new ones.
3. **Branch-per-issue.** All code on feature branches (`issue/{issue-number}`). Direct commits to `main` are forbidden.
4. **Test-driven development.** Strict Red-Green-Refactor. Tests are written before implementation. No merge without passing tests.
5. **Conventional Commits.** All commits follow: `type(scope): description`. Types: feat, fix, test, refactor, docs, chore.

## How to Run the Workflow

The workflow supports two execution modes:

1. Chat-orchestrated mode (main conversation drives each phase)
2. GitHub-native mode (issue labels, assignees, and PR events drive transitions)

Agents are short-lived workers for specific phases. No single agent runs the entire lifecycle.

### GitHub-Native Triggers

Use these event-driven transitions when users operate directly from GitHub:

1. Issue created with `status/draft` -> Issue agent performs intake, research, and planning.
2. Plan approved -> issue moved to `status/ready`.
3. Issue assigned to Copilot while `status/ready` -> implementation starts on `issue/{number}`.
4. PR opened from `issue/{number}` -> issue moved to `status/in-progress`.
5. CI checks pass on draft PR -> issue moved to `status/review` and Review Agent is invoked.
6. Review Agent returns PASS -> PR converted from draft to ready-for-review.
7. CI checks fail on PR -> develop agent re-invoked on `issue/{number}` with failure output and prior retrospective as context; label stays `status/in-progress`.
8. PR merged -> issue moved to `status/done` and closed.

### Phase 1: Init
Invoke the **orchestrate** agent. It creates the GitHub Issue and checks for duplicates. Returns when the issue is in `status/draft`.

### Phase 2: Research
Invoke the **orchestrate** agent again (or invoke research agents directly). It updates status to `status/researching`, launches parallel research agents, synthesizes findings, and writes the plan. Returns when the plan and acceptance criteria are ready.

### Phase 3: Gate 1 — Plan Approval
**You handle this in the main conversation.** Present the research, plan, and acceptance criteria to the user. Update label to `status/ready` on approval. Revise if requested.

### Phase 4: Implement
Use native automation to move to `status/in-progress` when Copilot is assigned on a `status/ready` issue. Invoke **develop** agents (one per independent task) and **documentation** agent in parallel. Each develop agent receives fully materialized context (see "Spawning Agents" below). If this is the first implementation on the project (no package.json / no build tool), include scaffold instructions in the develop agent prompt.

After each RED-GREEN-REFACTOR cycle the Develop Agent posts a `## Retrospective — Iteration N` comment to the issue (and PR if one exists), where N is determined by counting prior `## Retrospective — Iteration` comments on the issue. This applies to every invocation — not only on CI failure.

Open a **draft** PR from `issue/{number}` → `main` once the first commit is pushed. The PR must remain a draft until all Gate 2 prerequisites are satisfied. Never convert a PR from draft to ready-for-review during the implementation phase.

### Phase 5: Review
Before invoking the Review Agent: verify CI checks are green on the PR. If CI checks fail, re-invoke the **develop** agent with the exact failure output and the retrospective from the last develop agent run — do not proceed to the Review Agent until CI is green.

Once CI is green on a draft PR, native automation sets issue label `status/review`. **Do not invoke the Review Agent while CI is failing.** Invoke the **review** agent with the issue number, branch, and acceptance criteria. Wait for it to complete. If it fails, fix issues and re-run.

When the Review Agent returns PASS and CI is confirmed green: convert the PR from **draft to ready-for-review**. This is the only point at which the PR draft state is lifted.

### Phase 6: Gate 2 — Merge Approval
**You handle this in the main conversation.** Three prerequisites **MUST** all be satisfied before presenting Gate 2 — these are hard requirements:
1. Issue has `status/review` label.
2. Review Agent returned **PASS**.
3. CI checks are **green** on the PR.

Once all three are confirmed, the PR has been converted from draft to ready-for-review. Present the review summary, retrospective, diff, and proposed merge commit. On rejection: post a `## Retrospective — Iteration N` comment to the issue (where N = count of existing `## Retrospective — Iteration` comments + 1), update label to `status/researching`, go to Phase 2.

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
| Develop (per component) | ~15-20 | One RED-GREEN-REFACTOR cycle |
| Documentation | ~10-15 | Update docs for one feature |
| Review | ~15-20 | Validate one branch |

If a task requires multiple components, invoke **multiple develop agents** rather than asking one to do everything.

## Agents

Six specialist agents in `.github/agents/`:

| Agent | Purpose | Invoked by |
|-------|---------|------------|
| `issue` | GitHub-native intake and planning. Runs duplicate checks, research fan-out, and writes plan + acceptance criteria for Gate 1. | Main conversation or GitHub Agent |
| `orchestrate` | Creates GitHub Issues, runs research, synthesizes findings, writes plans. Handles init through Gate 1. | Main conversation |
| `research` | Investigates one angle of a problem (codebase, docs, external, constraints). Multiple run in parallel. | Orchestrate agent or main conversation |
| `develop` | Implements one component via Red-Green-Refactor. | Main conversation |
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
