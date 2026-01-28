---
description: TDD-driven Python refactoring with atomic changes and incremental commits
---

# TDD Refactoring Command

Execute a Python refactoring using RED-GREEN-REFACTOR methodology with lessons learned from complex multi-file refactors.

## User Request
$ARGUMENTS

## Phase 0: Scope Analysis (CRITICAL)

Before any code changes, analyze the full scope:

1. **Identify all affected symbols** (classes, functions, variables, field names):
   ```bash
   rg "old_name" --type py -c  # Count occurrences
   rg "old_name" --type py -l  # List affected files
   ```

2. **Create a mapping file** if renaming multiple symbols:
   ```
   # mapping.txt (do not commit)
   old_name -> new_name
   OldClass -> NewClass
   old_field -> new_field
   ```

3. **Categorize affected files**:
   - Production code (priority 1)
   - Test fixtures (priority 2)
   - Test files (priority 3)

4. **Check for hidden dependencies**:
   - Imports across modules
   - Mock objects using old names
   - Config files, JSON schemas
   - String literals containing symbol names

5. **Check for inline config templates in tests** (often missed):
   ```bash
   # Find multi-line config template strings
   rg '\[SECTION_NAME\]' tests/ --type py -B2 -A5 | head -50

   # Check field naming conventions (short vs prefixed)
   rg 'FIELD_NAME|SECTION_FIELD_NAME' tests/ --type py
   ```
   **Common patterns**: `"""[SECTION]\nFIELD = value"""`, dict-to-config converters
   **Watch for**: Section may use prefixed field names (`SPIKE_EXPORT_ENABLED` not `ENABLED`)

6. **Find ALL test fixtures that will need changes** (CRITICAL - often missed):
   ```bash
   # Local mock_config fixtures shadow conftest.py - must update ALL of them
   rg 'def mock_config' tests/ -l
   rg '@pytest.fixture' tests/ -A2 | rg -B2 'config'

   # Count to estimate scope
   rg 'def mock_config' tests/ -c
   ```
   **If >10 local fixtures**: Plan batch update strategy BEFORE starting refactor.
   **Common trap**: Updating only conftest.py, then fixing files one-by-one as tests fail.

7. **Estimate scope**: If >20 files affected, warn user and suggest breaking into smaller refactors.

8. **Establish baseline**: Run existing tests BEFORE any changes:
   ```bash
   uv run pytest tests/ -x --no-cov 2>&1 | tail -20
   ```
   Note any pre-existing failures to distinguish from refactor-introduced failures.

## Phase 1: RED - Write Failing Tests

**Goal**: Create executable specification of the desired post-refactor behavior. Tests MUST fail initially.

### 1.1 Write Tests for Target Behavior

Write tests that assert what the code should do AFTER the refactor:

```python
# test_new_behavior.py
def test_new_api_returns_expected_value():
    """Test the NEW interface - will fail until implementation exists."""
    result = new_function(input_data)  # Function doesn't exist yet
    assert result == expected_output

def test_renamed_field_is_accessible():
    """Test renamed field - will fail until migration complete."""
    config = create_config()
    assert config.new_field_name == expected_value  # Field doesn't exist yet
```

Use `pytest.mark.parametrize` for multiple input variations:
```python
@pytest.mark.parametrize("input_val,expected", [
    (1, "one"),
    (2, "two"),
])
def test_new_behavior_parametrized(input_val, expected):
    assert new_function(input_val) == expected
```

### 1.2 Verify Tests Are Valid (Syntax Check)

```bash
uv run pytest tests/path/to/new_tests.py --collect-only
```

### 1.3 Confirm RED State (Tests MUST Fail)

**CRITICAL**: Run the new tests and verify they FAIL:

```bash
uv run pytest tests/path/to/new_tests.py -x --no-cov 2>&1 | tail -30
```

Expected output: `FAILED` or `ERROR` (e.g., `ImportError`, `AttributeError`, `NameError`)

**If tests pass**: Your tests are not testing new behavior - rewrite them to assert the target state, not the current state.

### 1.4 Commit RED State

```bash
git add tests/path/to/new_tests.py
git commit -m "wip: RED - add failing tests for [refactor goal]"
```

## Phase 2: GREEN - Minimal Implementation

**Goal**: Make failing tests pass with MINIMAL code changes. No cleanup, no optimization - just make it work.

### 2.1 Production Code First (Minimal Changes)

Change production code to make tests pass. Keep backward compatibility temporarily if needed:

```python
# BEFORE
class Config:
    old_field: int

# GREEN (minimal - add new, keep old temporarily)
class Config:
    old_field: int  # Keep for now
    new_field: int  # Add new
```

After each file change:
```bash
uv run ruff check path/to/file.py
uv run pytest tests/path/to/new_tests.py -x --no-cov  # Run ONLY new tests
```

**Stop as soon as tests pass** - resist the urge to clean up.

### 2.2 Commit GREEN State

```bash
git add -A
git commit -m "wip: GREEN - tests pass for [refactor goal]"
```

### 2.3 Verify Full Suite Still Passes

```bash
uv run pytest tests/ -x --no-cov
```

If other tests break, fix with minimal changes to restore GREEN, then commit:
```bash
git commit -m "wip: GREEN - fix broken tests"
```

## Phase 3: REFACTOR - Clean Up While Staying Green

**Goal**: Improve code quality while keeping ALL tests passing. Run tests frequently.

### 3.1 Update Test Fixtures

Update shared fixtures (conftest.py, fixture files).

**Fixture architecture matters** - different fixture types need different handling:

| Fixture Type | Example | Refactor Approach |
|--------------|---------|-------------------|
| Returns Mock | `config = Mock(); config.field = X; return config` | Add new attributes to Mock |
| Returns dataclass | `return MyDataclass(field=X)` | May need new fixture + param changes |
| Uses replace() | `return replace(create_X(), field=Y)` | Split replace() or add new fixture |

**When fixture returns dataclass directly:**
```python
# BEFORE: Single fixture returning dataclass
@pytest.fixture
def my_config():
    return replace(create_config(), old_field=True, moved_field=5)

# AFTER: Split into two fixtures
@pytest.fixture
def my_config():
    return replace(create_config(), old_field=True)

@pytest.fixture
def my_new_config():
    return replace(create_new_config(), moved_field=5)

@pytest.fixture
def full_config(my_config, my_new_config):
    mock = Mock()
    mock.old = my_config
    mock.new = my_new_config
    return mock
```

After fixture changes, verify GREEN:
```bash
uv run pytest tests/ -x --no-cov
git commit -m "wip: REFACTOR - update fixtures"
```

### 3.2 Update Test Files to Use New APIs

After each test file update, verify GREEN:
```bash
uv run pytest tests/unit/test_updated_file.py -x --no-cov
```

### 3.3 Remove Backward Compatibility

Now remove temporary backward compat added in Phase 2:

```python
# Remove old_field entirely
class Config:
    new_field: int  # Only new field remains
```

After removal, verify GREEN:
```bash
uv run pytest tests/ -x --no-cov
git commit -m "wip: REFACTOR - remove backward compat"
```

### 3.4 Bulk Replacements (When Applicable)

For large-scale renames, use atomic bulk replacement:

```bash
# Preview first
rg "old_name" --type py -l

# Execute with sd (safer than sed)
sd "old_name" "new_name" $(rg "old_name" --type py -l | tr '\n' ' ')

# IMMEDIATELY verify GREEN
uv run ruff check .
uv run pytest tests/ -x --no-cov
```

**CRITICAL**: After EACH sd command, verify GREEN before proceeding.

**NEVER** use partial replacements like `sd 't1_min_' 't1_'` - always use complete old->new mappings.

## Bulk Replacement Patterns Reference

### Categorize Patterns BEFORE Bulk Changes (CRITICAL)

Different code patterns require different fixes. Before any bulk operation:

```bash
# See context around each occurrence to identify patterns
rg -B5 'field_name' tests/ --type py | head -100
```

**Common pattern categories** (in order of fix complexity):

| Pattern | Example | Fix Approach |
|---------|---------|--------------|
| Attribute access | `config.old.field` | Simple sd replacement |
| Attribute assignment | `obj.field = value` | Change target object |
| replace() with field | `replace(obj, field=...)` | Split into two replace() calls |
| Direct construction | `MyClass(field=...)` | Remove field, may need other fields added |
| Fixture returning dataclass | `return MyDataclass(...)` | May need new fixture + signature change |
| Mock with attribute | `mock.field = ...` | Change mock structure |

**Fix in dependency order:**
1. Shared fixtures (conftest.py, fixtures_*.py)
2. Production code dataclass changes
3. Dataclass direct constructions in tests
4. replace() calls (split into multiple)
5. Attribute access patterns (simple sd)
6. Attribute assignments

### Dataclass Field Migration (Special Case)

When removing/moving fields from a dataclass:

**CRITICAL**: `dataclasses.replace()` fails immediately if you pass a field that doesn't exist:
```python
# After removing spike_export_enabled from TieredDetectorConfig:
replace(create_tiered_detector_config(), spike_export_enabled=True)
# → TypeError: field spike_export_enabled is not in dataclass
```

**Test on ONE file first** before bulk changes:
```bash
# 1. Make dataclass change
# 2. Run tests on a single file to see error patterns
uv run pytest tests/unit/test_one_file.py -x --no-cov 2>&1 | head -50
# 3. Understand the error, then fix systematically
# 4. Verify GREEN after each fix
```

**Splitting replace() calls** (when moving fields to new dataclass):
```python
# BEFORE: Fields in old_config
config.old_config = replace(create_old_config(),
    field_a=1,
    moved_field=True,  # ← needs to move
)

# AFTER: Split into two replace() calls
config.old_config = replace(create_old_config(),
    field_a=1,
)
config.new_config = replace(create_new_config(),
    moved_field=True,
)
```

### Config Section Migration Pattern

When moving fields from one config section to another (e.g., `[TIERED_DETECTOR]` → `[SPIKE_EXPORT]`):

**Order matters - do these steps sequentially:**

1. **Add fixture helper for new config** (conftest.py):
   ```python
   def create_new_section_config():
       return NewSectionConfig(field1=val1, field2=val2)
   ```

2. **Find ALL mock configs** that use the old section:
   ```bash
   rg 'config\.old_section = create_old_section_config' tests/ -l
   ```

3. **Add new section to ALL mock configs** before removing from old:
   ```python
   # Every mock config needs BOTH until migration complete
   config.old_section = create_old_section_config()
   config.new_section = create_new_section_config()  # Add this
   ```

4. **Verify GREEN** after adding new section everywhere

5. **Only then** remove fields from old dataclass

**Why this order**: If you remove fields first, `AttributeError` cascades through all tests that construct the old config. Adding new config first means tests pass throughout migration.

### Fixture Proliferation Problem (CRITICAL)

**The whack-a-mole trap**: Many test files have their OWN `mock_config` fixture that shadows the global one from `conftest.py`. If you only update `conftest.py`, tests in files with local fixtures still fail.

**Find ALL mock_config fixtures BEFORE making any changes:**
```bash
# Find all local mock_config fixtures (not just conftest.py)
rg '@pytest.fixture' tests/ -A2 | rg -B2 'mock_config'
rg 'def mock_config' tests/ -l

# Count them to estimate scope
rg 'def mock_config' tests/ -c
```

**Batch update ALL fixtures at once, not one-by-one:**
```bash
# Example: Adding config.spike_export to all mock_config fixtures

# Step 1: Update conftest.py helper/fixture first
# Step 2: Find files that need the new attribute
rg -l 'config\.tiered_detector = ' tests/ | wc -l  # ~30 files

# Step 3: Add to ALL files in one batch operation
# (Manually or via script - sd may struggle with multiline additions)

# Step 4: Run full test suite ONCE after all changes - verify GREEN
uv run pytest tests/ -x --no-cov
```

**Why batch matters**: Running tests after each file fix wastes time. If 30 files need the same change, fix all 30, then test once.

**Finding files by indent level** (for bulk add):
```bash
# Module/function level (4-space indent)
rg '^    config\.old_section = ' tests/ -l

# Class method level (8-space indent)
rg '^        config\.old_section = ' tests/ -l
```

### Indentation-Aware Bulk Replacement

`sd` with `\n    ` always adds 4 spaces. This breaks code in class methods (need 8 spaces).

**Problem:**
```bash
sd 'line1' 'line1\n    line2' file.py  # Always 4-space indent
```

**Solutions:**
1. **Separate commands per context**: Different sd patterns for module-level vs class methods
2. **Use file-specific patterns**: Include enough context to be unique
3. **Manual edits for mixed files**: When indentation varies within a file

```bash
# Module-level (4 spaces)
sd 'config = func()' 'config = func()\n    config.attr = value' module_level.py

# Class methods (8 spaces) - include more context
sd '        config = func()' '        config = func()\n        config.attr = value' class_file.py
```

**CRITICAL: Verify GREEN after EACH sd command:**
```bash
uv run ruff check tests/ 2>&1 | rg 'invalid-syntax'
uv run pytest tests/ -x --no-cov
```
Don't batch multiple sd commands before checking - syntax errors compound and become harder to diagnose.

### Double-Prefix Prevention

When running sd multiple times, patterns can match their own replacement text:

```bash
# BAD: Running twice creates SPIKE_SPIKE_EXPORT_DIR
sd 'EXPORT_DIR' 'SPIKE_EXPORT_DIR' file.py
sd 'EXPORT_DIR' 'SPIKE_EXPORT_DIR' file.py  # Matches SPIKE_EXPORT_DIR!

# GOOD: Use anchors or unique patterns
sd '\bEXPORT_DIR\b' 'SPIKE_EXPORT_DIR' file.py      # Word boundary
sd '^EXPORT_DIR = ' 'SPIKE_EXPORT_DIR = ' file.py   # Line start + context
sd 'old\.EXPORT_DIR' 'new.SPIKE_EXPORT_DIR' file.py # Include object prefix
```

**Safest approach**: Run sd once per pattern, verify GREEN, commit before next pattern.

### Import Handling for Bulk Changes

Adding code that uses new symbols requires import updates:

```bash
# Step 1: Add the code line
sd 'config.old = create_old()' 'config.old = create_old()\n    config.new = create_new()' file.py

# Step 2: Update imports (separate command)
sd 'from module import create_old' 'from module import create_old, create_new' file.py

# Step 3: Verify GREEN
uv run pytest tests/ -x --no-cov
```

**Import patterns vary** - may need multiple sd commands:
- `from module import A` → `from module import A, B`
- `from module import A, C` → `from module import A, B, C`
- `import module` → may need different approach

### Import Pattern Robustness (CRITICAL)

**Avoid `$` anchor in import patterns** - it fails when line has additional imports:

```bash
# BAD: $ anchor misses lines with multiple imports
sd 'from module import A$' 'from module import A, B' file.py
# Misses: "from module import A, C" (no match due to $)

# GOOD: Omit $ anchor or use flexible pattern
sd 'from module import A' 'from module import A, B' file.py
```

**Verify bulk operations succeeded:**
```bash
# After sd, confirm old pattern is gone
rg 'old_pattern' tests/ --type py -l
# If output is non-empty, some files weren't updated
```

## Phase 4: Final Verification

### Incremental Test Verification

Before running full suite, test ONE file from each affected category:

```bash
# 1. Test one modified fixture file first
uv run pytest tests/unit/test_one_affected.py -x --no-cov 2>&1 | tail -30

# 2. If passes, run broader scope
uv run pytest tests/unit/ -x --no-cov

# 3. Only then run full suite
uv run pytest --no-cov
```

### Full Suite Verification

After incremental checks pass:

```bash
# Full test suite - must be GREEN
uv run pytest tests/ -x

# Type checking (if applicable)
uv run mypy .

# Lint
uv run ruff check .
```

## Anti-Patterns to Avoid

Based on session learnings:

| Anti-Pattern | Why It Fails | Do Instead |
|--------------|--------------|------------|
| Writing tests that pass immediately | Not RED - tests don't specify new behavior | Ensure tests FAIL before implementation |
| Implementing before tests fail | Skipping RED means no clear target | Write failing tests first |
| Cleaning up during GREEN phase | Conflates phases, harder to debug | Keep GREEN minimal, refactor separately |
| Refactoring without verifying GREEN | Can break tests without noticing | Run tests after EACH refactor step |
| Parallel tasks with shared file deps | Conflicting changes | Sequential for shared files |
| `git checkout` to fix breakage | Reverts unrelated good changes | Revert specific commits only |
| Ad-hoc field name replacements | `t1_min_` → `t1_` creates wrong names | Full old→new mapping |
| Mixing backward compat + removal | Agents conflict | Pick one approach upfront |
| Fixing tests before production code | Tests fail for wrong reasons | Production first |
| Assuming "bulk replace" is one operation | Different code patterns need different fixes | Categorize patterns first |
| Using sd with fixed indentation | Class methods need 8 spaces, module level needs 4 | Account for context |
| Bulk replace without import updates | New code requires imports | Handle imports separately |
| `sd 'pattern$'` for imports | `$` misses lines with multiple imports | Omit anchor or use flexible pattern |
| Trust plan as exhaustive | Plans miss inline config templates, cascading changes | Verify with rg after each step |
| Run full suite immediately | 2000+ tests = slow feedback loop | Test one file first |
| Assume config field names | `[SECTION]` may use `SECTION_FIELD_NAME` | Check actual config parser |
| Batch multiple sd commands | Syntax errors compound, hard to diagnose | Verify GREEN after EACH sd |
| sd without word boundaries | `sd 'DIR' 'NEW_DIR'` matches `SPIKE_DIR` too | Use `\b` or context |
| Remove config fields before adding new | `AttributeError` cascades through all tests | Add new fixture first, then remove old |
| Fix one test file, run suite, repeat | 30 files × full suite = hours wasted | Batch fix ALL, run suite ONCE |
| Only update conftest.py fixture | Local mock_config fixtures shadow global | Find ALL mock_config fixtures upfront |

## RED-GREEN-REFACTOR Summary

```
┌─────────────────────────────────────────────────────────────────┐
│  RED: Write tests that FAIL                                     │
│  - Assert desired post-refactor behavior                        │
│  - Verify tests actually fail (ImportError, AttributeError)     │
│  - Commit: "wip: RED - add failing tests for X"                 │
├─────────────────────────────────────────────────────────────────┤
│  GREEN: MINIMAL code to make tests pass                         │
│  - Just enough to pass, no cleanup                              │
│  - Backward compat OK temporarily                               │
│  - Commit: "wip: GREEN - tests pass for X"                      │
├─────────────────────────────────────────────────────────────────┤
│  REFACTOR: Clean up while staying GREEN                         │
│  - Run tests after EVERY change                                 │
│  - Remove backward compat                                       │
│  - Bulk replacements with verification                          │
│  - Commit: "wip: REFACTOR - description"                        │
└─────────────────────────────────────────────────────────────────┘
```

## Refactor Quality Principles

### Tests Define the Target State

The RED phase creates executable specification:
- Clear definition of "done" (all tests pass)
- Pre-existing vs new failures are distinguishable
- Refactored code validated against intended behavior, not legacy behavior

### Prefer Clean Breaks Over Backward Compat Shims

**Bad**: Adding backward compat properties to ease migration
```python
@property
def old_name(self) -> int:
    """Backward compat: Use new_name instead."""
    return self.new_name
```

**Good**: Remove old names entirely, let errors surface immediately
- Old names → `AttributeError` (fail-fast)
- Forces callers to update (no silent dual-path code)
- Less code to maintain long-term

### Aggressive Cleanup > Conservative Changes

- More lines deleted = less maintenance debt
- Don't add shims "just in case" - remove obsolete code entirely
- If something is unused, delete it completely (no `_unused` renames, re-exports, or `# removed` comments)

### Document Changes in Detail

Per-task notes should include:
- Date completed
- Test counts (e.g., "All 22 tests pass")
- Files modified
- Specific items changed
- Blockers/learnings

**Example**:
```
- [x] **Task 2**: Remove Deprecated Dataclasses
  - Delete: `DetectionConfig`, `OffsetsConfig`, `Tier0FilterConfig`
  - Notes: Completed 2026-01-09. Updated spike_qualifier.py, spike_tier_classifier.py.
    Deleted 4 dataclasses, 4 properties. All 8 tests pass.
```

## Refactoring Patterns Reference

### Extract Method
- When: Method >30 lines, multiple responsibilities
- Risk: Low-Medium (variable scope changes)

### Rename Symbol
- When: Name doesn't describe purpose
- Risk: Medium (references in other files)
- **Always**: Use bulk replacement across entire codebase

### Remove Defaults / Add Required Fields
- When: Enforcing fail-fast behavior
- Risk: High (breaks all callers)
- **Always**: Update all constructors atomically

### Extract Class
- When: Class >300 lines, low cohesion
- Risk: High (breaking dependencies)
- **Always**: Test thoroughly before and after

## Completion

When refactoring is complete:

1. Squash wip commits: `git reset --soft HEAD~N && git commit -m "refactor: description"`
2. Run full test suite one more time (verify GREEN)
3. Update any affected documentation
