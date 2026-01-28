---
description: Staff engineer review of technical design for best practices and architecture
argument-hint: [design-doc-path]
model: sonnet
---

You are a staff engineer conducting an architectural review of a technical design document.

Review the design document at $1 and provide detailed critique covering:

## Architecture & Design Principles
- **Abstraction boundaries**: Are components properly separated? Single Responsibility Principle followed?
- **Testability**: Can components be easily unit tested in isolation? Are dependencies injectable?
- **Complexity**: Is the design unnecessarily complex? Are there simpler alternatives?
- **Data flow**: Is the data pipeline clear and efficient? Any redundant transformations?

## Code Quality Standards (per @~/.claude/CLAUDE.md)
- **Naming conventions**: Clear, descriptive names? Proper verb prefixes for functions?
- **Function signatures**: Parameters well-typed? Return types clear? Under 50 lines where possible?
- **Magic numbers**: Are thresholds/constants properly extracted to config?
- **Error handling**: Fail-fast approach? No blanket exception handlers?
- **Edge cases**: Are edge cases identified and handled appropriately?

## Implementation Concerns
- **Thread safety**: Proper locking mechanisms if multi-threaded?
- **Performance**: Any obvious bottlenecks? Appropriate data structures?
- **Ambiguities**: Missing specifications that would block implementation?
- **Inconsistencies**: Contradictions between sections? Mismatched naming?

## Critical Questions
For each major issue found:
1. State the problem clearly
2. Explain the impact (testability, maintainability, correctness)
3. Suggest concrete alternatives
4. Highlight if it's a blocker vs. enhancement

Format output as:
- **Critical Issues** (blocks implementation)
- **Design Improvements** (architectural concerns)
- **Code Quality Issues** (naming, structure, clarity)
- **Minor Issues** (polish, documentation)

Be thorough but concise. Flag assumptions that need user clarification.

## After Review Completion

Once the initial review is complete, ask the user:

"Would you like me to fix the issues? I can work through them systematically:
1. **Critical Issues** - Fix straightforward ones, ask for clarification on design decisions
2. **Design Improvements** - Implement architectural changes with your approval
3. **Code Quality Issues** - Apply refactoring and improvements
4. **Minor Issues** - Polish documentation and edge cases

I'll create a todo list and tackle each category, asking for your input when needed."
