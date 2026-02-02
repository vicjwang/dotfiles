#!/usr/bin/env python3
"""
Opus-powered Bash permission validator for Claude Code.

This PermissionRequest hook uses Claude Opus to analyze Bash command safety
and automatically approve safe commands or deny unsafe ones.

Triggered when: A Bash permission dialog is about to show
Output: JSON with decision to allow/deny
"""

import json
import os
import sys
import subprocess
from typing import Tuple, Dict, Any


# Simple commands that are always safe (bypass Opus)
SAFE_COMMANDS = {
    "ls", "pwd", "echo", "cat", "head", "tail", "wc",
    "grep", "rg", "fd", "find", "tree", "jq", "sort", "uniq",
    "git status", "git log", "git diff", "tokei", "dust"
}


def get_first_word(command: str) -> str:
    """Extract first word from command, handling pipes and redirects."""
    parts = command.split()
    if not parts:
        return ""
    first = parts[0]
    # Handle sudo, time, etc.
    if first in ("sudo", "time", "env"):
        return parts[1] if len(parts) > 1 else first
    return first


def analyze_with_opus(command: str) -> Tuple[bool, str]:
    """
    Use Claude Opus to analyze command safety.

    Returns:
        (is_safe, explanation) tuple
    """
    prompt = f"""Analyze this Bash command for safety AND efficiency issues:

```bash
{command}
```

**Safety concerns:**
- Does it delete/modify critical files? (rm -rf /, system files)
- Does it expose sensitive data? (cat ~/.ssh/*, env vars, credentials)
- Does it have destructive side effects? (force push, hard reset without confirmation)
- Could it cause data loss or system instability?

**Inefficiency concerns (these are also "unsafe" - treat as UNSAFE):**
- Uses `xargs -I{{}} sh -c` when tool accepts multiple args directly
- Uses `xargs` when downstream tool reads from stdin natively (rg, sd, etc)
- Uses `| head -1` when tool has native early-exit (fd -1)
- Multi-stage pipelines when single-pass is possible (awk | awk)
- Uses find when fd/rg is more appropriate
- Text tools (sed/grep) for structural code changes (use ast-grep)
- Missing --null for filename safety with rg/fd

Respond with ONLY one of these formats:
SAFE: <brief reason why it's safe and efficient>
UNSAFE: <specific security OR efficiency concern>

**Safety examples:**
- "ls -la" → SAFE: Read-only directory listing
- "rm -rf /" → UNSAFE: Deletes entire filesystem
- "git reset --hard HEAD~5" → UNSAFE: Destructive history rewrite
- "npm test" → SAFE: Runs test suite without modifying files

**Efficiency examples (treat as UNSAFE):**
- "rg -l pattern | xargs sd old new" → UNSAFE: Inefficient - sd accepts stdin directly, use: rg -l --null pattern | sd --null old new
- "fd file | head -1 | xargs cat" → UNSAFE: Inefficient - use fd -1 with -x, not head + xargs
- "find . -name '*.py' | xargs command" → UNSAFE: Inefficient - use fd or find -exec
- "awk ... | awk ..." → UNSAFE: Inefficient - use single-pass awk with explicit state
- "xargs -I{{}} sh -c 'echo {{}}; cat {{}}'" → UNSAFE: Inefficient - spawns shell per file, use -x or direct command
"""

    try:
        result = subprocess.run(
            ["claude", "-p", prompt, "--model", "opus"],
            capture_output=True,
            text=True,
            timeout=10  # seconds
        )

        if result.returncode != 0:
            print(f"⚠️  Claude CLI error (exit {result.returncode}), allowing command", file=sys.stderr)
            if result.stderr:
                print(f"Error output: {result.stderr[:200]}", file=sys.stderr)
            return True, "Claude CLI error"

        response = result.stdout.strip()

        if response.startswith("SAFE:"):
            reason = response[5:].strip()
            print(f"✅ Opus validated: {reason}", file=sys.stderr)
            return True, reason
        elif response.startswith("UNSAFE:"):
            reason = response[7:].strip()
            print(f"🛑 Opus blocked: {reason}", file=sys.stderr)
            return False, reason
        else:
            # Unexpected format, fail open
            print("⚠️  Unexpected Opus response format, allowing command", file=sys.stderr)
            print(f"Response: {response[:200]}", file=sys.stderr)
            return True, "Unexpected response format"

    except subprocess.TimeoutExpired:
        print("⚠️  Opus analysis timed out, allowing command", file=sys.stderr)
        return True, "Analysis timeout"
    except FileNotFoundError:
        print("⚠️  'claude' CLI not found, allowing command", file=sys.stderr)
        return True, "Claude CLI not available"
    except Exception as e:
        print(f"⚠️  Opus validation error: {e}, allowing command", file=sys.stderr)
        return True, f"Validation error: {e}"


def create_decision_json(behavior: str, message: str = None) -> Dict[str, Any]:
    """Create PermissionRequest decision JSON."""
    decision = {"behavior": behavior}
    if message:
        decision["message"] = message

    return {
        "hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": decision
        }
    }


def main():
    """Hook entry point."""
    try:
        # Read hook input from stdin
        hook_input = json.load(sys.stdin)

        tool_name = hook_input.get("tool_name", "")
        if tool_name != "Bash":
            # Not a Bash command, allow (shouldn't happen with matcher)
            print(json.dumps(create_decision_json("allow")))
            return

        tool_input = hook_input.get("tool_input", {})
        command = tool_input.get("command", "")

        if not command:
            # No command to validate, allow
            print(json.dumps(create_decision_json("allow")))
            return

        # Check if command is simple and in safe list (no pipes, redirects, or complex structure)
        is_simple = not any(char in command for char in ("|", ">", "<", "&", ";", "$(", "`"))
        first_word = get_first_word(command)

        if is_simple and first_word in SAFE_COMMANDS:
            print(f"✅ Whitelisted command: {first_word}", file=sys.stderr)
            print(json.dumps(create_decision_json("allow")))
            return

        # Analyze with Opus
        is_safe, reason = analyze_with_opus(command)

        if is_safe:
            # Auto-approve
            print(json.dumps(create_decision_json("allow")))
        else:
            # Auto-deny with explanation
            message = f"Opus safety check: {reason}"
            print(json.dumps(create_decision_json("deny", message)))

    except json.JSONDecodeError as e:
        print(f"⚠️  Could not parse hook input: {e}, allowing command", file=sys.stderr)
        print(json.dumps(create_decision_json("allow")))
    except Exception as e:
        print(f"⚠️  Hook error: {e}, allowing command", file=sys.stderr)
        print(json.dumps(create_decision_json("allow")))


if __name__ == "__main__":
    main()
