# Auto — Template Propagation

This document describes how Auto framework updates flow from the **Auto source
repo** to **consumer repos** that have installed the framework.

## Two-repo topology

Auto uses a vendored-sync distribution model:

- **Auto source repo** (`Mpfk/auto`) — where the framework lives and is developed.
- **Consumer repos** — any project that has installed Auto by copying the
  framework files from the template.

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
