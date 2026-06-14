# Auto Template Repository

Auto is distributed through two repositories:

| Repo | Role |
|------|------|
| **[`Mpfk/auto`](https://github.com/Mpfk/auto)** | The **framework source**. This is where Auto is developed: slash commands, hooks, agents, docs, and the reusable CI workflow all live here and evolve here. It also hosts the release tags (`vX.Y.Z` and the floating `v1`) that consumers reference. |
| **[`Mpfk/auto-template`](https://github.com/Mpfk/auto-template)** | The **clean template** consumers instantiate. It is a GitHub template repository — a tidied copy of the framework source with framework-internal test files and dev/design docs stripped out, ready for "Use this template". |

Consumers never clone `Mpfk/auto` directly. They click **"Use this template"** on
`Mpfk/auto-template` (or run `gh repo create --template Mpfk/auto-template`),
which produces a brand-new repository seeded with the Auto workflow scaffolding.

## What "Use this template" gives you

"Use this template" performs a **one-time snapshot copy** of the template repo's
contents into your new repository. You get:

- **Slash commands** — `.claude/commands/*.md`
- **Git hooks** — `.githooks/` dispatchers, enforcement rules, and shared lib
- **Copilot agents** — `.github/agents/*.agent.md`
- **GitHub config** — copilot instructions, issue template, PR template, labels
- **Event-automation workflows** — the GitHub Actions that drive the workflow
  state machine (issue automation, label sync, state guard, etc.)
- **A thin CI caller** — `.github/workflows/pr-checks.yml`, which references
  Auto's reusable PR-checks workflow by tag (see [Updates](#how-updates-work))
- **Framework docs** — the consumer-facing docs under `docs/auto/`
- **`workflow.conf`** — the one file you must edit
- **`CLAUDE.md`**, **`README.md`**, **`.gitignore`** — starter files you own

There are **no tokens, no PATs, and no secrets** to configure — not now, not
ever. Auto runs entirely on GitHub's default `GITHUB_TOKEN`.

## Getting started

After creating your repo from the template:

```bash
gh repo create my-project --template Mpfk/auto-template --public --clone
cd my-project

# 1. Edit workflow.conf — set TEST_CMD for your language/framework
#    (SRC_DIRS, TEST_DIRS, and MAIN_BRANCH are auto-detected; override if needed)

# 2. Activate git hooks (required once per clone and once per worktree)
bin/setup-hooks

# 3. Create your first issue and start the workflow
#    /issue "your first task"   (or /auto for the fully autonomous flow)
```

Editing `workflow.conf` is the **only required setup step**. Everything else
works out of the box.

> The GitHub UI path is identical: click **"Use this template"** on
> [github.com/Mpfk/auto-template](https://github.com/Mpfk/auto-template), clone
> the result, then run steps 1–3 above.

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

## How updates work

Auto distinguishes two kinds of content, and they update differently.

### Instruction files — a snapshot, updated manually

The slash commands, agents, hooks, `CLAUDE.md`, and docs you received are a
**point-in-time snapshot** taken when you clicked "Use this template". There is
**no mechanism that auto-updates them** — by design. They are yours to edit, and
nothing upstream will ever overwrite your local changes.

If you want a newer version of the instruction files, you re-copy the files you
care about from `Mpfk/auto-template` by hand (via `git`, the GitHub UI, or a
plain download). See [`UPGRADING.md`](UPGRADING.md) for the recommended
procedure. Accepting this manual step is a deliberate trade-off: it keeps the
distribution model dead simple and token-free.

### CI logic — updates automatically via the reusable workflow

The actual PR-checks logic does **not** live in your repo. Your
`.github/workflows/pr-checks.yml` is a thin caller that references Auto's
reusable workflow by major tag:

```yaml
name: PR Checks
on:
  pull_request:
    branches: [main]
jobs:
  checks:
    uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1
    permissions:
      contents: read
      issues: read
      pull-requests: read
```

Because you pin the floating major tag `@v1`, whenever Auto cuts a new release
and moves the `v1` tag forward, your repo picks up the updated CI logic
**automatically, for free, on the next PR** — using only the default
`GITHUB_TOKEN`. You take no action and configure no secrets.

A breaking change to the CI contract ships as a new major (`v2`); you opt in
when you're ready by bumping the `uses:` ref. See [`UPGRADING.md`](UPGRADING.md).

> Auto's own repo (`Mpfk/auto`) dogfoods this exact pattern. Its `pr-checks.yml`
> is a thin caller pointing at a **local** `./.github/workflows/reusable-pr-checks.yml`
> reference, so the framework validates itself with the same logic consumers run.
