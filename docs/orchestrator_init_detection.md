# Orchestrate Phase A Detection - Verification Checklist

This checklist verifies that the Orchestrate agent correctly detects project types and writes `workflow.conf` during Phase A initialization.

## Test Scenarios

### ✓ Scenario 1: Fresh clone with package.json
- **Setup:** Clone with `package.json` and `workflow.conf` containing `TEST_CMD=""`
- **Expected:** Orchestrate Phase A detects Node.js project, sets `TEST_CMD="npm test"` in workflow.conf, commits change
- **Verification:**
  - [ ] `workflow.conf` updated with `TEST_CMD="npm test"`
  - [ ] Git commit made with message `chore(config): auto-detect test runner as npm test` 
  - [ ] Orchestrate agent reports what was detected to user
- **Status:** ✅ READY FOR TESTING - Feature implemented in Phase A step 4

### ✓ Scenario 2: Fresh clone with pyproject.toml  
- **Setup:** Clone with `pyproject.toml` and `workflow.conf` containing `TEST_CMD=""`
- **Expected:** Orchestrate Phase A detects Python project, sets `TEST_CMD="pytest"` in workflow.conf
- **Verification:**
  - [ ] `workflow.conf` updated with `TEST_CMD="pytest"`
  - [ ] Git commit made with message `chore(config): auto-detect test runner as pytest`
  - [ ] Orchestrate agent reports detection to user
- **Status:** ✅ READY FOR TESTING - Feature implemented in Phase A step 4

### ✓ Scenario 3: Fresh clone with multiple markers
- **Setup:** Clone with both `package.json` and `pyproject.toml`, `workflow.conf` has `TEST_CMD=""`
- **Expected:** Orchestrate agent warns user about multiple markers, does not write workflow.conf  
- **Verification:**
  - [ ] Warning message displayed about multiple project markers
  - [ ] User asked to set `TEST_CMD` manually in workflow.conf
  - [ ] No changes made to workflow.conf
  - [ ] No git commits for config changes
- **Status:** ✅ READY FOR TESTING - Feature implemented in Phase A step 4

### ✓ Scenario 4: Fresh clone with no markers
- **Setup:** Clone with no project marker files, `workflow.conf` has `TEST_CMD=""`
- **Expected:** Orchestrate agent continues without error, notes config will be set later during scaffolding
- **Verification:** 
  - [ ] No error thrown
  - [ ] Message noting workflow.conf will be configured during scaffolding
  - [ ] workflow.conf remains unchanged
  - [ ] Phase A continues to next step
- **Status:** ✅ READY FOR TESTING - Feature implemented in Phase A step 4

### ✓ Scenario 5: Clone where TEST_CMD already set
- **Setup:** Clone with `workflow.conf` containing `TEST_CMD="make test"`  
- **Expected:** Orchestrate agent skips detection entirely, does not override manual configuration
- **Verification:**
  - [ ] Detection step skipped
  - [ ] workflow.conf remains unchanged 
  - [ ] No git commits for config changes
  - [ ] Phase A continues normally  
- **Status:** ✅ READY FOR TESTING - Feature implemented in Phase A step 4

## Implementation Requirements

The Orchestrate agent must add this step to Phase A after branch creation:

1. Check if `workflow.conf` has `TEST_CMD=""` (empty)
2. If empty, scan for project markers using same priority as `.githooks/lib/detect.sh`
3. Handle single marker: update workflow.conf and commit
4. Handle multiple markers: warn user, ask for manual config  
5. Handle no markers: continue with note about later scaffolding
6. Handle existing config: skip detection entirely

## Notes

- This is a documentation/instruction change to `.github/agents/orchestrate.agent.md`
- Not executable code that can be unit tested
- Verification requires manual QA following this checklist