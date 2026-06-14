# Auto Framework — File Bucket Classification

This document is the authoritative classification of every path in the Auto
repository for the vendored sync mechanism (`auto-sync`). It determines how
`auto-sync` treats each file when propagating framework updates to consumer
repos.

## The Three Buckets

| Bucket | `auto-sync` behavior |
|--------|----------------------|
| **Framework** (Auto owns) | Overwrite on every sync update |
| **Config** (consumer owns, Auto seeds once) | Write if missing; never overwrite |
| **Consumer-owned** (not Auto's concern) | Auto never touches |

## Summary Classification Table

### Framework — Auto overwrites on every sync

| Path | Notes |
|------|-------|
| `.claude/commands/auto.md` | Core slash command — framework logic |
| `.claude/commands/develop.md` | Core slash command — framework logic |
| `.claude/commands/document.md` | Core slash command — framework logic |
| `.claude/commands/issue.md` | Core slash command — framework logic |
| `.claude/commands/merge.md` | Core slash command — framework logic |
| `.claude/commands/research.md` | Core slash command — framework logic |
| `.claude/commands/review.md` | Core slash command — framework logic |
| `.githooks/commit-msg` | Hook dispatcher — framework logic |
| `.githooks/commit-msg.d/010-conventional-commits.sh` | Framework enforcement rule |
| `.githooks/commit-msg.d/020-issue-linkage.sh` | Framework enforcement rule |
| `.githooks/lib/detect.sh` | Shared hook library — framework logic |
| `.githooks/post-commit` | Hook dispatcher — framework logic |
| `.githooks/pre-commit` | Hook dispatcher — framework logic |
| `.githooks/pre-commit.d/010-branch-guard.sh` | Framework enforcement rule |
| `.githooks/pre-commit.d/020-doc-placement-guard.sh` | Framework enforcement rule |
| `.githooks/pre-commit.d/030-tdd-cycle-guard.sh` | Framework enforcement rule |
| `.githooks/pre-push` | Hook dispatcher — framework logic |
| `.githooks/pre-push.d/010-issue-status-consistency.sh` | Framework enforcement rule |
| `.githooks/pre-push.d/020-test-suite-gate.sh` | Framework enforcement rule |
| `.github/agents/develop.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/documentation.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/issue.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/merge.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/orchestrate.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/research.agent.md` | Copilot agent definition — framework logic |
| `.github/agents/review.agent.md` | Copilot agent definition — framework logic |
| `.github/copilot-instructions.md` | Copilot workspace instructions — framework logic |
| `.github/hooks/doc-freshness.json` | Doc-freshness hook config — framework logic |
| `.github/hooks/scripts/doc-freshness.sh` | Doc-freshness hook script — framework logic |
| `.github/ISSUE_TEMPLATE/workflow-issue.yml` | Issue intake template — framework logic |
| `.github/labels.yml` | Workflow status and type labels — framework-defined |
| `.github/pull_request_template.md` | PR checklist — enforces framework gates |
| `.github/workflows/ci-issue-gate.yml` | Framework CI gate |
| `.github/workflows/copilot-setup-steps.yml` | Framework CI setup for Copilot |
| `.github/workflows/issue-native-automation.yml` | Framework automation |
| `.github/workflows/issue-state-guard.yml` | Framework state machine enforcer |
| `.github/workflows/labels-sync.yml` | Framework label management |
| `.github/workflows/pr-checks.yml` | Framework PR validation |
| `.github/workflows/pr-issue-sync.yml` | Framework issue-PR linkage |
| `.github/workflows/repo-setup.yml` | Framework repo bootstrap |
| `docs/auto/` (all files) | Auto's own documentation — framework-owned |
| `CHANGELOG.md` | Framework release history (will exist after #85) |
| `.auto-version` | Framework version pin (will exist after #85) |
| `bin/auto-sync` | Sync binary itself (will exist after #91) |
| `.autosyncignore` | Sync ignore rules (will exist after #88) |

### Config — Auto seeds once, consumer owns thereafter

| Path | Notes |
|------|-------|
| `workflow.conf` | Consumer sets TEST_CMD, SRC_DIRS, TEST_DIRS, MAIN_BRANCH. Auto writes a commented template on first install; consumer must be free to edit without having their changes wiped. |
| `.claude/settings.json` | Contains project-scoped permissions and hooks. Auto seeds the baseline allow-list so hooks work out of the box. Consumer may add project-specific tool permissions; those additions must survive sync. |
| `CLAUDE.md` | Contains framework instructions (Non-Negotiable Rules, workflow status flow, slash command reference, sub-agent guidance) alongside the project-instructions role. See note below. |
| `README.md` | Auto seeds a template README with Quick Start, project structure, and agent reference. Consumer is expected to replace the body with their own project description. |
| `.gitignore` | Auto seeds common ignores (OS files, language dependency directories). Consumer will add project-specific entries. |
| `docs/.gitkeep` | Placeholder that ensures the docs/ directory exists in the template. |
| `docs/api/.gitkeep` | Placeholder for consumer API docs. |
| `docs/decisions/.gitkeep` | Placeholder for consumer ADRs. |

### Consumer-owned — Auto never touches

| Path | Notes |
|------|-------|
| `src/.gitkeep` | Replaced entirely by consumer source code (see decision below). |
| `tests/.gitkeep` | Replaced entirely by consumer tests (see decision below). |
| `src/**` (all consumer files) | Consumer's implementation code — not Auto's concern. |
| `tests/**` (all consumer files) | Consumer's test files — not Auto's concern. |
| `docs/**` (consumer docs outside `docs/auto/`) | `docs/api/`, `docs/decisions/`, and any other subdirectories the consumer creates are theirs. |

## Decision Notes

### `CLAUDE.md` — seeded, not blindly overwritten

`CLAUDE.md` occupies an unusual position: it is auto-loaded by Claude Code as
project instructions, so it must contain the framework's Non-Negotiable Rules
and workflow reference. But a consumer will also accumulate project-specific
additions over time (custom scopes, local tool overrides, team conventions).

**Decision: Config bucket.** Auto seeds a complete `CLAUDE.md` on first install.
On subsequent syncs, `auto-sync` does _not_ overwrite `CLAUDE.md` wholesale.
Instead, it maintains a clearly delimited `<!-- auto:framework-block -->` region
that it can update surgically, leaving the consumer's additions untouched. The
exact merge strategy is specified in the `auto-sync` design (issue #91).

### `.claude/settings.json` — seeded, additive updates only

The baseline allow-list and doc-freshness hook must be present for the workflow
hooks to work. But consumers add project-specific tool permissions.

**Decision: Config bucket.** Auto seeds the file on first install. On subsequent
syncs, `auto-sync` merges the `permissions.allow` array additively (adds missing
entries, never removes consumer additions) and overwrites the `hooks` block
(which is purely framework-owned).

### `README.md` — consumer's own after seeding

Consumers replace the template README with their project's description
immediately after setup. There is no reliable way for `auto-sync` to distinguish
its own template content from the consumer's prose.

**Decision: Config bucket (seed-once).** After first install the file belongs
entirely to the consumer.

### `docs/auto/` vs `docs/**`

`docs/auto/` is Auto's own documentation and must stay in sync with the
framework version. All other subdirectories under `docs/` are the consumer's.

**Decision: `docs/auto/` is Framework; all other `docs/**` is Consumer-owned.**

### `.github/labels.yml` — framework-defined, but consumer may extend

The workflow status labels (`status/*`) and type labels (`feature`, `bug`,
`refactor`, etc.) are load-bearing — the state machine and CI gates depend on
them. Consumers may add their own project labels.

**Decision: Framework bucket, but `auto-sync` merges additively.** It ensures
the required labels are present; it does not remove labels the consumer added.

## `src/` and `tests/` — Explicit Decision

### Current state in the template

The template currently contains:

- `src/.gitkeep` — an empty placeholder
- `tests/.gitkeep` — an empty placeholder
- `tests/workflow-config.sh` — a static-assertion test that validates the
  framework's own GitHub Actions workflows

### Decision: ship as minimal placeholder stubs; remove the framework's own test file from the template

In a consumer repo, `src/` and `tests/` are where the consumer's application
code and tests live. Shipping the framework's own test file
(`tests/workflow-config.sh`) into a consumer repo would be confusing and
incorrect: it tests framework internals that belong in the Auto repo itself,
not in every project that uses Auto.

**Ruling:**

1. `src/.gitkeep` — keep in the template. A single `.gitkeep` preserves the
   directory in git, signals to the consumer where their source code goes, and
   is trivially replaced.

2. `tests/.gitkeep` — keep in the template for the same reason.

3. `tests/workflow-config.sh` — **remove from the template** (or move to the
   Auto repo's own test harness, outside the files synced to consumers). It
   tests Auto's CI wiring, not consumer code. Shipping it creates a confusing
   test file in the consumer's test suite that they must manually delete.

4. `auto-sync` classification: both `src/` and `tests/` are **Consumer-owned**.
   `auto-sync` seeds only the `.gitkeep` files on first install (to ensure the
   directories exist) and never touches them again.

### Rationale

The Auto template's value proposition is that it provides the workflow
scaffolding (hooks, agents, CI, docs) while staying out of the way of the
consumer's actual work. Shipping framework-specific test code into consumer
repos violates that boundary. The `.gitkeep` stubs are the right minimum:
they document the intended directory structure without prescribing content.
