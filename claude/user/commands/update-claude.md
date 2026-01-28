---
description: Update CLAUDE.md with learnings, avoiding redundancy
argument-hint: [path?]
allowed-tools: Read, Glob, Grep
model: sonnet
---

Update the appropriate CLAUDE.md file with relevant learnings from this conversation, applying condensation techniques to maintain clarity and conciseness.

# CLAUDE.md Hierarchy

**Structure:**
- **Root CLAUDE.md**: High-level architecture, project-wide patterns, cross-cutting concerns
- **Nested CLAUDE.md** (e.g., `tests/CLAUDE.md`, `ui/CLAUDE.md`): Module-specific patterns, conventions, gotchas

**Placement rules:**
- Architecture/data flow/component relationships → root
- Module-specific patterns/conventions/gotchas → nested (create if doesn't exist)
- If learning applies to specific subdirectory with 3+ related files → nested
- If learning is cross-cutting or affects multiple modules → root

**When to create nested CLAUDE.md:**
- Subdirectory has non-obvious patterns worth documenting
- Multiple related gotchas for that module
- Testing patterns specific to that area
- Complex internal conventions

# Smart Filtering - When to Update

**Skip updating for:**
- Trivial conversations (simple Q&A, basic file reads)
- Routine tasks (standard debugging, typical refactoring)
- Information already well-documented
- Frequently-changing metrics (test counts, line counts, file counts) - these become stale quickly

**DO update for:**
- Significant learnings or insights
- Bug fixes with important context
- Architectural decisions or design patterns
- Workflow improvements
- Critical warnings or "gotchas"
- Performance optimizations

# Process

## 1. Determine Target File

- Identify which module/subdirectory the learning relates to
- Use Glob to find existing CLAUDE.md files: `**/CLAUDE.md`
- **Decision tree:**
  1. Learning is module-specific AND nested CLAUDE.md exists → update nested
  2. Learning is module-specific AND no nested CLAUDE.md → create nested (if warranted) or add to root
  3. Learning is architectural/cross-cutting → update root
- Use `$1/CLAUDE.md` if path explicitly provided

## 2. Pre-Update Analysis

- Read the target CLAUDE.md file
- Use Grep to search for similar/related content using relevant keywords
- Identify the most appropriate section for new information
- Check if similar information already exists

## 3. Apply Condensation Techniques

**If adding new content:**
- Use bullet points and structured formats (not prose)
- Apply inline notation to reduce verbosity (e.g., "param_a/param_b" instead of separate bullets)
- Group related information together
- Extract only the essence - be concise and scannable
- No verbose explanations - get to the point
- Omit volatile metrics (test counts, LOC, coverage %) - prefer qualitative descriptions

**If similar content exists:**
- Merge/consolidate rather than append
- Update existing content with new insights
- Remove outdated or contradicting information

**Reorganization allowed:**
- Can reorganize sections if it improves clarity
- Can consolidate similar sections to reduce character count
- Can restructure for better scannability
- MUST NOT lose any meaningful information in the process

## 4. Write Changes

- Edits will prompt for approval so you can review changes
- Maintain consistent formatting with existing style
- Ensure no information loss during consolidation

# Examples of Good Updates

**Instead of:**
```
Added new feature for handling API rate limits. We implemented a token bucket algorithm with exponential backoff. The rate limiter tracks requests per minute and implements a safety margin to prevent hitting limits. It also includes jitter to prevent thundering herd problems.
```

**Do:**
```
**Rate Limiting:**
- Token bucket with exponential backoff
- Tracks requests/min with safety margin
- Jitter prevents thundering herd
```

**Instead of adding a new section, merge:**
```
### Existing Section: Error Handling
- Handle connection errors with retry
[NEW] - Rate limit errors: exponential backoff + jitter
```

**Nested CLAUDE.md example** (`detectors/CLAUDE.md`):
```
# Detectors

## Patterns
- All detectors inherit from `BaseDetector`, implement `process_update()`
- SDC integration: Pass `data_capture` + `export_enabled=True` for spike export

## Gotchas
- PriceSpikeDetector: Must check BOTH z-score AND bps threshold
- TieredDetector: Requires `data_capture` parameter (keyword-only)
```
