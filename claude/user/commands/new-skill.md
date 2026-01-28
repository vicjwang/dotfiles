---
description: Create a new Claude Skill with SKILL.md and optional scripts
argument-hint: [skill-name]
---

Create a new Claude Skill in ~/.claude/skills/$1/

## Steps

1. **Ask the user for skill details:**
   - What should the skill do? (Clear description of purpose and capabilities)
   - When should Claude use it? (Trigger conditions for auto-discovery)
   - What tools should it use? (allowed-tools field, if restricted)
   - Should it use a specific model? (haiku for fast tasks, sonnet/opus for complex)
   - Will it need supporting scripts? (Python, shell, etc.)

2. **Create the directory structure:**
   ```
   mkdir -p ~/.claude/skills/$1/scripts  # if scripts needed
   ```

3. **Create SKILL.md with frontmatter:**
   ```yaml
   ---
   name: skill-name
   description: Clear description of what the skill does AND when to use it
   allowed-tools: Tool1, Tool2  # optional
   model: claude-sonnet-4-20250514  # optional
   ---
   ```

4. **Write the skill instructions:**
   - Start with a brief overview
   - Include step-by-step execution instructions
   - Add examples section with concrete usage
   - Document any gotchas or edge cases

5. **If using scripts:**
   - Create scripts in `~/.claude/skills/$1/scripts/`
   - Use absolute paths in SKILL.md: `python ~/.claude/skills/$1/scripts/helper.py`
   - Include shebang lines (`#!/usr/bin/env python3`)
   - Add error handling with clear exit codes
   - Document script arguments in SKILL.md

## Best Practices

- **Description is critical**: Claude uses it to decide when to apply the skill
  - BAD: `description: Helps with documents`
  - GOOD: `description: Extract text and tables from PDF files. Use when user mentions PDFs, forms, or document extraction.`

- **Keep SKILL.md under 500 lines**: Put detailed docs in separate files (reference.md, examples.md)

- **Progressive disclosure**: Essential info in SKILL.md, link to reference files for details

- **Script guidelines**:
  - Single-purpose, focused scripts
  - Clear input/output documentation
  - Proper error handling

## Example Structure

```
my-skill/
├── SKILL.md           # Main instructions (<500 lines)
├── reference.md       # Detailed API docs (optional)
├── examples.md        # Usage examples (optional)
└── scripts/
    └── process.py     # Utility script (optional)
```

## After Creation

Show the user:
- Directory path: `~/.claude/skills/$1/`
- How Claude will discover it (based on description keywords)
- Any manual testing steps needed
