# Upgrading Auto

This document explains how a consumer repo upgrades Auto, what counts as a
breaking change, and how breaking changes are signaled.

For the general release process (versioning, tagging, CHANGELOG), see
[release-process.md](release-process.md).

---

## The two kinds of upgrade

Auto ships two kinds of content, and they upgrade by completely different means.

### CI logic — upgrades automatically, nothing to do

Your `.github/workflows/pr-checks.yml` is a thin caller that references Auto's
reusable PR-checks workflow by the floating major tag:

```yaml
jobs:
  checks:
    uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1
```

When Auto cuts a new minor or patch release, it moves the `v1` tag forward. Your
**next pull request automatically runs the new CI logic** — no copy, no token,
no action on your part. This is the whole point of the reusable-workflow model:
PR-checks improvements reach you for free.

You only do something when a **breaking** (major) release lands — see
[Major upgrades](#major-upgrades-opting-in-to-a-new-major) below.

### Instruction files — upgrade by manual re-copy (snapshot model)

The slash commands, hooks, agents, `CLAUDE.md`, and docs in your repo are a
**snapshot** copied once when you clicked "Use this template". There is **no
mechanism that updates them automatically**, and nothing upstream will ever
overwrite your local edits. To adopt newer instruction files, you re-copy the
ones you want by hand.

#### How to re-copy instruction files

Pick whichever fits your workflow:

**Option A — GitHub UI (single file).** Open the file in
[`Mpfk/auto-template`](https://github.com/Mpfk/auto-template), copy its contents,
and paste over your local copy in a pull request.

**Option B — `git` (one or many files).** Fetch the template as a remote and
check out just the paths you want onto an issue branch:

```bash
git checkout -b issue/{n}
git remote add auto-template https://github.com/Mpfk/auto-template.git   # once
git fetch auto-template
# Re-copy specific paths (example: the slash commands and one hook):
git checkout auto-template/main -- .claude/commands .githooks/pre-commit.d/030-tdd-cycle-guard.sh
git commit -m "chore: refresh Auto instruction files from template"
```

Then open a PR to `main` as usual. Review the diff before merging — because the
files are yours, any local customizations you made will show up as conflicts or
overwrites, and you decide what to keep.

> There is intentionally **no sync tool**. The manual re-copy is the supported
> path; it keeps the distribution model simple and free of tokens or secrets.

---

## What counts as a breaking change

A release is breaking if it requires manual action in a consumer repo. The most
important category is now the **reusable-workflow interface**, since that is the
one part of Auto consumers track live.

| Category | Example |
|----------|---------|
| **Reusable-workflow input change** | An input to `reusable-pr-checks.yml` is renamed or dropped — `@v1` callers that pass it break |
| **Reusable-workflow permission change** | The reusable workflow starts requiring a permission the caller doesn't grant |
| **Hook contract change** | A variable in `workflow.conf` is renamed (e.g. `TEST_CMD` → `RUN_TESTS`) — hook scripts that read it break |
| **Label renamed or removed** | `status/in-progress` renamed to `status/active` — existing issues carry the old label; queries and automations break |
| **File renamed or moved** | A slash command or hook is relocated — consumers' re-copy commands reference the old path |
| **`.auto-version` format change** | Tooling or docs that parse the version stamp break |

When in doubt, treat the change as breaking. It is safer to cut a major version
and provide migration steps than to silently break a consumer.

---

## How breaking changes are signaled

Three signals always accompany a breaking release:

1. **A new major tag** — Auto publishes `vX.Y.Z` and creates a **new floating
   major tag** (`v2`) rather than moving `v1`. Existing `@v1` consumers are
   untouched until they opt in.
2. **An entry in this file** — a dated `## vX.0.0` section appears below with a
   description of each breaking change and step-by-step migration instructions.
3. **A `### Breaking Changes` note in `CHANGELOG.md`** — links back to the
   relevant section of this file.

If any of the three signals is missing, the release is not correctly marked as
breaking. Maintainers: see the checklist in [For maintainers](#for-maintainers).

---

## Major upgrades — opting in to a new major

When Auto ships a new major (say `v2`), your CI does **not** change on its own:
you stay pinned to `@v1` and keep running the last `1.x` reusable workflow. To
adopt the new major:

1. Read the matching `## v2.0.0` migration section in this file end to end.
2. Perform any instruction-file re-copies it calls for (snapshot model — see
   [above](#instruction-files--upgrade-by-manual-re-copy-snapshot-model)).
3. Bump the reference in `.github/workflows/pr-checks.yml`:

   ```yaml
   # from
   uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v1
   # to
   uses: Mpfk/auto/.github/workflows/reusable-pr-checks.yml@v2
   ```

4. Open the change as a pull request and confirm CI is green before merging.

You upgrade on your own schedule; nothing forces the jump.

---

## Per-release migration format

Each breaking release gets one top-level section in this file. Use the following
template verbatim:

```markdown
## vX.0.0 (YYYY-MM-DD)

### Breaking changes

#### <Short name for change 1>

- **What changed:** One sentence describing the change precisely (old name/path/key → new name/path/key).
- **Why:** One sentence explaining the motivation.
- **Migration steps:**
  1. Step one (command or file edit).
  2. Step two.
  3. Verify step (what to check to confirm success).

#### <Short name for change 2>

- **What changed:** ...
- **Why:** ...
- **Migration steps:**
  1. ...
```

Rules for migration step authoring:

- Write steps as imperative commands (`Run`, `Edit`, `Delete`, `Replace`).
- Include the exact file name, label name, or config key — do not make consumers
  infer it.
- For label changes, include the GitHub CLI command to rename or delete the
  label on existing issues.
- For `workflow.conf` key renames, include both `grep` (to find uses) and `sed`
  (to rewrite) one-liners.
- If the major bumps the reusable-workflow contract, include the exact
  `uses:` ref edit (`@v1` → `@v2`).
- End with a concrete verification step so the consumer knows when they are done.

---

## Release history

### v0.1.0 (2026-06-13)

This is the initial release of Auto. There are no previous versions to migrate
from; no manual steps are required.

---

## For maintainers

### When to cut a major vs minor release

| Change type | Version bump |
|-------------|--------------|
| Breaking change (any category in [What counts as a breaking change](#what-counts-as-a-breaking-change)) | **MAJOR** |
| New slash command, new doc, new hook, additive reusable-workflow behavior | **MINOR** |
| Bug fix, doc correction, CI fix that does not change the reusable-workflow contract | **PATCH** |

If a single release contains both breaking and non-breaking changes, it is still
a **MAJOR** release.

### Checklist for shipping a breaking change

Complete all four steps before publishing the release:

- [ ] **Add a migration entry to this file** (`docs/auto/UPGRADING.md`) using the
  template above. The entry must be complete enough that a consumer can migrate
  without reading the diff.
- [ ] **Add a `### Breaking Changes` subsection to `CHANGELOG.md`** under the new
  version section, with a link to the corresponding section in this file.
- [ ] **Bump the MAJOR version** in `.auto-version` (reset MINOR and PATCH to `0`).
- [ ] **Create a new floating major tag** (`v2`, `v3`, …) rather than moving the
  existing one, so `@v1` consumers are not upgraded silently. See
  [release-process.md](release-process.md#breaking-changes).

Do not publish the release until all four items are checked. A breaking release
that ships without migration steps is a support incident waiting to happen.
