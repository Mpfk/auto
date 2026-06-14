# Changelog

All notable changes to Auto will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/Mpfk/auto/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Mpfk/auto/releases/tag/v0.1.0
