# README Quick Start Verification Checklist

Manual verification checklist for README.md Quick Start simplification (Issue #6).

## Acceptance Criteria

- [ ] Quick Start has exactly 2 steps
- [ ] Step 2 mentions `@orchestrator`
- [ ] No mention of "Edit workflow.conf" in Quick Start or For a new project sections
- [ ] `git config core.hooksPath .githooks` appears in developer setup note, not Quick Start
- [ ] Configuration subsection explains auto-detection, not manual editing
- [ ] No broken links

## Current Status: FAILING

The current README.md does not meet these criteria:
- ❌ Quick Start has 4 steps (should be 2)
- ❌ Contains "Edit `workflow.conf`" in Quick Start step 3
- ❌ Contains `git config core.hooksPath .githooks` in Quick Start step 2
- ❌ Configuration subsection shows manual workflow.conf editing

## After Implementation

This checklist should PASS after the GREEN phase implementation.