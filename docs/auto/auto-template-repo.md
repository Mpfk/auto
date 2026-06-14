# Auto Template Repository

Auto is distributed through two repositories:

| Repo | Role |
|------|------|
| **[`Mpfk/auto`](https://github.com/Mpfk/auto)** | Framework source — slash commands, hooks, agents, docs, and the reusable CI workflow are developed and versioned here. Hosts release tags (`vX.Y.Z` and floating `v1`). |
| **[`Mpfk/auto-template`](https://github.com/Mpfk/auto-template)** | The clean template consumers instantiate. A tidied copy with framework-internal test files stripped out, ready for "Use this template". |

Consumers never clone `Mpfk/auto` directly. They click **"Use this template"** on `Mpfk/auto-template` (or run `gh repo create --template Mpfk/auto-template`).

## What "Use this template" gives you

A one-time snapshot copy of the template into your new repository:

- **Slash commands** — `.claude/commands/*.md`
- **Git hooks** — `.githooks/` enforcement rules and shared lib
- **Copilot agents** — `.github/agents/*.agent.md`
- **GitHub config** — copilot instructions, issue template, PR template, labels
- **Event-automation workflows** — GitHub Actions that drive the state machine
- **A thin CI caller** — `.github/workflows/pr-checks.yml`, referencing Auto's reusable workflow by tag
- **Framework docs** — `docs/auto/`
- **`workflow.conf`** — the one file you must edit
- **`CLAUDE.md`**, **`README.md`**, **`.gitignore`** — starter files you own

**No tokens, no PATs, no secrets** — Auto runs entirely on GitHub's default `GITHUB_TOKEN`.

## Getting started

```bash
gh repo create my-project --template Mpfk/auto-template --public --clone
cd my-project

# 1. Edit workflow.conf — set TEST_CMD for your language
# 2. Activate git hooks (required once per clone and once per worktree)
bin/setup-hooks
# 3. Start the workflow
# /issue "your first task"   (or /auto for fully autonomous)
```

> **First commit:** the branch guard hook blocks direct commits to `main`. Create an `issue/1` branch before your first commit, then open a PR to merge it.

## How updates work

Auto distinguishes two kinds of content:

### Instruction files — snapshot, updated manually

Slash commands, agents, hooks, `CLAUDE.md`, and docs are a **point-in-time snapshot**. Nothing upstream overwrites them. To pick up a newer version, re-copy the files you want from `Mpfk/auto-template`. See [`UPGRADING.md`](UPGRADING.md).

### CI logic — updates automatically

Your `pr-checks.yml` is a thin caller referencing Auto's reusable workflow by major tag:

```yaml
jobs:
  checks:
    uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1
    permissions:
      contents: read
      issues: read
      pull-requests: read
```

When Auto cuts a release and moves the `v1` tag, your repo picks up the updated CI on its next PR — no action, no secrets, no tokens needed. A breaking change ships as `v2`; you opt in by bumping the `uses:` ref. See [`UPGRADING.md`](UPGRADING.md).
