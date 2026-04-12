# README Quick Start Verification Checklist

Manual verification checklist for README.md Quick Start simplification (Issue #6).

## Acceptance Criteria

- [x] Quick Start has exactly 2 steps
- [x] Step 2 mentions `@orchestrate`
- [x] No mention of "Edit workflow.conf" in Quick Start or For a new project sections
- [x] `git config core.hooksPath .githooks` appears in developer setup note, not Quick Start
- [x] Configuration subsection explains auto-detection, not manual editing
- [x] No broken links

## Current Status: PASSING ✅

The README.md now meets all acceptance criteria:
- ✅ Quick Start reduced from 4 steps to exactly 2 steps
- ✅ Step 2 mentions `@orchestrate`
- ✅ Removed "Edit `workflow.conf`" from guided path
- ✅ Moved `git config core.hooksPath .githooks` to developer setup note
- ✅ Configuration subsection explains auto-detection instead of manual editing
- ✅ All links verified and working