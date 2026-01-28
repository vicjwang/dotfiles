#!/usr/bin/env python3
"""
PreToolUse hook for Bash commands.
Detects shell antipatterns and asks for confirmation with rules displayed.
"""
import json
import os
import re
import sys

RULES_PATH = os.path.expanduser("~/.claude/rules/shell.md")

# Patterns that trigger the "ask" confirmation
ANTIPATTERNS = [
    (r"xargs\s+.*-I.*sh\s+-c", "xargs -I ... sh -c antipattern detected"),
]

# Patterns that are completely forbidden (deny, not ask)
FORBIDDEN = [
    (r"\brm\b", "rm command forbidden"),
]


def load_rules() -> str:
    """Load rules file content."""
    try:
        with open(RULES_PATH, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "(Rules file not found)"


def check_command(command: str) -> tuple[str, str]:
    """Check command. Returns (decision, reason) where decision is 'deny', 'ask', or ''."""
    for pattern, reason in FORBIDDEN:
        if re.search(pattern, command):
            return "deny", reason
    for pattern, reason in ANTIPATTERNS:
        if re.search(pattern, command):
            return "ask", reason
    return "", ""


def main():
    # Read hook input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # Invalid input, allow command

    # Extract command
    command = input_data.get("tool_input", {}).get("command", "")
    if not command:
        sys.exit(0)

    # Check for forbidden and antipatterns
    decision, reason = check_command(command)
    if not decision:
        sys.exit(0)  # Clean command, allow

    # Load rules for display
    rules = load_rules()

    # Return decision (deny or ask) with rules shown
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": f"{reason}\n\n{rules}",
        }
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()
