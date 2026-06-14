# Auto — Template Propagation

This document describes how Auto framework updates flow from the **Auto source
repo** to **consumer repos** that have installed the framework.

## Propagation mechanism

Consumer repos include `.github/workflows/auto-sync.yml` (a framework-owned
file, propagated by sync itself). This workflow drives the sync automatically:

- **Scheduled:** runs every **Monday at 09:00 UTC** (`cron: '0 9 * * 1'`).
- **Manual:** can be triggered at any time from the GitHub Actions tab via
  `workflow_dispatch`.

When the workflow runs it calls `bin/auto-sync --skip-verify`. If upstream is
ahead, the script updates local framework files and the workflow opens a PR
(`chore: sync Auto framework to vX.Y.Z`) for review before merging. When
the consumer is already up to date the workflow exits cleanly without opening
a PR (no-op).

The workflow uses only `actions/checkout` and the pre-installed `git`/`gh`
binaries — no third-party marketplace Actions. It declares minimal explicit
permissions: `contents: write` and `pull-requests: write`.

## Two-repo topology

Auto uses a vendored-sync distribution model:

- **Auto source repo** (`Mpfk/auto`) — where the framework lives and is developed.
- **`Mpfk/auto-template`** ([github.com/Mpfk/auto-template](https://github.com/Mpfk/auto-template))
  — a GitHub template repository that consumers instantiate via "Use this
  template". It is bootstrapped with every framework file, config seeds, and
  placeholder stubs. The release mirror job (issue #95) keeps it current on
  each new release. See `docs/auto/auto-template-repo.md` for full details.
- **Consumer repos** — any project that has installed Auto by clicking "Use this
  template" on `Mpfk/auto-template` (or an earlier manual copy of the files).

The sync binary (`bin/auto-sync`, issue #91) reads the canonical allow-list
(`.auto-framework-paths`) to know which files it owns, propagates updates, and
reads `.autosyncignore` to know which paths it must never touch.

## Ownership model — "extend, don't edit"

Every file in a consumer repo falls into one of three buckets (fully classified
in `docs/auto/file-buckets.md`):

| Bucket | Who owns it | Sync behavior |
|--------|-------------|---------------|
| **Framework** | Auto | Overwritten on every sync update |
| **Config** | Consumer (seeded by Auto once) | Written if missing; never overwritten |
| **Consumer-owned** | Consumer | Auto never touches |

Consumers customize the framework by **adding** files (e.g. hook extensions in
the 100+ range, new Claude commands, docs) — never by editing Auto's shipped
files. Edits to framework files are lost on the next sync.

## The customization contract — `.autosyncignore`

`.autosyncignore` is the enforcement mechanism for the ownership model. It uses
gitignore syntax and lists every path that `auto-sync` must **never** overwrite,
including:

- Consumer config files seeded once by Auto (`workflow.conf`,
  `.claude/settings.json`, `CLAUDE.md`, `README.md`, `.gitignore`)
- Consumer source and test directories (`src/`, `tests/`)
- Consumer-owned hook extensions in the 100+ range
  (`.githooks/*/1[0-9][0-9]-*.sh` — see `docs/auto/hook-extension.md`)
- The ignore file itself (`.autosyncignore`), so consumer additions survive sync

The complement of `.autosyncignore` is `.auto-framework-paths`, which lists
every path that Auto _does_ own. Together they form a complete, non-overlapping
partition of the repo's files.

When `auto-sync` runs an update it:

1. Iterates `.auto-framework-paths` to find files to overwrite.
2. Skips any path that matches a pattern in `.autosyncignore` (safety net for
   future entries that might span both lists).
3. For Config-bucket files, writes only if the file is absent.

## Hook extension convention

Consumers extend Auto's git hooks by dropping scripts into the hook `*.d/`
dispatcher directories using the 100+ numbering range. Auto's own scripts use
000–099. See `docs/auto/hook-extension.md` for the full convention.

## Adding a new framework file

When a framework author adds a new file to Auto:

1. Add the path to `.auto-framework-paths`.
2. Update the Framework bucket table in `docs/auto/file-buckets.md`.
3. Ensure the path does **not** appear in `.autosyncignore`.
4. Run `tests/test-framework-paths.sh` and `tests/test-autosyncignore.sh` to
   confirm correctness.

## Adding a new consumer-owned path

When a new consumer-owned path type is identified:

1. Add the pattern to `.autosyncignore`.
2. Update the Consumer-owned bucket table in `docs/auto/file-buckets.md`.
3. Ensure the path does **not** appear in `.auto-framework-paths`.
4. Run both test scripts to confirm no overlap.

## Known gotcha — GITHUB_TOKEN and CI

The auto-sync workflow authenticates with `GITHUB_TOKEN` (the default GitHub
Actions token). GitHub's security model intentionally prevents workflows
triggered by `GITHUB_TOKEN` from kicking off further workflow runs — this is
a recursion guard to prevent infinite loops.

**Accepted policy:** CI does **not** run on the sync PR itself. It runs when
the consumer merges the sync PR to their `main` branch. This is the simpler
model — it requires no consumer-side configuration and no additional secrets.
Consumers should treat the sync PR as a diff-review step and rely on their
branch-protection rules to enforce CI on the post-merge push to `main`.

**Safety net:** `.github/CODEOWNERS` requires that at least one human reviewer
approves any PR touching `.github/` or `.githooks/`. This ensures a human has
reviewed the framework diff before the merge triggers CI on `main`.

**Opt-in alternative:** Consumers who want CI to run on the sync PR itself can
store a Personal Access Token as an `AUTO_SYNC_TOKEN` repository secret and
modify the workflow's checkout step to use it instead of `GITHUB_TOKEN`. A PAT
is not subject to the recursion guard and will trigger normal workflow runs on
the opened PR. This is an advanced option — the default `GITHUB_TOKEN`
behaviour is recommended for most consumers.
