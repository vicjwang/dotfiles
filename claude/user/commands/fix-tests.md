---
description: Run pytest and fix failing tests
argument-hint: [test_path?]
model: opus
---

Run the test suite and fix any failing tests.

## Instructions

1. Run the test command: `uv run pytest --no-cov $ARGUMENTS`
   - Use `--no-cov` to skip coverage (2x faster iteration)
   - If no arguments provided, run all tests
   - If a path or pattern is provided, run only those tests

2. **Before fixing individual tests**, check for systemic issues:
   - If >5 tests fail with similar errors (e.g., missing config fields, renamed attributes), identify the pattern first
   - Check `tests/conftest.py` for existing helper functions before writing manual fixtures
   - Fix via sed/batch replacement, not one-by-one edits
   - Common patterns: config field renames, removed classes, new required arguments

3. For multiple unrelated failing test files, use parallel qa-engineer agents:
   - Launch one agent per file for concurrent fixing
   - Each agent should run targeted tests after fixing: `uv run pytest <file> -x --no-cov`

4. For each failing test:
   - Analyze the failure message and traceback
   - Determine if the issue is in the test or the production code
   - Fix the root cause (prefer fixing production code bugs over adjusting tests)
   - Re-run the specific failing test to verify the fix

5. Continue until all tests pass

6. Provide a summary of:
   - How many tests were failing
   - What was fixed and why
   - Any patterns or systemic issues discovered

## Important

- Do NOT modify tests to make them pass unless the test itself is incorrect
- If a test expectation is wrong, explain why before changing it
- Run the full test suite at the end to ensure no regressions
