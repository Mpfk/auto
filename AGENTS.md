# Auto repository guidance

Auto is an issue-driven software-development workflow. Before changing code, read
`docs/auto/playbooks/core.md` and the playbook for the requested phase. Use
`docs/auto/playbooks/github.md` whenever GitHub state is involved.

## Always-on rules

- Work from a GitHub issue and an `issue/{number}` branch. A host-managed cloud
  branch is allowed only when the host enforces it; link the issue from the PR.
- Never commit directly to `main`.
- Use Red-Green-Refactor: commit failing tests before implementation.
- Use Conventional Commits: `type(scope): description`.
- Keep project documentation in `docs/`. Root `README.md`, `CLAUDE.md`,
  `AGENTS.md`, and `CHANGELOG.md`, plus provider configuration under
  `.claude/`, `.github/`, and `.agents/`, are allowed exceptions.
- Gate 1 requires a researched plan and acceptance criteria. Gate 2 requires a
  mergeable PR, green CI, and a current-head passing review record.
- An ordinary implementation request uses interactive Gate 1 and Gate 2.
  Self-approve gates only when `$auto` is explicitly invoked or the user clearly
  requests hands-off completion or merge.

## Setup and tests

Run `bin/setup-hooks` after cloning and in every worktree. The full configured
test command is `TEST_CMD` in `workflow.conf`; when it is empty, use the
detection rules in `.githooks/lib/detect.sh`. Framework maintainers should also
run every executable `tests/*.sh` file and validate repository skills with the
Codex skill validator.

## Code Review Rules

- Review the PR's current head, not an earlier revision.
- Run `bin/auto-review-preflight` and require a PASS result.
- For Codex-driven PRs, request native review with `@codex review`. A native
  review passes only after it completes for the current head with no unresolved
  P0 or P1 findings.
- If native review is unavailable, errors, or does not finish within five
  minutes, run the local `$review` workflow and record provider `codex-local`.
- Record evidence on the issue using the schema in
  `docs/auto/playbooks/review.md`. Gate 2 rejects missing, failing, or stale
  evidence.
- Treat correctness, security, regressions, missing tests, failed checks,
  Conventional Commit violations, TDD ordering, and misplaced documentation as
  blocking. Avoid blocking on personal style preferences.

