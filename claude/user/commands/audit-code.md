---
description: Audit the code for potential issues
globs: **/*.py
alwaysApply: false
---

# Code Audit

Perform comprehensive code audit for logic bugs, memory leaks, race conditions, and code quality issues.

## Audit Categories

### 1. Memory Leaks & Resource Management

**Patterns to check:**
- Collections (dicts, lists, sets) that grow but never shrink
- Resources allocated but not freed in all code paths
- Cleanup/shutdown methods that don't clear all tracking structures
- Event listeners/callbacks registered but never unregistered
- File handles, connections, or other resources not closed

**Search strategy:**
- Find resource tracking structures (dicts, lists, caches)
- Trace where items are added vs removed
- Check all error paths for cleanup
- Verify cleanup/shutdown methods

### 2. Race Conditions & Concurrency Bugs

**Patterns to check:**
- Paired/dependent tasks that can fail independently
- Shared state accessed without proper synchronization
- Task cancellation that doesn't await completion
- Cleanup logic that assumes execution order
- Multiple code paths modifying same resource

**Search strategy:**
- Find async task creation and management
- Look for shared mutable state
- Check task cancellation patterns
- Verify atomic operations for shared resources

### 3. Inconsistent Error Handling

**Patterns to check:**
- Same operation handled differently in different places
- Some error paths do cleanup, others don't
- Duplicate error handling logic (copy-pasted)
- Missing error handlers in critical sections
- Silent failures (empty except blocks)

**Search strategy:**
- Find exception handlers
- Compare cleanup logic across error paths
- Look for duplicate try/except patterns
- Check for bare except clauses

### 4. Code Duplication & Missing Abstractions

**Patterns to check:**
- Same logic repeated 3+ times
- Similar error handling in multiple functions
- Cleanup code duplicated across error paths
- Missing helper methods for common operations
- Inconsistent implementations of same concept

**Search strategy:**
- Find duplicate code blocks
- Look for similar function signatures
- Check for copy-paste patterns (similar comments)
- Identify missing abstractions

### 5. Deprecated & Dead Code

**Patterns to check:**
- Parameters marked deprecated but still passed
- Config fields loaded but never used
- Constants defined but not imported
- Functions/methods with no callers
- Backward compatibility code that can be removed

**Search strategy:**
- Search for "deprecated", "unused", "backward compatibility"
- Find unused imports and definitions
- Check config parsing vs actual usage
- Verify all code paths have callers

## Audit Process

### Step 1: Determine Scope

Ask user what to audit:
- Specific files/directories
- Entire codebase
- Recent changes only
- Specific pattern (e.g., "audit async task management")

### Step 2: Scan for Patterns

For each category:
1. Use grep/glob to find relevant code
2. Read and analyze identified sections
3. Compare against bug patterns
4. Cross-reference related code

### Step 3: Report Findings

Use severity levels:
- 🔴 **CRITICAL**: Memory leaks, race conditions, data loss
- 🟡 **MODERATE**: Code duplication, inconsistent patterns
- 🟢 **MINOR**: Missing docs, style issues, minor improvements

Format:
```
## Audit Results

### Critical Issues 🔴

**Issue #1: [Brief description]**
- **Location**: file.py:line (or multiple locations)
- **Pattern**: [Which pattern from checklist]
- **Impact**: [What breaks or degrades]
- **Example**: [Code snippet showing the issue]

### Moderate Issues 🟡
[Same format]

### Minor Issues 🟢
[Same format]
```

### Step 4: Design Fixes

For each issue:
1. **Current Code**: Show the problematic code
2. **Problem**: Explain what's wrong and why
3. **Solution**: Propose fix with code example
4. **Rationale**: Explain why fix is correct

If multiple issues have same root cause, group them and propose unified fix.

### Step 5: Create Implementation Plan

Prioritize by:
1. Critical bugs first (memory leaks, race conditions)
2. Moderate issues (code quality, duplication)
3. Minor improvements (docs, style)

Example plan:
```
## Implementation Plan

### Phase 1: Critical Fixes
1. Add centralized cleanup helper (reduces duplication, fixes memory leak)
2. Fix race condition in task cancellation
3. Update all error paths to use cleanup helper

### Phase 2: Code Quality
4. Extract duplicate logic to shared utilities
5. Add missing docstrings
6. Remove deprecated code

### Phase 3: Documentation
7. Update docstrings for cleanup behavior
8. Add code comments for non-obvious logic
```

### Step 6: Execute Fixes

After user approval:
1. Implement fixes systematically
2. Update related tests if needed
3. Verify no new issues introduced

## Common Bug Patterns

### Memory Leak Pattern
```python
# BAD: Dict grows forever
self.tasks = {}
task = create_task(...)
self.tasks[key] = task  # Added but never removed!

# GOOD: Cleanup in all paths
try:
    await task
finally:
    del self.tasks[key]  # Always removed
```

### Race Condition Pattern
```python
# BAD: Paired tasks don't cancel each other
async def producer():
    try:
        await work()
    except Exception:
        cleanup_shared_resource()  # Consumer still running!

# GOOD: Cancel paired task
async def producer():
    try:
        await work()
    except Exception:
        consumer_task.cancel()  # Stop paired task
        await consumer_task
        cleanup_shared_resource()  # Safe now
```

### Duplicate Code Pattern
```python
# BAD: Cleanup duplicated 3 times
def handler_a():
    remove_resource()
    set_metric()
    log_failure()

def handler_b():
    remove_resource()
    set_metric()
    log_failure()

# GOOD: Centralized cleanup
def cleanup_resource():
    remove_resource()
    set_metric()
    log_failure()

def handler_a():
    cleanup_resource()

def handler_b():
    cleanup_resource()
```

## Tips for Effective Audits

1. **Start broad, go deep**: Scan entire scope first, then deep-dive on suspicious areas
2. **Follow the data**: Trace resources from allocation to cleanup
3. **Check all paths**: Success, errors, cancellation, shutdown
4. **Think adversarially**: What could go wrong? What edge cases exist?
5. **Verify assumptions**: Don't assume cleanup happens - verify it
6. **Look for patterns**: Same bug often appears in multiple places
7. **Check symmetry**: If X allocates, X should free (or explicit handoff)

## Language-Specific Considerations

### Python
- Check `__del__` methods are not relied upon
- Verify context managers used for resources
- Look for async task lifecycle management
- Check for circular references preventing GC

### JavaScript/TypeScript
- Check event listeners are removed
- Verify promises are properly awaited
- Look for closure memory leaks
- Check timers/intervals are cleared

### Rust
- Check for `Rc<RefCell<T>>` cycles
- Verify `Drop` implementations
- Look for `unsafe` code patterns
- Check for channel/receiver leaks

### Go
- Check goroutine lifecycle
- Verify channels are closed
- Look for context cancellation
- Check for resource cleanup in defer

## When to Audit

- **After major refactoring**: New patterns may introduce bugs
- **Before production release**: Catch issues early
- **After bug discovery**: Similar bugs may exist elsewhere
- **During code review**: Systematic check of changes
- **Periodic maintenance**: Prevent technical debt accumulation
