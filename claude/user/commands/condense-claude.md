---
description: Condense a project's CLAUDE.md file while preserving all information
argument-hint: [path?]
model: sonnet
---

You are tasked with condensing a CLAUDE.md file that has grown too large, while preserving all meaningful information and instructions.

# Input
- If an argument is provided, read the CLAUDE.md file at that path: `$1/CLAUDE.md`
- If no argument is provided, look for CLAUDE.md in the current working directory

# Your Task
1. **Read the existing CLAUDE.md file**
2. **Analyze the content** and identify:
   - Redundant or repetitive instructions
   - Verbose explanations that can be made more concise
   - Similar rules that can be consolidated
   - Unnecessary examples (keep only the most illustrative ones)
   - Any outdated or conflicting guidelines

3. **Condense the file** by:
   - Merging related sections
   - Converting verbose prose to bullet points where appropriate
   - Removing redundancy while keeping all unique rules and constraints
   - Making instructions more direct and actionable
   - Preserving all technical specifics (file paths, patterns, specific requirements)
   - Keeping the overall structure and organization logical

4. **Preserve ALL of:**
   - Unique coding standards and conventions
   - Specific technical requirements
   - Project-specific rules and constraints
   - Critical workflow instructions
   - Any "IMPORTANT" or emphasized guidelines

5. **Present the condensed version** to the user with:
   - A summary of what was condensed (e.g., "Merged 3 sections about error handling")
   - The new file size vs. old file size (approximate character/line count)
   - Ask for approval before writing the changes

6. **IMPORTANT: After user approval**, write the condensed version back to the original file path.

# Guidelines
- Aim for 30-50% reduction in size without information loss
- Prioritize clarity and scannability
- Use consistent formatting throughout
- Do not add new instructions or change meanings
- Keep the tone and style consistent with the original
