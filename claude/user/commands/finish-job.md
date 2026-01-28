---
description: Run linter, update docs, and prepare commit
argument-hint: <path-to-plan-file>
model: haiku
---

Finalize implementation for plan at: $ARGUMENTS

**Prerequisite:** Check whether `/review-job` was already run in PROGRESS.md. If not, run `/review-job` first to complete code review, simplification, and tests.

## CRITICAL: Step Tracking Required

**Use TodoWrite to track ALL steps.** Before starting, create todos for each step below. Mark each as `in_progress` before starting and `completed` only after finishing.

## Step 1 - Run Linter

Run `uv run ruff check` on modified files to catch style and code quality issues.

Fix any linter errors or warnings found.

## Step 2 - Update CLAUDE.md (if applicable)

Run `/update-claude` ONLY if this session introduced:
- New architectural patterns
- Non-obvious gotchas or edge cases
- Changes to testing or build patterns

Skip if the implementation simply followed existing patterns. Note "no updates needed" and proceed.

## Step 3 - Pre-Commit Checklist (GATE)

**Before proceeding to commit, explicitly verify ALL of the following:**

- [ ] `/review-job` completed (code review, simplification, tests passed)
- [ ] Step 1: Linter passed
- [ ] Step 2: CLAUDE.md updated (or confirmed no updates needed)

**If any checkbox is unchecked, go back and complete that step.**

## Step 4 - Finalize Commit

1. Check for unstaged changes related to this feature:
   - Run `git status --short`
   - Identify files with ` M` (unstaged modified) that belong to this feature
   - Stage them: `git add <files>`
   - **Include planning docs** if present (e.g., `docs/<feature>/`)
   - Verify remaining unstaged files are unrelated (runtime data, local configs)
2. Count wip commits: `git log --oneline | grep -c "^[a-f0-9]* wip:"`
3. If multiple wip commits exist, squash them:
   - Find the commit before first wip: `git log --oneline | grep -v "wip:" | head -1`
   - Squash: `git reset --soft <commit-before-wip>`
   - Create single commit with conventional message
4. If single wip commit, amend with proper message
5. If no wip commits, run `/git-commit`

The final commit message should:
- Follow conventional commits format (feat/fix/refactor/etc.)
- Remove any `wip:` prefix
- Summarize the full implementation

## Output

Provide a summary of:
1. Linter issues fixed
2. CLAUDE.md updates made
3. Pre-commit checklist status (all boxes checked)
4. Proposed commit message

## Next Steps

Suggest the user run `/retro-job` to reflect on the implementation session and capture learnings.
