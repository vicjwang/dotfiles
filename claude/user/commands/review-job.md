---
description: Code review, simplification, and test verification for implementation
argument-hint: <path-to-plan-file>
model: opus
---

Review implementation for plan at: $ARGUMENTS

## CRITICAL: Step Tracking Required

**Use TodoWrite to track ALL 4 steps.** Before starting, create todos for each step below. Mark each as `in_progress` before starting and `completed` only after finishing.

## Process Discipline

- **Never skip steps silently** - If skipping a step, state the reason BEFORE proceeding
- **Complete before marking done** - Verify each step is fully finished, not just started
- **Document blockers** - If a step cannot complete, explain why and get user input

## Step 1 - Code Review (MANDATORY)

**MUST invoke `code-reviewer` subagent.** Do not skip this step.

⚠️ **DO NOT** start reading files manually or running grep/search commands for review.
⚠️ **DO** immediately invoke: `Task(subagent_type="code-reviewer", ...)`

Pass the plan file path to the agent. The enhanced code-reviewer will check:
- Plan adherence (all tasks implemented, architecture matches, signatures correct)
- **Focus on code changed by this refactor** - flag pre-existing issues separately as "deferred"
- Code standards (naming, magic numbers, fail-fast, structure)
- Security vulnerabilities (input validation, injection, auth issues)
- Correctness problems (logic errors, race conditions, resource leaks)
- Performance issues (inefficient algorithms, N+1 queries)
- Error handling gaps
- Null/missing field handling for external API responses
- Type signature changes that affect public interfaces
- **Deprecated code removal** (can deprecated functions be deleted? check for callers)

Present critical findings to the user.

**Auto-apply** (no approval needed):
- Type hint corrections
- Import consolidation (moving to module level)
- Removing dead/unreachable code

**Require user approval**:
- Logic changes
- API/signature changes
- New abstractions or helpers

If bugs are found, use TDD to fix:
1. Write failing test first (RED)
2. Implement fix (GREEN)
3. Refactor if needed

**After fixing any code review issues:**
Run `uv run pytest` on affected test files immediately to verify fixes don't break existing tests.

## Step 2 - Code Simplification Review (MANDATORY)

**Spawn agents in parallel for efficiency:**
- Spawn ONE `python-simplifier` agent PER **production** Python file touched (exclude tests/)
- Spawn UP TO 2 `python-simplifier` agents for test files (to catch anti-patterns)
- Spawn ONE `code-simplifier` agent for overall review
- Launch ALL agents in a single message with multiple Task tool calls

Example for 5 production files + many test files:
```
Task(subagent_type="python-simplifier", prompt="Analyze /path/to/src/file1.py...")
Task(subagent_type="python-simplifier", prompt="Analyze /path/to/src/file2.py...")
Task(subagent_type="python-simplifier", prompt="Analyze tests/unit/test_foo.py and tests/unit/test_bar.py...")
Task(subagent_type="python-simplifier", prompt="Analyze tests/integration/test_baz.py...")
Task(subagent_type="code-simplifier:code-simplifier", prompt="Review all modified production files...")
```

**CRITICAL: Agents report findings ONLY - no edits.** Instruct each agent to:
- Analyze the assigned file(s)
- Report findings with specific file:line references
- Do NOT make any edits

Review findings for:
- Unnecessary complexity that can be reduced
- Duplicated code that should be extracted
- Verbose patterns that can use Pythonic idioms
- Opportunities to leverage modern Python 3.11+ features

After receiving both reports, YOU (the main agent) make the edits:
- Apply trivial changes that improve readability without altering functionality
- Present significant refactoring suggestions to the user for approval before applying

Run tests to verify functionality did not change.

## Step 3 - Run Tests

Run `uv run pytest` to ensure nothing regressed.

Fix any test failures before proceeding. Make sure the integrity of the tests
are not compromised. Ensure existing functionality remains unchanged.
Ask the user to resolve any ambiguity or conflicts.

**If tests require significant rework (not simple fixes):**
1. Count affected tests and explain the pattern (e.g., "12 tests need baseline-building loops updated for timer API")
2. Ask user: "Fix now (estimated N changes) or skip with TODO?"
3. **Never skip silently** - skipping without approval is a process violation
4. If approved to skip, add `pytest.mark.skip(reason="...")` with clear explanation

## Step 4 - Update PROGRESS.md

If a PROGRESS.md file exists in the plan directory (same location as plan file), update it with:

```markdown
## Code Review (/review-job)

### Findings Addressed

1. **[Finding title]**
   - [Resolution description]

### Test Results After Review

- **Total**: X passed, Y skipped
```

Include:
- Each code review finding and its resolution
- Magic number extractions, test API migrations, etc.
- Final test counts after all fixes
- Update commit history section with new commits

## Output

Provide a summary of:
1. Plan adherence results (pass/fail with details)
2. Code review findings addressed (list each finding and resolution)
3. Code simplifications applied
4. Standards violations fixed
5. Test results

## Next Steps

After review passes, run `/finish-job` to lint, update docs, and commit.

**If deferred refactorings identified**: Ask user "Would you like me to create an implementation plan for [N] deferred refactorings?" before finishing.
