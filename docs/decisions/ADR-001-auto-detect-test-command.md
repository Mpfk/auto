# ADR-001: Auto-detect test command

## Status

**Accepted** (2026-04-11)

## Context

The primary friction point in the multi-agent workflow template setup was requiring 
users to manually edit `workflow.conf` before git hooks would work. Users would 
clone a repository, attempt to push to an issue branch, and encounter cryptic 
errors when the pre-push hook tried to run an empty `TEST_CMD`.

This manual configuration step blocked adoption and created poor first-run experience.

## Options Considered

**Option A: Smarter defaults**  
Set `TEST_CMD="echo 'No tests configured'"` in template to avoid empty command errors.

**Option B: Auto-detect from project markers**  
Scan for `package.json`, `pyproject.toml`, `go.mod`, etc. at hook runtime and 
infer the appropriate test command.

**Option C: Interactive setup script**  
Provide a `setup.sh` script that prompts users for test command and writes 
`workflow.conf`.

**Option D: Agent-driven config**  
Have orchestrator/issue agents automatically detect and configure test commands 
during repository initialization.

## Decision

Implemented **Options A + B combined** with **Option D** as an enhancement:

1. **Empty default signals auto-detect**: `TEST_CMD=""` in template triggers detection
2. **Runtime detection with write-back**: `.githooks/lib/detect.sh` scans project markers
3. **Agent integration**: Orchestrator Phase A also runs detection on repository init
4. **Option C rejected**: Interactive scripts add complexity and still require manual steps

### Key Design Choices

**Write-back vs runtime-only**  
Chose write-back to `workflow.conf` for transparency and debuggability. Users can 
see what was detected and manually override if needed.

**Monorepo multiple-marker behavior**  
When multiple markers found (e.g., `package.json` + `pyproject.toml`), warn and 
skip rather than choosing first. Safety over convenience.

**Shared library approach**  
Created `.githooks/lib/detect.sh` sourced by both local hooks and CI to avoid 
code duplication and ensure consistent behavior.

## Consequences

**Positive:**
- Fresh clones with standard project structures work immediately
- No manual configuration required for Node.js, Python, Go, Rust, Java projects
- Clear error messages guide users toward resolution
- Transparent auto-detection with manual override capability

**Negative:**
- Monorepos and unusual project structures still require one manual configuration step
- Additional complexity in hook logic
- Edge cases (multiple test commands, custom runners) need documentation

**Trade-offs:**
- Prioritized common case convenience over edge case flexibility
- Added detection logic increases maintenance surface but dramatically improves UX