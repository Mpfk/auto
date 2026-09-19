# OpenAI Codex setup

Auto works natively with Codex desktop, CLI, IDE, and cloud through repository
instructions and skills. It does not require `.codex/config.toml`, a Codex
plugin, an OpenAI API key, or an enabled GitHub Action.

Codex automatically reads root `AGENTS.md` and discovers the seven workflows
under `.agents/skills/`:

- `$auto` — autonomous issue-to-merge progression
- `$issue` — issue intake, research, planning, and Gate 1
- `$develop` — one Red-Green-Refactor implementation cycle
- `$document` — documentation for completed work
- `$research` — one evidence-gathering strategy
- `$review` — deterministic preflight plus semantic review
- `$merge` — Gate 2, merge, and verification

The skills load provider-neutral contracts from `docs/auto/playbooks/`, so
Codex, Claude Code, and Copilot follow the same state transitions and gates.

## Local setup

1. Run `bin/setup-hooks` after cloning and in every worktree.
2. Check `workflow.conf`, especially `TEST_CMD`, `SRC_DIRS`, and `TEST_DIRS`.
3. Authenticate the GitHub CLI with `gh auth login`, or connect a host-provided
   GitHub integration with issue, PR, review, checks, and branch access.
4. Start with `$issue Describe the change`, or explicitly use `$auto Describe
   the change` for hands-off completion.

An ordinary implementation request keeps Gate 1 and Gate 2 interactive. Only an
explicit `$auto` invocation or clear hands-off completion/merge request grants
self-approval authority.

## Native GitHub review

For Codex-driven PRs, `$review` requests `@codex review`. Auto waits at most five
minutes and requires a completed review for the current head with no unresolved
P0/P1 findings. If native review is unavailable, errors, or times out, `$review`
runs locally and records provider `codex-local`.

Every review also runs `bin/auto-review-preflight`, which preserves the broader
Gate 2 checks: current head, CI, Conventional Commits, TDD order, documentation
placement, and the configured tests. See
[Review GitHub pull requests with Codex](https://learn.chatgpt.com/docs/third-party/github),
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), and
[skills](https://learn.chatgpt.com/docs/build-skills).

