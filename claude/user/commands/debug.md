---
description: Deep analysis and root cause diagnosis for bugs (read-only)
allowed-tools: Read, Grep, Glob, Bash, Task, WebFetch, mcp__*
---

**ANALYSIS ONLY MODE**: This command does NOT modify code. It provides diagnosis, logging proposals, and solution recommendations for you to review and implement.

## Debugging Protocol

### Phase 1: Question Core Assumptions

**DO NOT start with implementation details.** First question the fundamental architecture:

- **If this is a repeated audit of the same code**: Core assumptions are likely wrong, not just implementation bugs
- **Trace operation timelines**: When does each step happen? What's the ordering?
- **Identify race conditions**: Are operations sequential when they should be concurrent? Or vice versa?
- **Read specifications carefully**: Pay attention to ordering words ("first X then Y" vs "X and Y" vs "while X do Y")
- **Look for implied concurrency**: Specs that say "do A and buffer B" often require simultaneity

### Phase 2: Gather Evidence

**Check logs BEFORE code** - logs often contain the answer faster than code analysis:

1. **Check logs first** (before reading any code):
   - `grep -i "SYMBOL\|error\|fail" run.log | tail -50` - recent activity and errors
   - Look for **timing gaps** - long pauses often reveal the real issue
   - Check timestamps around the reported problem time
2. **Read all relevant files** - understand the full context
3. **Search for related code** - use Grep to find patterns, error handling, state management
4. **Trace data flow** - follow the path from input to output
5. **Identify related symptoms** - multiple issues often share a single root cause

### Phase 3: Root Cause Analysis

**Look for architectural issues, not just bugs:**

- **Timeline analysis**: Add diagnostic logging proposals showing:
  - Timestamps for each operation
  - Sequence numbers or IDs
  - Relative ordering of events
- **Test with worst-case scenarios**: High-frequency, edge cases, race conditions
- **Multiple related symptoms**: Usually indicate ONE root cause, not separate bugs
- **If a fix works briefly then fails**: The fix addressed a symptom, not the root

**When root cause is ambiguous**: It's OKAY to propose extensive logging to verify current logic, state, or hypotheses. Better to over-log during diagnosis than to guess. Focus logging on:
- State transitions and values
- Timing and ordering of operations
- Validation checkpoints
- Boundary conditions

### Phase 4: Solution Design

**Suggest solutions that address the root issue:**

1. **Present multiple approaches** - compare tradeoffs
2. **Consider complete refactoring** if fundamentals are wrong
3. **Prioritize simplicity** - can we eliminate complexity entirely?
4. **Propose specific logging additions**:
   - Exact locations (file:line)
   - What to log (timestamps, IDs, state changes)
   - Log levels (debug/info/warning/error)
   - Include logger.exception() in ALL except blocks

### Phase 5: Validation Strategy

**How to verify the fix:**

- **Test cases**: Normal, edge, worst-case scenarios
- **Metrics to watch**: Latency, memory, error rates
- **Logging to add**: What evidence confirms the fix?
- **Rollback plan**: How to revert if it fails?

## Guidelines

- **Explain your reasoning chain** - make architectural assumptions explicit
- **Be willing to recommend major refactoring** - don't assume current design is correct
- **Focus on "why"** not just "what" - explain the root cause clearly
- **Provide actionable proposals** - specific file:line locations, exact logging statements
- **No shortcuts** - thorough investigation over quick guesses
- **When uncertain, propose diagnostic logging** - it's better to add extensive logging than to guess

## Output Format

Provide a structured analysis:

1. **Timeline/Architecture Analysis**: What's the order of operations? Any race conditions?
   - **For time-sensitive bugs, include a timeline table:**
   ```
   | Time | Event | Impact |
   |------|-------|--------|
   | HH:MM:SS.mmm | What happened | Why it matters |
   ```
2. **Root Cause Hypothesis**: What is the fundamental issue? (If ambiguous, state that clearly)
3. **Evidence**: What supports this hypothesis?
4. **Proposed Solutions**: 2-3 approaches with tradeoffs (or diagnostic logging if root cause unclear)
5. **Diagnostic Logging Proposals**: Specific additions to confirm diagnosis or gather more data
6. **Implementation Plan**: Step-by-step with verification strategy
