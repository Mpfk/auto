# Auto Template Repository

The **`Mpfk/auto-template`** repository at
[github.com/Mpfk/auto-template](https://github.com/Mpfk/auto-template) is a
GitHub **template repository** that consumers instantiate via the "Use this
template" button (or `gh repo create --template Mpfk/auto-template`). It is the
canonical starting point for any new project using the Auto workflow framework.

## What it contains

The template ships exactly the files a new consumer needs:

### Framework files (Auto-owned, never edit)

All paths listed in `.auto-framework-paths` at the time of the last release:

- **Slash commands** — `.claude/commands/*.md`
- **Git hooks** — `.githooks/` dispatchers, enforcement rules, and shared lib
- **GitHub Actions** — all CI workflows under `.github/workflows/`
- **Copilot agents** — `.github/agents/*.agent.md`
- **GitHub config** — copilot instructions, issue template, PR template, labels
- **Sync tooling** — `bin/auto-sync`, `.autosyncignore`, `.auto-framework-paths`
- **Framework docs** — `docs/auto/agent-flow.md`, `docs/auto/github-access.md`,
  `docs/auto/copilot-cloud-setup.md`, `docs/auto/hook-extension.md`,
  `docs/auto/UPGRADING.md`
- **Version stamp** — `.auto-version`

### Config seeds (consumer edits after setup)

Files that Auto seeds once and the consumer then owns:

- `workflow.conf` — seeded with `TEST_CMD=""` (auto-detect); consumer sets their
  own test command, source dirs, and test dirs
- `.claude/settings.json` — baseline allow-list for Claude Code hooks
- `CLAUDE.md` — framework instructions; consumer adds project-specific rules
- `README.md` — starter README; consumer replaces body with their project
- `.gitignore` — common ignores; consumer adds project-specific entries

### Consumer placeholder stubs

- `src/.gitkeep` — marks where consumer source code goes
- `tests/.gitkeep` — marks where consumer tests go
- `docs/api/.gitkeep` — marks consumer API docs directory
- `docs/decisions/.gitkeep` — marks consumer ADR directory

## What it does NOT contain

Intentionally excluded from the template:

- **Framework test files** (`tests/test-*.sh`, `tests/workflow-config.sh`) —
  these test Auto's own internals and do not belong in consumer repos
- **Dev/design docs** (`docs/auto/file-buckets.md`,
  `docs/auto/template-propagation.md`, `docs/auto/release-process.md`) — RFCs
  and architecture documents for framework authors, not consumers
- **Release tooling** — changelog generation, release scripts, and similar
  automation are internal to the Auto source repo

## How it stays current

No secrets required. `auto-template` self-updates via its own `auto-sync.yml`
workflow, which runs on a weekly schedule and pulls from the public `Mpfk/auto`
repo using its own `GITHUB_TOKEN`. On each run it:

1. Checks for a new release tag on `Mpfk/auto` (via `bin/auto-sync`).
2. Copies every framework file listed in `.auto-framework-paths` to
   `Mpfk/auto-template` (overwriting previous content).
3. Stamps `.auto-version` with the new version.
4. Opens a PR for review and merge.

You can also trigger the sync manually from the Actions tab (Run workflow) to
pull a new release immediately rather than waiting for the next weekly run.

The template always reflects the latest stable release of the framework.

## Snapshot lag

> **Newly created repos should run `bin/auto-sync` once after setup.**

`Mpfk/auto-template` is a **point-in-time snapshot** of the Auto source repo at
the moment of the most recent release. GitHub template instantiation copies
exactly what is in the template repo at that instant.

This means any framework files added to `Mpfk/auto` **after** the last release
(but before the next one) will not appear in freshly instantiated consumer repos.
They will arrive on the consumer's first `bin/auto-sync` run once a new release
tag is cut.

**Recommended first step after setup:**

```bash
bin/auto-sync --skip-verify   # or without --skip-verify for GPG-verified sync
```

This ensures the consumer starts from the most current stable release rather
than the snapshot captured when the template was last updated.

## First commit — branch guard

> **New consumer repos must commit to a branch, not `main`.**

The `.githooks/pre-commit.d/010-branch-guard.sh` hook blocks direct commits to
`main`. This is correct and intentional for ongoing development, but it fires on
the very first commit too.

Before making your first commit, create an issue branch:

```bash
git checkout -b issue/1
git commit -m "chore: initial project setup"
```

Then open a pull request to merge into `main`. This is the standard Auto
workflow: all changes flow through `issue/N` branches. See `CLAUDE.md` for the
full workflow guide.

## Using the template

```bash
# GitHub UI: click "Use this template" on github.com/Mpfk/auto-template
# or via CLI:
gh repo create my-project --template Mpfk/auto-template --public --clone
cd my-project

# Activate git hooks
git config core.hooksPath .githooks

# Run an initial sync to catch any post-snapshot framework additions
bin/auto-sync --skip-verify

# Customise for your project
# Edit workflow.conf — set TEST_CMD for your language/framework
# Edit CLAUDE.md — add project-specific conventions below the framework block
```

Enable the `auto-sync` workflow in repo Settings → Actions to receive future
framework updates automatically.
