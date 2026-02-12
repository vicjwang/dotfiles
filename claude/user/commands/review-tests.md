---
description: Review test files for quality, correctness, and best practices
argument-hint: [test files or paths?]
allowed-tools: Read, Glob, Grep, Task, Edit, Write, Bash(pytest:*), AskUserQuestion
model: opus
---

Review the test files provided in $ARGUMENTS. If no files are specified, infer the relevant test files from the current conversation context or recent changes.

For each test, evaluate against these criteria:

## 1. Tests Behavior, Not Implementation
- Tests should assert on observable outcomes (return values, state changes, side effects), not internal method calls or implementation details.
- Flag tests that would break if the implementation is refactored without changing behavior.

## 2. Appropriate Mock Usage
- Mocks should only be used at system boundaries (network, filesystem, external APIs).
- Flag tests where excessive mocking makes the test meaningless — if everything is mocked, nothing is tested.
- Verify mocks use `spec=RealClass` (never bare `Mock()`).
- Prefer real objects and in-memory fakes over mocks when feasible.

## 3. DRY Setup via Fixtures
- Identify duplicated setup code across tests and recommend `@pytest.fixture` extraction.
- Check that fixtures are appropriately scoped (function, class, module, session).
- Flag copy-pasted helper objects that should be shared fixtures.

## 4. Parameterization and Property-Based Testing
- Identify tests with repetitive structure that differ only in inputs/outputs — recommend `@pytest.mark.parametrize`.
- For functions with broad input domains (numeric ranges, string formats, collections), suggest `hypothesis` strategies where appropriate.
- Verify existing parametrize/hypothesis usage is correct (proper id naming, valid strategies).

## 5. Edge Case Coverage
- Check for missing edge cases: empty inputs, None/null, boundary values, zero, negative numbers, very large inputs, unicode, concurrent access.
- Flag happy-path-only tests.
- Ensure error paths are tested (exceptions raised, invalid inputs rejected).

## 6. Correctness of Assertions
- Verify tests actually enforce the desired functionality — not just "doesn't crash."
- Flag tests missing assertions or with trivially-true assertions.
- Check for the false-positive pattern: loops that should use `else: pytest.fail()`.
- Ensure assertion messages are helpful for debugging.

## 7. Alignment with Documentation
- Cross-reference test expectations against docstrings, CLAUDE.md, and README documentation.
- Flag tests whose assumptions contradict documented behavior.
- Note any documented behavior that lacks test coverage.

## 8. Redundant, Unnecessary, and Overkill Tests
- **Duplicate coverage**: Two test files testing the same behavior/component with overlapping assertions.
- **Trivial tests**: Tests verifying obvious behavior (e.g., "attribute exists", "constructor works", dataclass field assignment).
- **Overkill**: Tests with excessive setup for trivial assertions, or testing internal implementation details that no real bug would trigger.
- **Superseded tests**: Tests made obsolete by newer, more comprehensive tests in other files.
- **Over-specified tests**: Tests asserting too many implementation details, making refactoring impossible (e.g., testing private attributes, internal data structures, exact dict/list structure when order doesn't matter).
- **Testing stdlib/framework**: Tests verifying Python built-in behavior (e.g., `max()` returns maximum, `sorted()` sorts correctly, dataclass `__eq__` works).
- **Stubbed tests**: Incomplete tests with `assert ... or True` or `@pytest.mark.skip` without clear plan to complete.
- **Already covered elsewhere**: For each test class/method, check if other test files already verify the same behavior. Create a coverage map showing "Test X → already covered by Test Y in file Z". Example: Test that constructs a config object and asserts field value may be redundant if another test file already does config parsing and field verification.
- For each redundant test, explain WHY it's unnecessary and what (if anything) already covers it.

## 9. DO NOT Delete These (Common False Positives)

Before recommending deletion, verify the test doesn't fall into these categories:

**Unit tests for standalone classes with non-trivial logic:**
- Classes used internally but with complex behavior (memory management, expiration, bucketing, caching)
- Example: `TestBucketedTopN` tests memory-bounded top-N tracking with bucket cycling and expiration — this is non-trivial logic that deserves direct unit tests even though BucketedTopN is only used by DangerAnalyzer
- Rule: If the class has >3 methods with conditional logic, it deserves unit tests

**Property-based tests verifying invariants through the full pipeline:**
- Hypothesis tests that exercise real components (not mocks) with randomized inputs
- Example: `TestDangerRankInvariant` uses hypothesis to verify danger_rank behavior through DangerAnalyzer + BucketedTopN pipeline — NOT just testing stdlib `max()`
- Rule: If the test uses `@given` with real objects and verifies component interaction, keep it

**Public API methods with dynamic logic:**
- Methods that construct/transform data structures with conditional logic
- Example: `get_tier_evaluation_metadata()` with branching, optional fields, dynamic dict construction
- Rule: If a public getter has >5 lines with conditionals, it needs tests

**Integration tests with real components (even if similar to unit tests):**
- Tests using actual objects instead of mocks to verify end-to-end behavior
- Keep even if unit tests exist — integration tests catch composition bugs mocks miss
- Rule: Prefer keeping integration over unit when choosing what to delete

**Thread safety and concurrency tests:**
- Any test with `threading.Thread`, `ThreadPoolExecutor`, race conditions
- These are hard to write and catch real production bugs
- Rule: Never delete concurrency tests

## Output Format
For each file reviewed, provide:
1. **Summary**: Overall quality assessment (Good / Needs Work / Major Issues)
2. **Issues**: Specific problems found, grouped by criteria number above
3. **Recommendations**: Concrete suggestions with code examples where helpful

After reviewing all files, provide a prioritized action list of the most impactful improvements.
