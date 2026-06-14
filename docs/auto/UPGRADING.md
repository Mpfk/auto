# Upgrading Auto

This document explains what constitutes a breaking change in Auto, how breaking changes are signaled, and how to migrate your consumer repo when one lands.

For the general release process (versioning, tagging, CHANGELOG), see [release-process.md](release-process.md).

---

## What counts as a breaking change

A release is breaking if it requires any manual action in a consumer repo beyond accepting the auto-sync PR. Specifically:

| Category | Example |
|----------|---------|
| **File renamed or moved** | `docs/auto/agent-flow.md` → `docs/auto/workflow/agent-flow.md` — consumer's `.autosyncignore` may reference the old path |
| **Hook contract change** | A variable in `workflow.conf` is renamed (e.g. `TEST_CMD` → `RUN_TESTS`) — hook scripts that read it break silently |
| **Label renamed or removed** | `status/in-progress` renamed to `status/active` — existing issues carry the old label; queries and automations break |
| **CI workflow interface change** | A reusable workflow input is renamed or dropped — consumer's thin-shim workflow calls the wrong key |
| **`.auto-version` format change** | `bin/auto-sync` reads the version stamp; a format change breaks the comparison logic |
| **`.autosyncignore` syntax change** | If the sync script starts interpreting the ignore file differently, previously protected paths may be clobbered |

When in doubt, treat the change as breaking. It is safer to cut a major version and provide migration steps than to silently break a consumer's workflow.

---

## How breaking changes are signaled

Three signals always accompany a breaking release:

1. **Major semver bump** — the version in `.auto-version` advances its `MAJOR` component (e.g. `1.4.2` → `2.0.0`). `bin/auto-sync` detects this and can warn the consumer before applying files.
2. **An entry in this file** — a dated `## vX.0.0` section appears below with a description of each breaking change and step-by-step migration instructions.
3. **A `### Breaking Changes` note in `CHANGELOG.md`** — the release section in `CHANGELOG.md` includes a `### Breaking Changes` subsection that links back to the relevant section of this file.

If any of the three signals is missing, the release is not correctly marked as breaking. Maintainers: see the checklist in [For maintainers](#for-maintainers).

---

## Per-release migration format

Each breaking release gets one top-level section in this file. Use the following template verbatim:

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
- Include the exact file name, label name, or config key — do not make consumers infer it.
- For label changes, include the GitHub CLI command to rename or delete the label on existing issues.
- For `workflow.conf` key renames, include both `grep` (to find uses) and `sed` (to rewrite) one-liners.
- End with a concrete verification step so the consumer knows when they are done.

---

## Release history

### v0.1.0 (2026-06-13)

This is the initial release of Auto. There are no previous versions to migrate from; no manual steps are required.

---

## For maintainers

### When to cut a major vs minor release

| Change type | Version bump |
|-------------|--------------|
| Breaking change (any category in [What counts as a breaking change](#what-counts-as-a-breaking-change)) | **MAJOR** |
| New slash command, new doc, new hook that does not alter existing contracts | **MINOR** |
| Bug fix, doc correction, typo fix, hook behavior fix that does not change the interface | **PATCH** |

If a single release contains both breaking and non-breaking changes, it is still a **MAJOR** release.

### Checklist for shipping a breaking change

Complete all four steps before pushing the release tag:

- [ ] **Add a migration entry to this file** (`docs/auto/UPGRADING.md`) using the template above. The entry must be complete enough that a consumer can migrate without reading the diff.
- [ ] **Add a `### Breaking Changes` subsection to `CHANGELOG.md`** under the new version section. Include a link to the corresponding section in this file.
- [ ] **Bump the MAJOR version** in `.auto-version` (reset MINOR and PATCH to `0`).
- [ ] **Verify `bin/auto-sync`** handles the major-version gap gracefully — it should warn the consumer and either halt or prompt before applying files, rather than silently overwriting.

Do not create a release tag until all four items are checked. A breaking release that ships without migration steps is a support incident waiting to happen.
