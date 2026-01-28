---
description: Generate a new custom slash command
argument-hint: [command-name]
---

Create a new custom slash command.

Follow these steps:

1. **Ask the user for storage level using AskUserQuestion:**
   Use the AskUserQuestion tool with these options:
   - **Project level** (`.claude/commands/$1.md`): Command available only in current project, checked into repo
   - **User level** (`~/.claude/commands/$1.md`): Command available across all projects for this user

2. **Ask the user for command details:**
   - What should the command do? (Get a clear description of the command's purpose)
   - What arguments (if any) should it accept?
   - Should it use specific tools only? (allowed-tools field)
   - Should it use a specific model? (e.g., haiku for fast/simple tasks)

3. **Create the frontmatter:**
   - `description`: Brief, clear description (required for good UX)
   - `argument-hint`: Format like [arg1] [arg2] for required args, [arg?] for optional
   - `allowed-tools`: Restrict to specific tools if needed (format: ToolName, ToolName(pattern:*))
   - `model`: Specify if you want haiku/sonnet/opus (otherwise inherits from conversation)
   - `disable-model-invocation`: Set to true if command shouldn't be auto-callable

4. **Write the command prompt:**
   - Be specific and clear about what Claude should do
   - Use $ARGUMENTS for all arguments, or $1, $2, $3... for positional arguments
   - Include relevant context, constraints, or examples
   - Keep it concise but complete

5. **Best practices:**
   - Start command names with verbs (e.g., review-pr, fix-lint, generate-tests)
   - Make prompts actionable and specific
   - Use argument-hint to make usage clear
   - Consider using haiku for simple/fast commands to save costs
   - Restrict tools with allowed-tools if the command has a narrow scope

6. **Create the file** at the path based on user's storage level choice:
   - Project level: `.claude/commands/$1.md`
   - User level: `~/.claude/commands/$1.md`

After creating the command, show the user:
- The file path where it was created
- The storage level chosen (project or user)
- How to use it (e.g., `/$1 [args]`)
- Confirm it will be available in their next message
