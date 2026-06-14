# Auto Framework — File Bucket Classification

This document classifies every path in a consumer's Auto repo by **how it is
distributed and how it updates**. Auto's distribution model is native to GitHub:
files arrive once via "Use this template" (a snapshot), and CI logic is pulled
from upstream via a reusable-workflow reference. There is no custom sync engine,
allow-list, or ignore-list — the buckets below describe ownership and update
behavior, not the behavior of any propagation tool.

## The Three Buckets

| Bucket | How it arrives | How it updates |
|--------|----------------|----------------|
| **Snapshot** | Copied once by "Use this template" | Consumer owns it; update by manual re-copy if desired |
| **Reusable-workflow logic** | Referenced from upstream by `@v1`, not copied | Updates automatically when Auto moves the `v1` tag |
| **Config** | Seeded by the template | Consumer edits; never touched again |

## Snapshot files — copied once, consumer owns thereafter

These are copied verbatim into your repo at template-instantiation time. After
that they are **yours**: nothing upstream overwrites them, and you may edit them
freely. To pick up newer upstream versions you re-copy by hand (see
[`UPGRADING.md`](UPGRADING.md)).

| Path | Notes |
|------|-------|
| `.claude/commands/auto.md` | Core slash command |
| `.claude/commands/develop.md` | Core slash command |
| `.claude/commands/document.md` | Core slash command |
| `.claude/commands/issue.md` | Core slash command |
| `.claude/commands/merge.md` | Core slash command |
| `.claude/commands/research.md` | Core slash command |
| `.claude/commands/review.md` | Core slash command |
| `.githooks/commit-msg` | Hook dispatcher |
| `.githooks/commit-msg.d/010-conventional-commits.sh` | Enforcement rule |
| `.githooks/commit-msg.d/020-issue-linkage.sh` | Enforcement rule |
| `.githooks/lib/detect.sh` | Shared hook library |
| `.githooks/post-commit` | Hook dispatcher |
| `.githooks/pre-commit` | Hook dispatcher |
| `.githooks/pre-commit.d/010-branch-guard.sh` | Enforcement rule |
| `.githooks/pre-commit.d/020-doc-placement-guard.sh` | Enforcement rule |
| `.githooks/pre-commit.d/030-tdd-cycle-guard.sh` | Enforcement rule |
| `.githooks/pre-push` | Hook dispatcher |
| `.githooks/pre-push.d/010-issue-status-consistency.sh` | Enforcement rule |
| `.githooks/pre-push.d/020-test-suite-gate.sh` | Enforcement rule |
| `.github/agents/develop.agent.md` | Copilot agent definition |
| `.github/agents/documentation.agent.md` | Copilot agent definition |
| `.github/agents/issue.agent.md` | Copilot agent definition |
| `.github/agents/merge.agent.md` | Copilot agent definition |
| `.github/agents/orchestrate.agent.md` | Copilot agent definition |
| `.github/agents/research.agent.md` | Copilot agent definition |
| `.github/agents/review.agent.md` | Copilot agent definition |
| `.github/copilot-instructions.md` | Copilot workspace instructions |
| `.github/hooks/doc-freshness.json` | Doc-freshness hook config |
| `.github/hooks/scripts/doc-freshness.sh` | Doc-freshness hook script |
| `.github/ISSUE_TEMPLATE/workflow-issue.yml` | Issue intake template |
| `.github/labels.yml` | Workflow status and type labels |
| `.github/pull_request_template.md` | PR checklist — enforces framework gates |
| `.github/workflows/pr-checks.yml` | **Thin caller** — references the reusable workflow (see next bucket) |
| `.github/workflows/issue-native-automation.yml` | Event-automation workflow |
| `.github/workflows/issue-state-guard.yml` | Event-automation: state machine enforcer |
| `.github/workflows/labels-sync.yml` | Event-automation: label management |
| `.github/workflows/pr-issue-sync.yml` | Event-automation: issue-PR linkage |
| `.github/workflows/repo-setup.yml` | Event-automation: repo bootstrap |
| `.github/workflows/copilot-setup-steps.yml` | CI setup for Copilot |
| `docs/auto/` (consumer-facing files) | Auto's consumer documentation |
| `CLAUDE.md` | Framework instructions + project instructions (see note below) |

## Reusable-workflow logic — referenced from upstream, auto-updates for free

The PR-checks logic is **not** snapshotted into your repo. Your thin
`pr-checks.yml` caller references it by major tag:

```yaml
jobs:
  checks:
    uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1
```

| Path | Where it lives | Update behavior |
|------|----------------|-----------------|
| `reusable-pr-checks.yml` | Upstream `Mpfk/auto`, referenced as `@v1` | When Auto moves the `v1` tag, your next PR runs the new logic automatically — no copy, no token |

A breaking change to the reusable-workflow interface ships as `v2`; you opt in
by editing the `uses:` ref. See [`UPGRADING.md`](UPGRADING.md).

## Config — seeded by the template, edited by the consumer

| Path | Notes |
|------|-------|
| `workflow.conf` | The one required edit. Set `TEST_CMD`; `SRC_DIRS`, `TEST_DIRS`, `MAIN_BRANCH` are auto-detected. Seeded with a commented template. |
| `.claude/settings.json` | Project-scoped Claude Code permissions and the doc-freshness hook. Seeded with a working baseline; add your own tool permissions as needed. |
| `README.md` | Seeded starter; replace the body with your project description. |
| `.gitignore` | Seeded common ignores; add project-specific entries. |
| `docs/.gitkeep`, `docs/api/.gitkeep`, `docs/decisions/.gitkeep` | Directory placeholders. |

## Consumer-owned — your application code

| Path | Notes |
|------|-------|
| `src/.gitkeep`, `tests/.gitkeep` | Placeholder stubs marking where your code and tests go; replace freely. |
| `src/**`, `tests/**` | Your implementation and tests — entirely yours. |
| `docs/**` outside the consumer-facing `docs/auto/` files | `docs/api/`, `docs/decisions/`, and any subdirectories you create are yours. |

## Decision Notes

### `CLAUDE.md` — a snapshot you own

`CLAUDE.md` is auto-loaded by Claude Code as project instructions, so it ships
with the framework's Non-Negotiable Rules and workflow reference. Under the
snapshot model it is copied once and then belongs to you: add project-specific
scopes, local overrides, and team conventions freely. Nothing upstream rewrites
it. If you want a newer framework block, re-copy the relevant section from the
template by hand.

### `.claude/settings.json` — seeded, then yours

The baseline permissions allow-list and doc-freshness hook ship so the workflow
works out of the box. After instantiation the file is yours; add project-specific
tool permissions. No automated process modifies it.

### `README.md` — yours after seeding

Consumers replace the template README with their project's description right
after setup. It is a snapshot file you own from day one.

### `.github/labels.yml` — framework-defined, consumer may extend

The workflow status labels (`status/*`) and type labels (`feature`, `bug`,
`refactor`, etc.) are load-bearing — the state machine and CI gates depend on
them. The `labels-sync.yml` event-automation workflow keeps these required
labels present in your repo on its own schedule; it does not remove labels you
add. You may define additional project labels alongside them.

### `docs/auto/` consumer-facing files vs `docs/**`

The consumer-facing files under `docs/auto/` document the framework you're using
and ship as snapshot files. All other subdirectories under `docs/` (`docs/api/`,
`docs/decisions/`, anything you create) are entirely yours.

## Hook number-range convention

Git hooks are snapshot files: Auto's built-in hook scripts arrive once and you
own them thereafter. To let you add your own hooks without ever colliding with a
re-copied framework hook, the `.d/` script number ranges are partitioned:

| Range | Owner |
|-------|-------|
| `000`–`099` | Auto framework |
| `100`+ | Consumer repo |

Auto's built-in scripts currently occupy `010`–`030`; the full `000`–`099` band
is reserved for future framework scripts. Add your own hooks at `100`+ so a
manual framework re-copy never clobbers them. See
[`hook-extension.md`](hook-extension.md) for the full convention.

## `src/` and `tests/` — placeholder stubs only

In a consumer repo, `src/` and `tests/` hold the consumer's application code and
tests. The template ships only `.gitkeep` placeholders in those directories —
just enough to preserve the directory structure in git and signal where your
code goes. Auto's own framework test files (which exercise framework internals)
live in `Mpfk/auto` and are stripped from the template, so they never clutter a
consumer's test suite.
