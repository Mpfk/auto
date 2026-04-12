# Auto — Multi-Agent Software Development Template

A reusable project template that enforces structured software development through specialized GitHub Copilot agents, test-driven development, GitHub Issues for project management, and automated git hooks + GitHub Actions.

## Quick Start

1. Clone this template into your new project
2. Start working by invoking the Orchestrate agent in Copilot Chat: `@orchestrate`

## How To Use

Choose the path that matches how you're running the workflow:

### Native GitHub Mode

Use this path if you want to drive the workflow entirely from GitHub — no local IDE required.

**Prerequisites**
- GitHub Copilot plan with coding agent (assign-to-Copilot) access
- MCP write access — the `@issue` and `@orchestrate` agents ship with `mcp-servers` frontmatter that enables GitHub write tools (create issues, create branches, etc.) automatically. No extra setup needed when using those agents. If you want the **default Copilot agent** to also have write access, follow the one-time repo configuration in [`docs/auto/copilot-cloud-setup.md`](docs/auto/copilot-cloud-setup.md).

**Steps**
1. Open Copilot Chat on GitHub and invoke `@issue` with a plain-English description of the work (e.g. `@issue Add a contact form with name, email, and message fields`)
2. Review the plan the Issue Agent posts as an issue comment
3. Assign **Copilot** to the issue (GitHub web UI) — implementation starts on a `issue/{number}` branch
4. When checks pass and the PR is ready, the Review Agent validates automatically; review the summary
5. Approve the merge — the branch merges to `main`, the issue closes, and the feature branch is deleted

---

### Developer Instance (VS Code)

Use this path if you're working locally in VS Code with GitHub Copilot Chat.

**Prerequisites**
- VS Code with the [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat) extension
- Repository cloned locally
- Git hooks activated: run `git config core.hooksPath .githooks` once after cloning
- GitHub CLI authenticated: `gh auth login`

**Invoking agents**

Open the Copilot Chat panel and type the agent name to start:

| What you want | Command |
|---|---|
| Start new work from a description | `@issue Add a contact form with name and email` |
| Start new work with full orchestration | `@orchestrate` |
| Re-plan an existing issue | `@issue 42` |

The agent drives the workflow — creating the issue, running research, writing a plan, and presenting it for your approval. You stay in control at two gates: plan approval and merge approval.

## How It Works

The `@orchestrate` agent manages the full development lifecycle in chat-driven mode:

1. You describe what you need (feature, bug fix, refactor)
2. It creates a GitHub Issue, spawns Research Agents in parallel, synthesizes findings, and writes a plan
3. You approve the plan (Gate 1)
4. `@develop` and Documentation Agents implement the work on a feature branch
5. The Review Agent validates everything
6. You approve the merge (Gate 2)

The template also supports a GitHub-native mode where issue labels, assignees, and PR events drive the same lifecycle without requiring the full orchestration session in a local VM.

See [`docs/auto/agent-flow.md`](docs/auto/agent-flow.md) for the complete workflow specification.

## Project Structure

```
├── workflow.conf           # Project-specific config (test cmd, dirs)
├── .github/
│   ├── copilot-instructions.md  # Copilot workspace instructions
│   ├── agents/             # Agent definitions (.agent.md)
│   ├── hooks/              # Copilot lifecycle hooks
│   ├── workflows/          # GitHub Actions CI
│   └── ISSUE_TEMPLATE/     # Structured issue template
├── .githooks/              # Git hook enforcement scripts
├── docs/                   # All project documentation
│   ├── decisions/          # Architecture Decision Records
│   └── api/                # API specifications
├── src/                    # Source code
└── tests/                  # Test files
```

## Using This Template

### For a new project

```bash
# Clone the template
git clone <template-repo-url> my-new-project
cd my-new-project

# Invoke the Orchestrate agent to start your first issue
# In VS Code Copilot Chat: @orchestrate
```

For local development with git hook enforcement, run `git config core.hooksPath .githooks` once after cloning. This is not required for GitHub-native (cloud agent) mode.

### Configuration

`workflow.conf` is auto-configured on first use. The `@orchestrate` agent detects your project's test runner from standard marker files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.) and writes the detected value back to `workflow.conf`. You only need to edit it manually if auto-detection doesn't match your setup.

### Agents

| Agent | Purpose |
|-------|---------|
| Issue | GitHub-native intake. Creates or normalizes issue structure, runs research and planning, prepares `status/ready`. |
| Orchestrate | Entry point. Creates GitHub Issues, manages workflow, delegates to agents, enforces approval gates. |
| Research | Investigates one angle of a problem. Runs 2-4 in parallel. |
| Develop | Implements code via strict Red-Green-Refactor cycle. |
| Documentation | Maintains `docs/` directory. |
| Review | Pre-merge validation. Read-only. |

## Documentation

All project documentation lives in `docs/`. This README provides only the overview and setup steps.

- [`docs/auto/agent-flow.md`](docs/auto/agent-flow.md) — Complete workflow specification, state machine, and agent reference
- [`docs/auto/copilot-cloud-setup.md`](docs/auto/copilot-cloud-setup.md) — Setup guide for GitHub Copilot cloud agent (language tooling, copilot-setup-steps.yml)

## Repository Guardrails

Setup is automatic. The `Repo Setup` workflow runs on every push to `main` and:

1. Creates/syncs all status and type labels from `.github/labels.yml`.
2. Applies branch protection rules to `main` (required checks, PR reviews, no force-push).

No secrets or manual steps are required. To re-run manually: GitHub Actions → `Repo Setup` → `Run workflow`.
