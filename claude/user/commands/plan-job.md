---
description: Create comprehensive implementation plan with codebase exploration and technical design
argument-hint: [feature-name] [small|large]
model: opus
---

Create a comprehensive implementation plan for: $ARGUMENTS

**OUTPUT REQUIREMENTS** (check FIRST before any exploration):
- Parse arguments for `small`, `large`/`big`, and feature name
- `small` → Use EnterPlanMode (no files)
- Default/`large` → Create `docs/<feature-name>/PLAN.md` AND `docs/<feature-name>/PROGRESS.md`
- NEVER use `.claude/plans/` directory

**CRITICAL: This is a PLANNING phase only. DO NOT write any implementation code. DO NOT create source files. Your output is the plan only (either as a document file or in Plan mode for `small`).**

## Instructions

Parse the arguments:
- `<feature-name>` (optional): kebab-case name for the feature. If not provided, generate a descriptive kebab-case name from the user's prompt (e.g., "add retry logic to API calls" → `api-retry-logic`)
- `small`: Use built-in Plan mode (no file output)
- `large` or `big`: Create plan at `docs/<feature-name>/PLAN.md` + PROGRESS.md tracking file
- No size argument: Default to `docs/<feature-name>/PLAN.md`

Arguments can appear in any order. Detect `small`/`large`/`big` keywords; treat other arguments as the feature name.

## Phase 1 - Explore

Thoroughly explore the codebase to understand:
1. Current abstractions and code structure
2. Existing patterns and conventions
3. Possible integration points that may need to change
4. Dependencies and relationships between components

**For refactoring/deletion tasks**, explicitly identify all usages:
- Run `grep -rn "ClassName\|function_name" --include="*.py"` for items being removed/renamed
- Quantify test file impact: `grep -rn "pattern" tests/ | wc -l`
- List ALL files that need updates (not just "multiple test files")

**No shortcuts** - read the relevant files, understand the architecture, trace data flows.

Use the Explore agent liberally to search for:
- Similar existing implementations
- Related components and their interfaces
- Testing patterns used in the codebase
- Configuration patterns

## Phase 2 - Design

### Architectural Reminders

- **Shared components**: Identify all consumers. If they need different behavior, the divergence point matters (e.g., check at consumer level, not shared component).
- **Callback receivers**: Clarify single-threaded vs multi-threaded access upfront. Document assumption or add synchronization.
- **Performance comparisons**: Draw data flow first, count ops per component. Shared components don't multiply.
- **Config consistency**: Before finalizing, verify all config values match between code snippets and summary tables.

### Output based on arguments:

**If `small` argument provided:**
Use `EnterPlanMode` tool to enter built-in Plan mode. Present your plan directly in the conversation (no file output). The plan should follow the same content structure as below, but output as conversation text.

**Otherwise (default or `large`):**
Write plan to `docs/<feature-name>/PLAN.md`

### Plan content:

1. **Overview**: Brief description of the feature and its goals
2. **Architecture**: How it fits into the existing system (use diagrams where helpful)
3. **Tasks**: Break down into discrete, implementable tasks
   - Each task should result in files ≤700 lines
   - Include clear function signatures (full implementation only for tricky logic)
   - Specify which files will be created/modified
   - **Mark dependencies**: Note which tasks depend on others (e.g., "Depends on: Task 1, 3"). Independent tasks can be parallelized by `/do-job`
   - **For field/API renames**: Include bulk update commands (sed, ast-grep) as part of the task definition, not manual file-by-file edits
   - **Quantify work**: If a task affects 50+ files, it's not "one task" - break it into batch operations
   - **For deletion/migration tasks**: Include exact shell commands, not descriptions:
     - Step-by-step commands (`rm`, `mv`, `sd`, `rg`)
     - Verification commands before (what to check) and after (confirm clean)
     - Example: "Delete old file and migrate tests" → `rm old.py`, `mv test_old.py test_new.py`, `sd 'OldClass' 'NewClass' test_new.py`, `rg "OldClass" --type py` (should return nothing)
   - **Each task must include its corresponding unit tests** (not as separate tasks)
     - Unit tests are part of the task definition, not an afterthought
     - Specify test cases: happy path, edge cases, error conditions
   - **Integration tests should be a separate final task**
     - Test end-to-end flows across multiple components
     - Include manual testing checklist if applicable
4. **Integration Points**: What existing code needs to change
5. **API Change Checklist** (required for interface changes):
   If the plan changes function signatures, removes methods, or changes return types:

   - [ ] **All call sites listed**: `rg "function_name\(" --type py -l` - every file must be in a task
   - [ ] **Wrapper type impacts**: If changing `Foo` → `FooWrapper`, list ALL places that unwrap/check types
   - [ ] **Implicit dependencies**: Components that must exist for others to work (e.g., "SDC must be created before any detector can receive windows")
   - [ ] **Test fixtures that mock the changed class**: `rg "Mock.*ClassName|mock_class_name" tests/` - mock fixtures can drift from real implementation if not updated together
   - [ ] **Test files to delete**: Files that ONLY test removed APIs (will never pass)
   - [ ] **Test files to update**: Files that test both old and new APIs
   - [ ] **Integration test with real objects**: At least one test should use the real class (not mock) to catch signature drift

6. **Open Questions**: Document any decisions that need user input (these will be asked interactively)
7. **Migration Mappings** (for refactoring plans): If renaming fields/classes/methods, create an explicit mapping table:
   | Old Name | New Name |
   |----------|----------|
   | `old_field` | `new_field` |

### If `large` or `big` argument provided:

Also create `docs/<feature-name>/PROGRESS.md` with:
- List of all tasks from the plan
- Checkbox for completion status
- Space for brief notes on problems or learnings per task
- This file is for the implementation agent to track progress

## Phase 3 - Clarify

Before finalizing the plan, use the `AskUserQuestion` tool to resolve any open questions or ambiguities. Present options with clear descriptions for each choice. Do NOT leave questions unanswered in the plan document.

Examples of when to use AskUserQuestion:
- Multiple valid architectural approaches
- Unclear scope boundaries
- Missing requirements
- Trade-offs that need user input

## Output

**If `small` argument provided:**
After presenting the plan in Plan mode, use `ExitPlanMode` to signal completion and await user approval.

**Otherwise (default or `large`):**
After creating the plan file:
1. Summarize the key architectural decisions
2. Show the full path of the plan to the user
3. Confirm the plan is complete and ready for implementation (by a separate `/do-job` command)

**STOP HERE. Do not proceed to implementation. The user will invoke `/do-job` separately when ready.**
