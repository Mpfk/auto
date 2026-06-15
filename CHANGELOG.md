# Changelog

All notable changes to Auto will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-06-15

GitHub Actions cost savings: fewer metered minutes and reduced event fan-out.

### Added

- `bin/publish-template` — local maintainer tool that builds the consumer-form template snapshot (rewrites `pr-checks.yml` to the `@v1` caller, drops the hosted reusable workflow and dev-only files, adds `src/`/`tests/` placeholders) and pushes it to `Mpfk/auto-template`. Documented as release step 7. Deliberately not a CI workflow — that would require a PAT or cron.
- `pr-checks.yml`: `paths-ignore` for `docs/**` and `CHANGELOG.md` — CI is skipped for documentation-only PRs; GitHub marks the skipped check as passing for required-status-check purposes.
- `issue-native-automation.yml`: concurrency group keyed on issue number with `cancel-in-progress: true` — rapid label changes or repeated `/auto` comments no longer stack parallel runs (mirrors the pattern already in `issue-state-guard.yml`).
- `repo-setup.yml`: push trigger restricted to `paths: ['.github/labels.yml']` — label sync only runs when label configuration actually changes.

### Removed

- Informational `createComment` calls from `ci-issue-gate.yml` (CI-failure and CI-pass comments) and `issue-native-automation.yml` ("Issue is ready", "Implementation kickoff", "Gate 1 approved" comments). Each comment was itself an issue event that cascaded back into `issue-state-guard.yml`; the information is directly observable through CI check status, labels, and branch existence. Error-guard comments (misconfiguration signals) are retained.

## [0.3.0] - 2026-06-14

Native-GitHub-only distribution. Auto is now adopted with one click ("Use this
template") and updated through native GitHub primitives — no custom sync engine,
no scheduled job, and no personal access token.

### Added

- Reusable CI workflow `reusable-pr-checks.yml` (`on: workflow_call`) holding the test/commit-lint/policy logic. Consumer repos reference it by major tag (`uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1`) and receive updates automatically with the default `GITHUB_TOKEN`. This repo dogfoods the pattern via a local `./` caller.
- README "Getting started": Use this template → edit `workflow.conf` → `bin/setup-hooks`. No tokens.

### Changed

- `pr-checks.yml` is now a thin caller of `reusable-pr-checks.yml` (keeps the load-bearing "PR Checks" status name for `ci-issue-gate`).
- Instruction files (`.claude/` commands, `.github/agents`, `CLAUDE.md`, hooks, docs) are an explicit one-time snapshot from the template; there is no auto-update mechanism for them.
- Rewrote distribution docs for the native model: `auto-template-repo.md`, `file-buckets.md` (snapshot / reusable-workflow / config buckets), `release-process.md` (move the `v1` tag on release), `UPGRADING.md`, `hook-extension.md`.

### Removed

- The entire custom sync engine: `bin/auto-sync`, the weekly `auto-sync.yml` cron workflow, the `.auto-framework-paths` allow-list, and the `.autosyncignore` ignore-list.
- The `AUTO_SYNC_TOKEN` opt-in PAT — no token setup is required anywhere.
- `docs/auto/template-propagation.md` and the orphaned sync tests (`tests/test-auto-sync.sh`, `tests/test-autosyncignore.sh`, `tests/test-framework-paths.sh`).

## [0.2.0] - 2026-06-14

First properly signed release. Supersedes the unsigned `v0.1.0` pilot tag.

### Added

- Template propagation system: consumer repos receive framework updates as reviewed PRs (`bin/auto-sync`, weekly `auto-sync.yml`).
- Ownership contracts: `.auto-framework-paths` (always-sync allow-list) and `.autosyncignore` (never-overwrite consumer files).
- Two-repo topology: `Mpfk/auto` (framework source) and `Mpfk/auto-template` (the template consumers instantiate).
- Semantic versioning artefacts: `CHANGELOG.md`, `.auto-version` stamp, and the signed-tag release process (`docs/auto/release-process.md`, `docs/auto/UPGRADING.md`).
- `bin/setup-hooks` — idempotent git-hook activation that works correctly inside git worktrees.
- Documentation: `docs/auto/template-propagation.md`, `docs/auto/file-buckets.md`, `docs/auto/auto-template-repo.md`, `docs/auto/hook-extension.md`, `docs/auto/pilot-results.md`.

### Changed

- Rewrote `README.md` to be clearer and user-facing — leads with how the workflow works, with a horizontal pipeline diagram.
- `pr-issue-sync` now derives the linked issue's status from the PR's draft state (`status/in-progress` for drafts, `status/review` for ready PRs).
- `bin/auto-sync` emits a clear error when no upstream `v*` tag exists; documented template snapshot lag and the branch-guard first-run behavior.

### Fixed

- CI `policy` gate no longer races the `pr-issue-sync` label update — ready PRs pass on the first run without a manual label swap.
- Git hooks now fire inside worktrees (relative `core.hooksPath` resolves per working tree).

### Removed

- `release-mirror.yml` and the `MIRROR_TOKEN` cross-repo PAT requirement — `auto-template` now self-updates via its own `auto-sync.yml` using `GITHUB_TOKEN` only (no secrets to manage).

## [0.1.0] - 2024-01-01

### Added

- Initial Auto workflow framework as a reusable template repository.
- Multi-agent workflow specification with GitHub Issues, two human approval gates (Gate 1 and Gate 2), and Conventional Commits enforcement.
- Slash commands: `/issue`, `/auto`, `/develop`, `/review`, `/document`, `/research`.
- Git hooks (`.githooks/`): branch guard, doc placement, TDD cycle enforcement, commit-msg formatter, pre-push test gate.
- `workflow.conf` for project-specific configuration (`TEST_CMD`, `SRC_DIRS`, `TEST_DIRS`, `MAIN_BRANCH`).
- GitHub Actions workflow definitions for cloud-native mode.
- Copilot agent definitions (`.github/agents/`) for GitHub-native orchestration.
- Documentation: `docs/auto/agent-flow.md`, `docs/auto/github-access.md`, `docs/auto/copilot-cloud-setup.md`.

[Unreleased]: https://github.com/Mpfk/auto/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/Mpfk/auto/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/Mpfk/auto/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Mpfk/auto/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Mpfk/auto/releases/tag/v0.1.0
