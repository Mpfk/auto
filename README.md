# Auto — Multi-Agent Software Development Template

A reusable project template that enforces structured software development through specialized GitHub Copilot agents, test-driven development, GitHub Issues for project management, and automated git hooks + GitHub Actions.

## Quick Start

1. Clone this template into your new project
2. Run `git config core.hooksPath .githooks`
3. Edit `workflow.conf` to match your project's test runner and directory layout
4. Start working by invoking the Orchestrator agent: `@orchestrator`

## How It Works

The Orchestrator agent manages the full development lifecycle:

1. You describe what you need (feature, bug fix, refactor)
2. The Orchestrator creates a GitHub Issue, spawns Research Agents in parallel, synthesizes findings, and writes a plan
3. You approve the plan (Gate 1)
4. TDD and Documentation Agents implement the work on a feature branch
5. The Review Agent validates everything
6. You approve the merge (Gate 2)

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

# Configure git hooks
git config core.hooksPath .githooks

# Customize for your project
# Edit workflow.conf — set your test command and directory layout
# Edit README.md — replace this content with your project's overview
```

### Configuration

Edit `workflow.conf` to match your project:

```bash
TEST_CMD="pytest"           # Your test runner
SRC_DIRS="src/ lib/"        # Where source code lives
TEST_DIRS="tests/ test/"    # Where tests live
```

### Agents

| Agent | Purpose |
|-------|---------|
| Orchestrator | Entry point. Creates GitHub Issues, manages workflow, delegates to agents, enforces approval gates. |
| Research | Investigates one angle of a problem. Runs 2-4 in parallel. |
| TDD | Implements code via strict Red-Green-Refactor cycle. |
| Documentation | Maintains `docs/` directory. |
| Review | Pre-merge validation. Read-only. |

## Documentation

All project documentation lives in `docs/`. This README provides only the overview and setup steps.

- [`docs/auto/agent-flow.md`](docs/auto/agent-flow.md) — Complete workflow specification, state machine, and agent reference
- [`docs/auto/copilot-cloud-setup.md`](docs/auto/copilot-cloud-setup.md) — Setup guide for GitHub Copilot cloud agent (GH_TOKEN, copilot environment, copilot-setup-steps.yml)
