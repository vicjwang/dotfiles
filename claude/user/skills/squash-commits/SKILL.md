---
name: squash-commits
description: Squash WIP commits into logical groups. Use when user wants to clean up commit history, consolidate commits, or prepare branch for merge/PR.
---

# Squash Commits Skill

Automate squashing of WIP commits into logical groups with proper commit messages.

## Workflow

1. **Identify base branch**: Determine the branch to rebase onto (usually `main` or `master`)

2. **Analyze commits**: Run `git log --oneline BASE..HEAD` to list commits to squash

3. **Propose groupings**: Analyze commit messages and propose logical groups based on:
   - Related file changes
   - Feature/fix boundaries
   - Commit message patterns (WIP, fixup, etc.)

4. **Show proposed messages**: Display the full commit message for each group, get user approval

5. **Create backup**: `git branch backup-before-squash-$(date +%Y%m%d-%H%M%S)`

6. **Stash changes**: `git stash` if there are uncommitted changes

7. **Move untracked files**: If data files block rebase, temporarily move them

8. **Execute rebase**: Use automated rebase with fixup + exec pattern

9. **Verify**: `git diff backup-branch` should be empty

## Technical Details

### Why fixup + exec, not squash
- `squash` opens interactive editor for each squash group
- `fixup` discards message, then `exec git commit --amend -F file` sets final message
- Fully automated, no editor interaction needed

### Rebase Editor Script Pattern
```bash
#!/bin/bash
# Dynamically generated rebase-editor.sh
cat > "$1" << 'EOF'
pick abc1234 First commit of group 1
fixup def5678 WIP: more work
fixup ghi9012 WIP: almost done
exec git commit --amend -F /path/to/message1.txt

pick jkl3456 First commit of group 2
fixup mno7890 WIP: feature B
exec git commit --amend -F /path/to/message2.txt
EOF
```

### Message File Format
Create `.rebase-messages/` directory with numbered message files:
- `01-group-name.txt` - First group's commit message
- `02-group-name.txt` - Second group's commit message

Each file contains the full commit message including:
- Subject line (50 chars max)
- Blank line
- Body (wrapped at 72 chars)
- Co-Authored-By if applicable

## Execution Commands

```bash
# Create message directory
mkdir -p .rebase-messages

# Create backup
git branch backup-before-squash-$(date +%Y%m%d-%H%M%S)

# Stash if needed
git stash

# Run rebase
GIT_SEQUENCE_EDITOR="./rebase-editor.sh" git rebase -i BASE_BRANCH

# Verify (should be empty)
git diff backup-before-squash-*

# Clean up on success
rm -rf .rebase-messages rebase-editor.sh
git branch -D backup-before-squash-*  # Only after verification
```

## Verification Checklist
- [ ] `git log --oneline BASE..HEAD` shows expected commit count
- [ ] `git diff backup-branch` is empty (no code changes)
- [ ] Each commit message follows Conventional Commits format
- [ ] No WIP/fixup/squash commits remain
