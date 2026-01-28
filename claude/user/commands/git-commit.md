---
description: Auto-generate and create a git commit with Conventional Commits format
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), AskUserQuestion
model: haiku
---

Create a git commit with an auto-generated message following Conventional Commits format.

## Prerequisites

Use AskUserQuestion with both questions in a single call:

1. **Update docs?** - "Run /update-claude to update CLAUDE.md?"
   - Options: "Yes" (run /update-claude first), "No" (skip, docs already current)

2. **Bump version?** - "Bump version in pyproject.toml?"
   - Options: "Yes" (run `uv run tools/bump_version.py`), "No" (skip)

## Steps

1. Run `git status` to see all staged and unstaged changes
2. Run `git diff --cached` to see staged changes
3. Run `git log --oneline -5` to see recent commit style
4. **Check for filesystem operations**: If diff contains `mkdir`, `Path()`, or directory structure patterns, ask: "Does this commit introduce a directory structure that should be documented in the commit message?"
5. **Stage files from current conversation**: Automatically stage files that were edited/created during this conversation. If unclear which files belong to the conversation, ask the user which files to stage.
6. Run `git diff --cached` again to see what will be committed

## Commit Message Format

Use Conventional Commits format:
```
type(scope): short description

- Bullet point summarizing key change
- Another bullet point if needed
- Keep it concise, not verbose

🤖 Co-Authored-By: Claude Opus 4.5
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no functional change)
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Maintenance tasks, dependencies
- `style`: Code style/formatting (no functional change)
- `perf`: Performance improvements

**Scope:** The module, component, or area affected (optional but preferred)

**Body length (scale to complexity, always capture the "why"):**
- Simple (logging, typos, renames): 1-line body explaining why, or title-only if why is obvious
- Standard (bug fixes, small features): 1-2 bullets - what changed and why it matters
- Complex (multi-file, architectural): 2-3 bullets max

## Requirements

- Keep the first line under 72 characters
- Use imperative mood ("add" not "added")
- **Be concise** - summary bullet points, not detailed paragraphs
- Use bullet points for the body (not prose)
- Include JIRA ticket reference only if working on a ticket (check branch name for JV-* pattern)
- Include this standard footer exactly:

```
🤖 Co-Authored-By: Claude Opus 4.5
```

## Important

- The `git commit` command will prompt for approval so you can review the message
- Use HEREDOC format for multi-line commit messages
- Do NOT push to remote unless explicitly asked
- *ALWAYS* run "git add" and "git commit" commands separate, not in
  a single command with "&&"
