# Release Process

This document describes how to cut a new release of Auto.

A release does two things at once:

1. Publishes an immutable `vX.Y.Z` tag for the new version.
2. Moves the **floating major tag** (`v1`) to point at that release, so every
   consumer whose `pr-checks.yml` references the reusable workflow as `@v1`
   picks up the new CI logic automatically — for free, with no token and no
   action on their part.

There is no sync engine, no PAT, and no scheduled job involved. Distribution is
native GitHub: consumers reference the reusable workflow by tag, and moving the
tag delivers the update.

## Version format

Auto uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html): `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking changes to the workflow contract (hook signatures,
  slash-command interface, gate protocol, or the **reusable-workflow inputs**).
  A major bump means consumers must opt in by changing their `uses:` ref from
  `@v1` to `@v2`.
- **MINOR** — backward-compatible additions (new slash commands, new docs, new
  hooks that don't break existing ones, additive reusable-workflow behavior).
  Delivered automatically to `@v1` consumers.
- **PATCH** — backward-compatible fixes (hook bug fixes, doc corrections, CI
  fixes). Delivered automatically to `@v1` consumers.

### What `@v1` consumers receive automatically

Because consumers pin the **major** tag (`@v1`), every minor and patch release
reaches them the moment you move the `v1` tag — no copy, no manual step. The
only release that does **not** reach them automatically is a new **major**: that
ships as a new tag (`v2`) which they adopt deliberately when ready.

## `.auto-version` file

The `.auto-version` file in the repo root is the canonical version stamp for
Auto. It is a plain text file containing exactly one line: the current version
in `MAJOR.MINOR.PATCH` form, with no `v` prefix and no trailing newline.

Example:

```
1.2.0
```

It records the framework's own version for humans and CHANGELOG cross-reference.

## Release steps

Follow these steps in order, after the work for the release has already been
merged.

`main` is branch-protected: direct pushes are forbidden and a branch-guard
pre-commit hook blocks commits to `main`. So the version-bump commit
(`.auto-version` + `CHANGELOG.md`) goes through an `issue/{n}` branch and a PR
like any other change — it is **not** committed directly to `main`. Only the
tagging steps run on `main`, after that release PR has merged.

### 1. Determine the new version

Decide the new `MAJOR.MINOR.PATCH` version according to the rules above. The
current version is in `.auto-version`.

### 2. Update `.auto-version`

File a release-tracking issue and create an `issue/{n}` branch off `main`:

```bash
git checkout main && git pull
git checkout -b issue/{n}
```

Edit `.auto-version` to contain the new version. The file must be a single line
with no trailing newline:

```
X.Y.Z
```

### 3. Update `CHANGELOG.md`

Move everything under `[Unreleased]` into a new dated section, and update the
comparison link footer:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added / Changed / Fixed / Removed
- ...

[Unreleased]: https://github.com/Mpfk/auto/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/Mpfk/auto/compare/vPREV...vX.Y.Z
```

Leave an empty `[Unreleased]` section above the new entry for the next release.

### 4. Commit the release and merge via PR

On the `issue/{n}` branch, commit the version bump with a **signed** commit
(branch protection on `main` requires signed commits):

```bash
git add .auto-version CHANGELOG.md
git commit -S -m "chore(release): vX.Y.Z"
```

The commit-msg hook appends `Closes #N` on an `issue/*` branch — that is
expected and fine; it closes the release-tracking issue when the PR merges.

Then open a PR, wait for CI to pass, and merge it to `main`:

```bash
git push -u origin issue/{n}
gh pr create --fill
# once CI is green:
gh pr merge --squash --delete-branch
```

The release commit is now on `main`. The tagging steps below run against that
merged commit.

### 5. Create the signed `vX.Y.Z` tag

Switch to `main` and pull so the tag is created from the merged release commit:

```bash
git checkout main && git pull
git tag -s vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

A signed annotated tag (`-s`) is required. Push the tag separately from the
branch — do not use `git push --tags`, which would push all local tags.

### 6. Move the floating major tag

This is the step that actually delivers the release to consumers. Point the
major tag (`v1` for any `1.Y.Z` release) at the new commit and force-push it:

```bash
git tag -f -s v1 -m "Auto v1 → vX.Y.Z"
git push --force origin v1
```

Every consumer whose `pr-checks.yml` references
`Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1` now runs the new CI
logic on their next pull request — automatically, using only the default
`GITHUB_TOKEN`.

> For a release that bumps the **major** version (e.g. cutting `2.0.0`), create
> the new floating major tag `v2` instead of moving `v1`. Existing `@v1`
> consumers stay on the last `1.x` release until they deliberately change their
> `uses:` ref to `@v2`. See [Breaking changes](#breaking-changes).

## Verification

After the tags are pushed, confirm:

1. `git ls-remote --tags origin vX.Y.Z` returns the immutable version tag.
2. `git ls-remote --tags origin v1` (or `v2`) shows the floating major tag now
   points at the new release commit.
3. `cat .auto-version` on `main` reads the new version.
4. `CHANGELOG.md` has the new version section with today's date and a non-empty
   entry.

## Breaking changes

When a release contains breaking changes — renamed files, changed hook
contracts, renamed labels, or **altered reusable-workflow inputs** — it requires
a **MAJOR** version bump. Before tagging:

1. Add a dated migration entry to [`UPGRADING.md`](UPGRADING.md) using the
   template defined there.
2. Add a `### Breaking Changes` subsection to `CHANGELOG.md` linking to that
   entry.
3. Bump the MAJOR component in `.auto-version` (reset MINOR and PATCH to `0`).
4. In Step 6, create the **new** floating major tag (`v2`) rather than moving
   `v1`. Consumers opt in to the breaking release by changing their `uses:` ref;
   they are never broken silently.

See [`UPGRADING.md`](UPGRADING.md) for the full checklist, the definition of
breaking changes, and per-release migration steps.

## Hotfix releases

Hotfix releases follow the same process with a `PATCH` bump. Branch from the tag
that needs patching (`git checkout -b hotfix/vX.Y.Z vX.Y.(Z-1)`), apply the fix,
merge back to `main` via PR, cut the `vX.Y.Z` tag from `main`, then move the
floating major tag (Step 6) so `@v1` consumers receive the fix.
