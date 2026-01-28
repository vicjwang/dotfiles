---
description: Execute implementation plan using TDD - tests first, then implement
argument-hint: <path-to-plan-file>
model: opus
---

Implement the plan at: $ARGUMENTS

## Overview

Execute the implementation plan using strict Test-Driven Development (TDD). Tests are written first and are immutable during implementation.

## Pre-flight Check

Before starting implementation:
1. Read `PROGRESS.md` in the plan directory
2. If status is "done" or all tasks are `[x]`, inform user: "Implementation already complete per PROGRESS.md. Run `/review-job` or `/finish-job` instead."
3. If status is "not finished", resume from first unchecked `[ ]` task

## Phase 1 - Write Tests

### Phase 1.0 - Verify Behavior Assumptions

Before writing tests, verify that test expectations in the plan match actual code behavior:
- If plan says "X should return Y", read the relevant code to confirm
- Watch for "returns highest only" vs "returns all matching" patterns
- Watch for "list of strings" vs "tuple" vs "dict" format expectations
- Check config/fixture structure matches what production code expects

### Phase 1.1 - Write Tests

Choose based on plan complexity:
- **Small plans (1-3 tasks)**: Use `/tdd` command directly in main context
- **Medium plans (4-6 tasks)**: Spawn a single `qa-engineer` subagent to write all tests
- **Large plans (7+ tasks)**: Spawn **parallel** `qa-engineer` subagents by independent test area

**Parallel test writing (7+ tasks):**
1. Analyze which tasks can have tests written independently (different modules/files)
2. Group tasks by test file or module boundary
3. Spawn multiple `qa-engineer` agents in a **single message** with multiple Task tool calls
4. Each agent writes tests for its assigned task group

**Test requirements:**
- Organize tests by task from the plan
- Use `pytest.mark.parametrize` for multiple input variations
- Use `hypothesis` for property-based testing when applicable
- Thoroughly consider edge cases
- Tests must be comprehensive enough to validate the implementation

### Phase 1a - Update Existing Tests for API Changes

**If the plan changes function signatures, return types, or behavior**, spawn a `qa-engineer` subagent to update affected existing tests BEFORE writing new tests.

Provide the agent with:
1. List of API changes from the plan (function names, what changes)
2. Instructions to search for existing tests: `rg "function_name" tests/ --type py`
3. Update tests to work with new API (do NOT write new tests)
4. Create helper functions if a pattern repeats across many tests

**After writing/updating tests:** Proceed to Phase 1b if the plan removes APIs, otherwise skip to Phase 1.5.

## Phase 1b - Delete Obsolete Test Files (API Removal Only)

**If the plan removes or completely replaces APIs**, identify and delete test files that will never pass:

1. **Identify obsolete tests**: Search for tests that ONLY test removed APIs:
   ```bash
   # Find tests using removed APIs
   rg "removed_function|removed_class|old_api_name" tests/ --type py -l
   ```

2. **Categorize each file**:
   - **Delete**: Test file ONLY tests removed APIs (no salvageable tests)
   - **Keep + Update**: File has mix of old and new API tests (handled by Phase 1a)

3. **Delete obsolete files before implementation**:
   ```bash
   rm tests/unit/test_old_api.py tests/unit/test_removed_feature.py
   git add -u && git commit -m "chore: remove obsolete tests for removed APIs"
   ```

**Why this matters**: Fixing tests for removed APIs is wasted effort. If new comprehensive tests (from Phase 1.1) cover the replacement functionality, delete the old tests proactively.

## Phase 1.5 - Validate Test Fixtures

Run fixture validation on new test files:
```bash
# 1. Collection check
uv run pytest <new-test-files> --collect-only

# 2. Baseline existing failures (to distinguish new vs pre-existing)
uv run pytest tests/ --tb=no -q 2>&1 | tail -5  # Note any pre-existing failures

# 3. Run ONE test to verify fixtures work at runtime
uv run pytest <new-test-files> -k "test_" --maxfail=1 -x
```

If collection fails or the first test fails with AttributeError on a mock, the fixture is incomplete. Fix BEFORE proceeding to Phase 2.

**Common fixture issues:**
- Mock missing `return_value` for methods that return values
- Mock missing nested attributes (e.g., `mock_config.tiered_detection.logging_window_ms`)
- Mock missing spec causing unexpected attribute access
- Missing `mock_config.parser.sections.return_value = []` for MainWindow tests
- Missing signal/slot mock setup

**After adding config fields** (any task adding fields to config dataclasses):
```bash
# Find Mock-based fixtures that may need the new fields
rg "mock_config|Mock\(\)" tests/ --type py | rg "tiered_detection\." | head -20

# CRITICAL: Also find INLINE config templates (string literals with [SECTION] headers)
rg "EXISTING_FIELD_IN_SAME_SECTION" tests/ --type py -l
# Then add new field to each file's inline config string
```
Update each fixture AND inline config template to include the new fields, or tests will fail post-implementation.

### Phase 1.6 - Fix Direct Dataclass Instantiations

**After adding required fields to dataclasses** (config classes, models), test files that instantiate them directly will break.

1. **Find all direct instantiations**:
   ```bash
   rg "DataclassName\(" tests/ --type py -l
   ```

2. **For each file**, either:
   - Add the new field to the instantiation
   - OR verify it uses a `create_*_config()` helper from conftest.py (preferred)

3. **If >5 files need updates**, spawn a dedicated agent:
   ```
   Update all test files creating DataclassName directly to include new_field parameter.
   Files: [list from step 1]
   ```

**Why this matters**: New required dataclass fields cascade unpredictably - tests in unrelated files break because they construct the dataclass directly instead of using helpers.

## Phase 2 - Implement

**Parallel execution strategy:**
1. Analyze task dependencies in the plan (file modifications, import chains, shared state)
2. Group dependent tasks together (same subagent, sequential execution)
3. Independent task groups → spawn `python-pro` subagents **in parallel** (single message, multiple Task calls)

**CRITICAL: How to spawn parallel Tasks:**
- Send ONE message containing MULTIPLE Task tool calls (not sequential messages)
- Each Task call is independent and runs concurrently
- **Do NOT use `run_in_background: true`** - background agents can't get Edit tool permissions
- Example: 8 tasks with 2 independent groups → spawn 2 agents in single message, each handling 4 tasks sequentially

**Dependency analysis:**
- **Dependent** (same agent): Task B imports from file modified by Task A; shared fixtures; sequential DB migrations
- **Independent** (parallel agents): Different modules; separate test files; no shared state

**Workload balancing** (avoid 7-task vs 2-task splits):
- Target ~3-4 tasks per agent for balanced execution time
- Group by **file**, not just logical dependency:
  - Tasks modifying same file → same agent (even if logically separate)
  - Example: "add field to models.py" + "add another field to models.py" → one agent
- Config/wiring tasks can often parallelize if field names are known upfront
- Sequential dependency chains are slow; split at natural boundaries where possible
- Bad: Agent A gets 7 sequential tasks, Agent B gets 2 → A takes 3x longer
- Good: Split 10 tasks into 3 agents of 3-4 tasks each, grouped by file proximity

**Parallel agent file ownership** (prevent merge conflicts):

When spawning parallel agents, assign shared files to ONE agent:

| Shared File | Assign To |
|-------------|-----------|
| `config.ini` | Agent handling config-focused task |
| `tests/conftest.py` | Agent adding most fixtures |
| Test fixture files with config dataclasses | Agent implementing Task 1 (config changes) |
| `**/base_config.py` templates | Same agent as conftest.py |
| `CLAUDE.md` | Do at end, not during parallel work |

**Pattern:**
- Agent A: Tasks 1, 3 + **owns config.ini edits**
- Agent B: Tasks 2, 4 (no shared file writes)

**Why**: Multiple agents editing the same file creates race conditions or requires manual merge resolution.

**CRITICAL**: When Task 1 adds config fields, that agent MUST also update all test fixtures using those config dataclasses. Don't split config + fixture updates across agents.

**For each subagent:**
1. **Tests are immutable** - do NOT edit tests during implementation
2. Run tests with `uv run pytest` after implementation
3. **Update PROGRESS.md after EACH task** - not batched at end:
   - Mark task `[x]` with test counts and notes
   - If handling tasks 3,4,5: update after 3, update after 4, update after 5
   - Include: test count, files modified, any blockers
4. If tests fail:
   - Attempt to fix implementation (up to 3 attempts per task)
   - After 3 failed attempts, STOP and return to main context

### On repeated test failures (3+ attempts):

1. **Do NOT continue implementing**
2. Notify the user with:
   - Which task failed
   - What the test expects vs. what the implementation does
   - Your analysis: Do the tests need updating, or does the plan need structural changes?
3. **Wait for user approval** before proceeding

### Post-Code-Review Fix Protocol

When fixing issues identified by code-reviewer (during `/review-job`):
1. Make the fix
2. **Immediately run affected tests** before proceeding to next step
3. If tests fail, the fix conflicts with test assumptions - revert and notify user
4. Tests are immutable; if fix conflicts with tests, user must decide

## Progress Tracking

**MUST update `PROGRESS.md`** in the same directory as the plan file after completing each task.

### Status Header (required at top)

PROGRESS.md must start with a status line:
```
## Status: not started | not finished | done
```

Update status as work progresses:
- `not started` - Initial state, no tasks completed
- `not finished` - At least one task done, work in progress
- `done` - All tasks completed and verified

### Detailed Task Notes (2511942-style)

For each completed task, include:
1. **Date**: When the task was completed
2. **Test counts**: How many tests pass (e.g., "All 22 tests pass")
3. **Files modified**: List specific production files changed
4. **Items completed**: Bullet list of specific changes made
5. **Blockers/learnings**: Any issues encountered or lessons learned

**Example format:**
```markdown
## Status: not finished

### Phase 1: Foundation
- [x] **Task 1**: Add ConfigurationError and Helper Methods
  - `ConfigurationError` exception class
  - `_require()`, `_require_int()`, `_require_float()` helpers
  - Notes: Completed 2026-01-09. All 22 tests pass (3 in TestConfigurationError, 19 in TestRequireHelpers). Files: core/config.py.

- [x] **Task 2**: Remove Deprecated Dataclasses
  - Delete: `DetectionConfig`, `OffsetsConfig`, `Tier0FilterConfig`
  - Delete: `config.detection`, `config.offsets` properties
  - Notes: Completed 2026-01-09. Updated spike_qualifier.py, spike_tier_classifier.py. Deleted 4 deprecated dataclasses. All 8 Task 2 tests pass.

- [ ] **Task 3**: Update Test Fixtures
  - Blocked by: Task 2 test failures in test_config.py
```

### Update Frequency

- Update PROGRESS.md **immediately** after each task (not batched)
- Mark tasks `[x]` when done, include notes inline
- Note blocked tasks with reason

**Do NOT create your own summary file** - only update the existing PROGRESS.md.

## Shell Tooling

Prefer performant tools over POSIX defaults:
- **Files**: `fd` not `find` (e.g., `fd -e py`)
- **Text search**: `rg` not `grep` (e.g., `rg "pattern" --type py`)
- **Code structure**: `ast-grep -p '<pattern>'` for syntax-aware matching
- **Find & replace**: `sd` not `sed` (e.g., `sd 'old' 'new' file.py`)
- **Structural diff**: `difft` for syntax-aware diffs
- **JSON**: `jq` for parsing/filtering
- **YAML/XML**: `yq` for parsing
- **CSV**: `xsv` for fast CSV processing (e.g., `xsv select col1,col2`)
- **Columns**: `choose` not `cut`/`awk` (e.g., `echo "a b c" | choose 1`)
- **Selection**: pipe to `fzf` when choosing from multiple results
- **Disk usage**: `dust` not `du`
- **Code stats**: `tokei` for lines of code
- **Benchmarking**: `hyperfine` not `time` (e.g., `hyperfine 'cmd1' 'cmd2'`)

## Constraints

- Never modify tests to make them pass
- Seek user approval when blocked
- Follow existing code patterns in the codebase
- Keep files under 700 lines as specified in the plan

## Parallelization Quick Reference

| Plan Size | Phase 1 (Tests) | Phase 2 (Implement) |
|-----------|-----------------|---------------------|
| 1-3 tasks | `/tdd` in main | Sequential in main |
| 4-6 tasks | 1 qa-engineer | 1-2 python-pro agents |
| 7+ tasks | N qa-engineer agents (by module) | N python-pro agents (~3-4 tasks each) |

**Max useful parallelism**: ~4 agents (diminishing returns beyond; coordinate via PROGRESS.md)

**Balancing example** (10 tasks with dependency chain 1→2→3→4→6 + independent 7,8 + config 9 + integration 10):
- Bad: Agent A (tasks 1-6,9) = 7 tasks, Agent B (tasks 7-8) = 2 tasks
- Good: Agent A (tasks 1,4 - models.py), Agent B (tasks 2,3,6 - tiered pipeline), Agent C (tasks 7,8,9 - detectors+config)

**Main agent should work too**: Take the largest/most complex task group directly instead of delegating everything:
- Spawn subagents in **parallel foreground mode** (multiple Task calls in single message, no `run_in_background`)
- Work on the most challenging task (longest dependency chain, most files, most context needed) in main context
- Main agent has full conversation context - use it for tasks requiring deep codebase understanding
- Parallel foreground agents run concurrently and can prompt for Edit permissions
- Example: Main handles tasks 1-4 (core pipeline), parallel agents handle tasks 5-8 (independent modules)

## Incremental Commits (for recovery)

After each task completes successfully:
1. Stage modified files AND new files from the task (NOT irrelevant files):
   ```bash
   git add -u                           # Modified tracked files
   git add <new-files-from-task>        # New files created by this task
   git commit -m "wip: task N - <description>"
   ```
2. Record the commit hash in PROGRESS.md next to the completed task

**CRITICAL**: Do NOT use `git add -A` (includes untracked data/, docs/, etc.). Explicitly add new source/test files created by the task.

## Completion

When all tasks pass:
1. If multiple `wip:` commits exist, squash into one: `git reset --soft HEAD~N && git commit -m "wip: <feature-summary>"`
2. Ensure the commit message starts with `wip:` prefix (this signals `/finish-job` to finalize it)
3. Update PROGRESS.md to note "Ready for /review-job"
4. Prompt user to run `/review-job` for code review and simplification

Note: `/finish-job` will amend the `wip:` commit, remove the prefix, and generate a proper conventional commit message.
