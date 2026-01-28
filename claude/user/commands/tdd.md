---
description: Test-driven development - write tests first, then implement to pass
argument-hint: [description-of-feature]
---

Implement the following using TDD with two specialized agents:

$1

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

New code written before tests? **Delete it.** Don't keep as "reference", don't adapt it. Implement fresh from tests.

## Three Scenarios

| Scenario | Test Approach |
|----------|---------------|
| **New code** | Write tests first for desired behavior |
| **Existing code WITH tests** | Modify tests first to reflect new desired behavior |
| **Existing code WITHOUT tests** | Write new tests first for desired behavior |

All three: tests define desired behavior BEFORE implementation.

**Step 1: Write tests (RED phase)**

Choose execution strategy by complexity:
- **Simple (1-2 tests)**: Do directly in main context
- **Medium (3-6 tests)**: Spawn 1 `qa-engineer` agent
- **Large (7+ tests across multiple modules)**: Spawn parallel `qa-engineer` agents by module
  - **CRITICAL**: Split by test file/module to avoid prompt length limits
  - Each agent gets 2-4 test cases max (one file group)
  - Spawn all agents in single message for true parallelism

For agent-based work:
1. Identify scenario: NEW, EXISTING+TESTS, or EXISTING+NO-TESTS
2. For NEW: Design public API, write tests for desired behavior
3. For EXISTING+TESTS: Modify existing tests to reflect new desired behavior
4. For EXISTING+NO-TESTS: Write new tests for desired behavior
5. **CRITICAL - Search ALL tests**: Before modifying, search entire `tests/` directory (unit AND integration) for assertions of the old behavior:
   ```bash
   rg "old_value\|old_behavior" tests/ --type py
   ```
   Integration tests often duplicate assertions from unit tests - both must be updated.
6. Create skeletons (raise NotImplementedError) for new code so tests can run
7. **VERIFY RED**: Run tests, confirm they FAIL for the expected reason (feature missing, not typos)
8. Use `uv run pytest` if project uses uv, otherwise `pytest`
9. Cover edge cases with pytest.mark.parametrize or hypothesis

**Step 2: Implement (GREEN phase)**

Choose execution strategy by complexity:
- **Simple (1-2 functions)**: Do directly in main context
- **Medium (3-6 functions)**: Spawn 1 `python-pro` agent
- **Large (7+ functions, independent modules)**: Spawn parallel `python-pro` agents

**Parallel spawning**: Send ONE message with MULTIPLE Task tool calls (not sequential). Group dependent code in same agent.

For agent-based work:
1. Implement **minimal** code to make tests pass - no extra features
2. **VERIFY GREEN**: Run tests after EVERY change, confirm all pass
3. Make ONE incremental change at a time
4. If tests fail: fix code, not tests (unless test is genuinely wrong)
5. REFACTOR only after green - clean up while keeping tests passing

## Parallelization Quick Reference

| Complexity | RED (Tests) | GREEN (Implement) |
|------------|-------------|-------------------|
| Simple (1-2) | Main context | Main context |
| Medium (3-6) | 1 qa-engineer | 1 python-pro |
| Large (7+) | N qa-engineer (by module) | N python-pro (by dependency) |

**Independence criteria**: Different modules, separate test files, no shared state → parallel agents
**Dependence criteria**: Imports from modified file, shared fixtures → same agent, sequential

## Red Flags - STOP and Restart

- New code exists before test (delete it, start over)
- Test passes immediately without implementation
- Can't explain why test failed
- Rationalizing "just this once" or "too simple to test"
- Only searched unit tests, not integration tests (search ALL of `tests/`)

## Verification Checklist

Before marking complete:
- [ ] Searched ALL test directories (unit + integration) for old behavior assertions
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass
- [ ] All tests pass with clean output

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

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API first. Write assertion first. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |

## Qt/PyQt: Avoiding Hanging Tests

Tests hang when Qt dialogs block on `exec()`. Quick fixes:

1. **Mock dialog classes** before methods that open them:
   ```python
   with patch('module.ChildDialog') as mock:
       parent._open_child_dialog()  # Won't block
   ```

2. **Use lambda for button signals** (enables patching):
   ```python
   btn.clicked.connect(lambda: self._method())  # Patchable
   # NOT: btn.clicked.connect(self._method)      # Stores reference
   ```

3. **Test child widgets directly** (Qt C++ rejects MagicMock in addWidget):
   ```python
   table = StrategyTable(config=mock_config)  # Direct
   # NOT: MainWindow with mocked StrategyTable  # Fails
   ```
