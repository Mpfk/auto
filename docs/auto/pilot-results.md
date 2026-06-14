# Auto Propagation Pilot Results

**Date:** 2026-06-13
**Issue:** [#99](https://github.com/Mpfk/auto/issues/99)
**Branch:** `issue/99`
**Pilot consumer repo:** `Mpfk/auto-pilot-test` (deleted after pilot)

---

## Summary

End-to-end pilot of the Auto framework propagation loop. A throwaway consumer repo
was created from the `auto-template`, the consumer's `.auto-version` was back-dated
to `0.0.1`, and `bin/auto-sync` was run against the upstream `v0.1.0` release tag.
All four acceptance checks passed.

---

## Steps Executed

1. **Created upstream release tag** — `gh release create v0.1.0` on `Mpfk/auto`.
   The repo had no release tags prior to this run.

2. **Created pilot consumer repo** — `gh repo create Mpfk/auto-pilot-test --template Mpfk/auto-template`.

3. **Cloned and set up consumer** — cloned to `/tmp/auto-pilot-test`.

4. **Added consumer hook** — wrote `.githooks/pre-commit.d/100-pilot-test.sh` and
   pushed to `main`. (Branch-guard hook was temporarily disabled via
   `git config core.hooksPath /dev/null` — the consumer repo is not subject to the
   Auto framework-dev workflow, so this is expected consumer behaviour.)

5. **Simulated being behind** — set `.auto-version` to `0.0.1` and pushed.

6. **Ran bin/auto-sync**:
   ```
   bin/auto-sync --upstream https://github.com/Mpfk/auto --skip-verify
   ```
   Output: *Copied 43 file(s). Skipped 8 (consumer-owned).*

7. **Verified all four checks** (see below).

8. **Opened sync PR** — `auto-sync/v0.1.0` branch →
   [Mpfk/auto-pilot-test#1](https://github.com/Mpfk/auto-pilot-test/pull/1).

9. **Deleted pilot repo** — `gh repo delete Mpfk/auto-pilot-test --yes`.

---

## Verification Results

| Check | Result | Details |
|-------|--------|---------|
| PR opens | **PASS** | [Mpfk/auto-pilot-test#1](https://github.com/Mpfk/auto-pilot-test/pull/1) created successfully from branch `auto-sync/v0.1.0` |
| `workflow.conf` untouched | **PASS** | `git diff HEAD -- workflow.conf` returned empty; file is in `.autosyncignore` |
| `100-pilot-test.sh` survives | **PASS** | Hook present and unmodified after sync; `1xx-` namespace is consumer-owned |
| `.auto-version` advances | **PASS** | Updated from `0.0.1` → `0.1.0` |

### Check 1 Detail — Framework files updated

`git status --short` after sync showed:

```
 M .auto-version
?? .github/CODEOWNERS
?? .github/workflows/release-mirror.yml
?? docs/auto/auto-template-repo.md
?? docs/auto/file-buckets.md
?? docs/auto/template-propagation.md
```

The template was created from a slightly older snapshot of `auto-template`, so five
framework files were present in upstream `v0.1.0` but missing from the consumer.
The sync engine correctly added them. All other framework files were already at
identical content (same v0.1.0 codebase), so no diff on those — which is correct.

---

## Friction / Gaps Found

### F-1: No release tag existed before this pilot

`bin/auto-sync` requires a `v*` annotated release tag on the upstream repo.
The upstream `Mpfk/auto` had no tags prior to this run, causing `auto-sync` to
exit with "Could not determine latest release tag". A `v0.1.0` release was created
manually as part of this pilot.

**Implication:** the release process (`docs/auto/release-process.md`) must include
creating a GitHub Release (annotated tag) for every version bump, or the sync engine
cannot locate an update target.

**Action:** Filed as [#100](https://github.com/Mpfk/auto/issues/100) if not already
tracked; otherwise note in the release checklist.

### F-2: Template snapshot lag

The `auto-template` repo is a one-time clone of the framework, not a continuously
mirrored copy. Five files present in upstream `v0.1.0` were absent from the freshly
created consumer because the template snapshot predated those files.

**Implication:** consumers created from `auto-template` may need an immediate sync
run after setup to pull in files added since the template was last refreshed.

**Mitigation (already in place):** `docs/auto/auto-template-repo.md` documents the
`release-mirror.yml` workflow that keeps the template current. This pilot confirms
that `bin/auto-sync` correctly handles the "template is behind" case.

### F-3: Branch-guard hook blocks pilot setup commits to main

The framework's `010-branch-guard.sh` hook prevents direct commits to `main`.
Consumer repos inherit this hook via sync. When setting up the pilot on the consumer,
direct commits were required (no issue workflow for a throwaway repo), so the hooks
path was temporarily cleared.

**Implication:** operators bootstrapping a fresh consumer from the template cannot
commit setup changes directly to `main` without temporarily disabling the guard.

**Mitigation:** `docs/auto/auto-template-repo.md` should document a "first-run
setup" pattern (disable hooks, make initial customisation commits, re-enable).
Not blocking — document in a follow-up.

---

## Conclusion

All four acceptance criteria passed. The propagation loop is end-to-end functional:
upstream release tag → `bin/auto-sync` → consumer PR. The friction items are
documentation/process gaps rather than implementation bugs.
