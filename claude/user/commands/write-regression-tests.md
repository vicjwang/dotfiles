---
description: Generate and run regression tests based on bugs/issues discussed in current session
argument-hint:
model: sonnet
---

You are tasked with writing regression tests based on the current conversation session.

**Your objective:**
1. Analyze the conversation history to identify any bugs, issues, or edge cases that were discovered and fixed
2. Generate comprehensive regression tests that verify these issues don't resurface
3. Write the tests to the appropriate test files (following the project's existing test structure)
4. Run the tests to ensure they pass

**Guidelines:**
- Focus on tests that prevent regressions - tests that would have caught the bugs discussed in this session
- Follow the existing test patterns and conventions in the codebase (check existing test files first)
- Include both positive cases (expected behavior) and negative cases (edge cases that caused bugs)
- Add clear docstrings/comments explaining what regression each test prevents
- Name tests descriptively: `test_regression_<issue_description>` or `test_<feature>_<edge_case>`
- If the session discussed multiple bugs, create tests for all of them

**Process:**
1. Review the conversation to identify bugs/fixes (use Read tool to check what was changed)
2. Examine existing test files to understand the testing patterns (e.g., pytest, unittest, structure)
3. Write regression tests that would have caught the bugs
4. Run the tests with the appropriate test command (e.g., `uv run pytest tests/...`)
5. Report results to the user, including:
   - What bugs you created regression tests for
   - Where the tests were added
   - Test execution results

**If no bugs were discussed:**
- Politely inform the user that no bugs/issues were found in the current session
- Offer to write general test coverage instead if they'd like
