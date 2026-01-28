---
description: Optimize slow tests by eliminating real sleeps and expensive setup
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(uv run pytest:*)
---

Analyze slow tests and apply proven optimization patterns to speed them up while preserving test integrity.

## Optimization Patterns (apply in order of impact)

### 1. Eliminate Real Sleeps (Highest Impact)

**asyncio.sleep** - Use `fast_async_sleep` fixture:
```python
@pytest.fixture(autouse=True)
def fast_sleep(self, fast_async_sleep):
    """Make asyncio.sleep instant."""
    pass
```

**time.sleep** - Use `fast_time_sleep` fixture:
```python
@pytest.fixture(autouse=True)
def fast_sleep(self, fast_time_sleep):
    """Make time.sleep instant."""
    pass
```

**Staleness/threshold tests** - Use `fast_forward_time` when tests check `time.time()` for age calculations:
```python
@pytest.fixture(autouse=True)
def fast_time(self, fast_forward_time):
    """Advance mocked time during asyncio.sleep."""
    pass
```

### 2. Fixed Time Values Instead of Real Time

Replace `time.time()` calls in test assertions with fixed values:
```python
# BAD: Non-deterministic, requires real sleep
current_time = time.time()
time.sleep(0.1)
new_time = time.time()

# GOOD: Deterministic, no sleep needed
current_time = 1000.0
new_time = current_time + 0.1
```

### 3. Module/Class-Scoped Fixtures for Expensive Setup

For UI tests (MainWindow, Qt widgets), database connections, API clients:
```python
@pytest.fixture(scope="module")
def shared_window(qapp):
    """Create window once per module."""
    with patch('...'):
        window = MainWindow(...)
    yield window

def _reset_window_state(window):
    """Reset mutable state between tests."""
    window._cached_data = None
    window._state_dict = {}
    window.client = Mock()

class TestFeature:
    @pytest.fixture(autouse=True)
    def reset_state(self, shared_window):
        _reset_window_state(shared_window)
```

### 4. Faster Polling in Wait Loops

When using mocked sleep, reduce poll interval:
```python
# Store original for deadline calculations
_original_time = time.time

def wait_for_condition(timeout=1.0, use_real_time=False):
    time_func = _original_time if use_real_time else time.time
    deadline = time_func() + timeout
    while time_func() < deadline:
        if condition_met():
            return True
        time.sleep(0.001)  # 1ms with mock, was 10ms
    return False
```

### 5. Mock External Dependencies

**Network calls** - Always mock HTTP/API calls:
```python
@pytest.fixture
def mock_client():
    client = Mock()
    client.get_data_async = AsyncMock(return_value={'data': []})
    return client
```

**File I/O** - Use `tmp_path` fixture or mock:
```python
def test_file_op(tmp_path):
    config_file = tmp_path / "config.ini"
    config_file.write_text("[section]\nkey=value")
```

**Database** - Use in-memory SQLite or mock:
```python
@pytest.fixture(scope="session")
def db_engine():
    return create_engine("sqlite:///:memory:")
```

### 6. Parallel Test Execution

Add pytest-xdist for CPU-bound test suites:
```bash
uv add pytest-xdist
uv run pytest -n auto  # Use all CPU cores
```

**Note:** Requires tests to be independent (no shared state).

### 7. Lazy Imports and Setup

Defer expensive imports to test runtime:
```python
@pytest.fixture
def heavy_module():
    import heavy_dependency  # Only imported when fixture used
    return heavy_dependency
```

### 8. Hypothesis Fast Profile

Already configured in conftest.py - reduces property tests 90%:
```python
settings.register_profile("fast", max_examples=10, phases=[Phase.generate])
settings.load_profile("fast")
```

### 9. Skip Expensive Tests Conditionally

Mark slow tests for selective execution:
```python
@pytest.mark.slow
def test_integration_full_cycle():
    ...

# Run fast tests only: pytest -m "not slow"
# Run all: pytest
```

### 10. Reduce Test Data Size

Use minimal data sets that still cover edge cases:
```python
# BAD: 1000 items when 3 suffice
@pytest.mark.parametrize("n", range(1000))

# GOOD: Representative cases only
@pytest.mark.parametrize("n", [0, 1, 100])  # Edge, typical, large
```

### 11. Cache Expensive Computations

For test data that's expensive to generate:
```python
@pytest.fixture(scope="session")
def precomputed_test_data():
    """Compute once, reuse across all tests."""
    return expensive_computation()
```

### 12. Use `pytest.raises` Context Manager

More efficient than try/except for exception tests:
```python
# BAD
try:
    func()
    assert False
except ValueError:
    pass

# GOOD
with pytest.raises(ValueError, match="expected message"):
    func()
```

## Execution Steps

1. **Identify slow tests**: `uv run pytest --durations=10`
2. **Profile if needed**: `uv run pytest --profile` (with pytest-profiling)
3. **Categorize by cause**:
   - Real `asyncio.sleep()` calls → Pattern 1a
   - Real `time.sleep()` calls → Pattern 1b
   - Staleness checks with `time.time()` → Pattern 1c or 2
   - Expensive setup per test → Pattern 3
   - Polling loops → Pattern 4
   - Network/API calls → Pattern 5
   - Large test data → Pattern 10
4. **Apply fixes** starting with highest-impact
5. **Verify integrity**: Run tests, check no false positives

## Integrity Verification

After optimization, verify tests still catch bugs:

1. **Temporarily break code** the test covers
2. **Run the test** - it must fail
3. **Restore code**

Red flags that test integrity is compromised:
- Test passes when feature code is deleted
- `for x in items: if cond: assert` without `else: pytest.fail()`
- Mocked time but test doesn't use time-dependent logic
- Over-mocking: mocking the thing being tested

## Target

Tests should run in < 5 seconds total. Module-scoped fixtures provide ~90% speedup for UI tests.
