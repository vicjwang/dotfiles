---
description: Update all CLAUDE.md files, stale docstrings, and stale comments to match current codebase state
allowed-tools: Read, Glob, Grep, Edit, Task
---

Audit and update all CLAUDE.md files, stale docstrings, and stale comments in this project to ensure they accurately reflect the current codebase.

## Process

1. **Find all CLAUDE.md files** recursively in the project

2. **For each CLAUDE.md file**, analyze its scope (project root = entire codebase, subdirectory = that module)

3. **Audit the documentation** against actual code:
   - Check that documented functions/methods still exist and have correct signatures
   - Verify documented patterns match actual implementation
   - Check constants, config options, and defaults are accurate
   - Verify file paths and directory structures are current
   - Check that documented workflows match actual code flow
   - **Audit docstrings**: Check that function/method docstrings match actual signatures, parameters, return types, and behavior
   - **Audit comments**: Check that inline comments accurately describe the code they annotate

4. **Find undocumented code**:
   - New public functions/methods not in docs
   - New configuration options
   - New patterns or conventions
   - Changed behavior or signatures
   - New files or modules

5. **Find stale docstrings**:
   - Docstrings with incorrect parameter names or types
   - Docstrings with missing/extra parameters vs actual signature
   - Docstrings with incorrect return type descriptions
   - Docstrings describing behavior that no longer matches implementation

6. **Find stale comments**:
   - Comments referencing variable/function names that were renamed or deleted
   - Comments describing logic that has since changed
   - Comments with stale index/position references (e.g., "column 7" when columns reordered)
   - TODO/FIXME comments for issues that were already resolved
   - Comments explaining "what" the code does (redundant) rather than "why"

7. **Report findings** before making changes:
   - List what's outdated or incorrect
   - List what's missing/undocumented
   - List stale docstrings found
   - List stale comments found
   - Ask for confirmation before updating

8. **Update CLAUDE.md files**:
   - Fix inaccuracies
   - Add undocumented items to appropriate sections
   - Remove references to deleted code
   - Keep language concise (per CLAUDE.md guidelines)
   - Preserve existing structure and organization

9. **Update stale docstrings**:
   - Fix parameter names, types, and descriptions to match actual signature
   - Add missing parameters, remove deleted ones
   - Correct return type descriptions
   - Update behavior descriptions to match current implementation
   - Preserve existing docstring style (Google, NumPy, reST, etc.)

10. **Update stale comments**:
    - Fix or remove comments referencing renamed/deleted identifiers
    - Update comments to reflect changed logic
    - Remove stale index/position references or make them relative
    - Remove resolved TODO/FIXME comments
    - Remove redundant "what" comments that just restate the code

## Guidelines

### CLAUDE.md Files
- Do NOT add verbose descriptions - keep CLAUDE.md concise
- Do NOT document trivial or self-explanatory code
- Focus on: patterns, gotchas, architectural decisions, non-obvious behavior
- Preserve existing formatting style of each CLAUDE.md
- When adding new sections, follow existing conventions in that file

**Hierarchy structure:**
- Project root CLAUDE.md provides high-level information and architecture, then references nested CLAUDE.md files for details
- Each nested CLAUDE.md provides context specific to files in that subdirectory (patterns, conventions, gotchas for that module)
- Create new nested CLAUDE.md files when appropriate for subdirectories with significant complexity or non-obvious patterns

### Docstrings
- Only fix docstrings that are WRONG (mismatched params, incorrect types, outdated behavior)
- Do NOT add docstrings to undocumented functions (that's a separate task)
- Preserve the existing docstring format used in the file
- Keep fixes minimal - correct the inaccuracy, don't rewrite the whole docstring

### Comments
- Only fix comments that are WRONG (stale references, outdated logic descriptions)
- Do NOT add new comments to uncommented code (that's a separate task)
- Prefer removing stale comments over trying to update them if the code is self-explanatory
- Keep fixes minimal - if a comment is partially wrong, fix only the incorrect part
