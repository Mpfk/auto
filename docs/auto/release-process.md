# Release Process

This document describes how to cut a new release of Auto. Releases produce a semver tag that consumer repos use to detect when a framework update is available via `bin/auto-sync`.

## Prerequisites

> **`bin/auto-sync` requires at least one `v*` tag on the upstream repo.**
>
> The sync script uses `git ls-remote --tags` to discover the latest release.
> If no `v*` tag exists, consumers will see the error:
> `ERROR: No v* tags found on upstream repo… Create a release tag first.`
>
> This means the very first release tag (`v0.1.0` or similar) **must be
> created and pushed before `bin/auto-sync` is usable by any consumer repo.**
> Follow the [Release steps](#release-steps) below to create that first tag.

## Initial setup

Before cutting the first release tag, a repo admin must configure the secret that the release mirror job uses to push framework files to `Mpfk/auto-template`:

1. Go to **Settings → Secrets and variables → Actions** in the `Mpfk/auto` repository.
2. Click **New repository secret**.
3. Set **Name** to `MIRROR_TOKEN`.
4. Set **Value** to a [fine-grained personal access token](https://github.com/settings/tokens?type=beta) scoped to the `Mpfk/auto-template` repository with **Contents: Read and write** permission.
5. Save the secret.

Without `MIRROR_TOKEN` the release mirror job (`.github/workflows/release-mirror.yml`) will fail with a 403 on push. This is a one-time setup; no further action is needed between releases.

## Version format

Auto uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html): `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking changes to the workflow contract (hook signatures, slash-command interface, gate protocol).
- **MINOR** — backward-compatible additions (new slash commands, new docs, new hooks that don't break existing ones).
- **PATCH** — backward-compatible fixes (hook bug fixes, doc corrections, typo fixes).

## `.auto-version` file

The `.auto-version` file in the repo root is the canonical version stamp for Auto. It is a plain text file containing exactly one line: the current version in `MAJOR.MINOR.PATCH` form, with no `v` prefix and no trailing newline.

Example:

```
0.1.0
```

`bin/auto-sync` copies this file into consumer repos during a sync so they can compare their local stamp against the latest release tag to determine if an update is available.

## Adding a new framework file

When adding a new framework file or directory to Auto, add its path to `.auto-framework-paths` **before tagging the release**. The allow-list is the single source of truth for which paths `bin/auto-sync` overwrites on update and which paths the release mirror job pushes to `auto-template`; a path omitted here will not propagate to consumers. After appending the entry, update the Framework bucket table in `docs/auto/file-buckets.md` and run `tests/test-framework-paths.sh` to confirm the path resolves.

## Release steps

Follow these steps in order. All commands run on the `main` branch after the work for the release has already been merged.

### 1. Determine the new version

Decide the new `MAJOR.MINOR.PATCH` version according to the rules above. The current version is in `.auto-version`.

### 2. Update `.auto-version`

Edit `.auto-version` to contain the new version. The file must be a single line with no trailing newline:

```
X.Y.Z
```

### 3. Update `CHANGELOG.md`

Move everything under `[Unreleased]` into a new dated section, and update the comparison link footer:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added / Changed / Fixed / Removed
- ...

[Unreleased]: https://github.com/Mpfk/auto/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/Mpfk/auto/compare/vPREV...vX.Y.Z
```

Leave an empty `[Unreleased]` section above the new entry for the next release.

### 4. Commit the release

```bash
git add .auto-version CHANGELOG.md
git commit -m "chore(release): vX.Y.Z"
```

The commit-msg hook does not append `Closes #N` on `main`, so the message stays clean.

### 5. Create a signed tag

```bash
git tag -s vX.Y.Z -m "Release vX.Y.Z"
```

A signed tag (`-s`) is required. Unsigned tags are not considered valid release markers by `bin/auto-sync`.

### 6. Push the tag

```bash
git push origin vX.Y.Z
```

Push the tag separately from the branch. Do not use `git push --tags` as that would push all local tags.

### 7. Trigger the release mirror

After the tag lands on `origin`, the release mirror job (see issue #95) automatically pushes the tagged commit to the `auto-template` mirror repository. Consumer repos running `bin/auto-sync` will detect the new tag on their next sync run.

## Verification

After the tag is pushed, confirm:

1. `git ls-remote --tags origin vX.Y.Z` returns the tag ref.
2. The GitHub release mirror job completes successfully (check Actions on the `auto-template` repo).
3. `cat .auto-version` on `main` reads the new version.
4. `CHANGELOG.md` has the new version section with today's date and a non-empty entry.

## Breaking changes

When a release contains breaking changes (renamed files, changed hook contracts, renamed labels, altered CI workflow inputs, or a changed `.auto-version` format), it requires a **MAJOR** version bump. Before tagging:

1. Add a dated migration entry to [`docs/auto/UPGRADING.md`](UPGRADING.md) using the template defined there.
2. Add a `### Breaking Changes` subsection to `CHANGELOG.md` linking to that entry.
3. Bump the MAJOR component in `.auto-version` (reset MINOR and PATCH to `0`).

See [`docs/auto/UPGRADING.md`](UPGRADING.md) for the full checklist, the definition of breaking changes, and all per-release migration steps.

## Hotfix releases

Hotfix releases follow the same process with a `PATCH` bump. Branch from the tag that needs patching (`git checkout -b hotfix/vX.Y.Z vX.Y.(Z-1)`), apply the fix, merge back to `main`, then cut the tag from `main`.
