---
description: Add/audit logging following repo patterns (logger.exception, dual handlers, CLI flags)
model: haiku
allowed-tools: Read, Edit, Write, Glob, Grep
---

You are tasked with implementing or auditing logging in Python code following this repository's strict logging standards.

# Repository Logging Standards

## Required Patterns

1. **Always use `logger.exception()` in exception handlers** (NOT `logger.error()`):
   ```python
   from common.logger import logger

   try:
       # some operation
   except Exception as e:
       logger.exception(f"Operation failed: {e}")  # Captures full stacktrace
       # Handle error appropriately
   ```

2. **Never re-raise with `raise e`** - use bare `raise` to preserve traceback:
   ```python
   # WRONG
   except Exception as e:
       logger.exception(f"Error: {e}")
       raise e  # Loses original traceback

   # CORRECT
   except Exception as e:
       logger.exception(f"Error: {e}")
       raise  # Preserves original traceback
   ```

3. **Import logger from common.logger**:
   ```python
   from common.logger import logger
   ```

4. **Replace print statements with logging**:
   ```python
   # WRONG
   print("Starting process...")
   print(f"Error: {error}")
   print(f"Debug: value={value}")

   # CORRECT
   logger.info("Starting process...")
   logger.error(f"Error: {error}")  # Or logger.exception() in except block
   logger.debug(f"Debug: value={value}")
   ```

   **Guidelines for replacement:**
   - Informational prints → `logger.info()`
   - Debug/diagnostic prints → `logger.debug()`
   - Error messages → `logger.error()` (or `logger.exception()` in except blocks)
   - Warnings → `logger.warning()`

5. **Dual handler setup (file + console)**:
   - DEBUG level and higher → `logs/app.log` (file handler)
   - ERROR level and higher → console (console handler)
   - This is implemented in `common/logger.py` - just import and use

6. **Use appropriate log levels**:
   - `logger.debug()` - Detailed debugging information
   - `logger.info()` - General informational messages
   - `logger.warning()` - Warning messages (deprecated patterns, non-critical issues)
   - `logger.exception()` - Exception messages (ONLY in except blocks)
   - Never use `logger.error()` in except blocks - use `logger.exception()` instead

7. **Never use blanket exception handlers** - always be specific or let errors propagate:
   ```python
   # WRONG - silently swallows all errors
   try:
       something()
   except Exception:
       pass

   # CORRECT - specific handling or propagation
   try:
       something()
   except SpecificException as e:
       logger.exception(f"Specific error: {e}")
       # Handle appropriately
   ```

## CLI Flags for Runnable Scripts

If the file is a runnable script (has `if __name__ == "__main__":` or is entry point), add argparse support:

```python
import argparse
import logging

def main():
    parser = argparse.ArgumentParser(description="Script description")
    parser.add_argument('-q', '--quiet', action='store_true',
                        help='Suppress console output (log to file only)')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Verbose console output (show DEBUG level)')
    args = parser.parse_args()

    # Adjust console handler level based on flags
    from common.logger import logger
    console_handler = None
    for handler in logger.handlers:
        if isinstance(handler, logging.StreamHandler) and not isinstance(handler, logging.FileHandler):
            console_handler = handler
            break

    if console_handler:
        if args.quiet:
            console_handler.setLevel(logging.CRITICAL + 1)  # Suppress all console output
        elif args.verbose:
            console_handler.setLevel(logging.DEBUG)  # Show DEBUG to console

    # Rest of main logic
    logger.info("Starting script...")
```

**Key points:**
- `-q/--quiet`: Suppress console, file logging continues
- `-v/--verbose`: Show DEBUG level to console (default is ERROR+)
- Mutually exclusive in practice (if both specified, verbose wins)

## Your Task

Based on the conversation context:

1. **If adding logging to existing code:**
   - Add `from common.logger import logger` import if missing
   - **Replace all print() statements with appropriate logger calls**
   - Add `logger.exception()` to all try/except blocks
   - Add `logger.debug()` or `logger.info()` to key operations (function entry, important state changes)
   - Fix any `raise e` to bare `raise`
   - Fix any `logger.error()` to `logger.exception()` in except blocks
   - If runnable script, add argparse with -q and -v flags

2. **If setting up logging in new file:**
   - Add `from common.logger import logger` at top
   - Use logger calls instead of print()
   - Add exception handling with proper `logger.exception()` calls
   - Add informational logging at key points
   - If runnable script, add argparse with -q and -v flags

3. **If auditing existing logging:**
   - Check for remaining print() statements and replace them
   - Check all try/except blocks have `logger.exception()` (not `logger.error()`)
   - Check all exception re-raises use bare `raise` (not `raise e`)
   - Check no blanket `except Exception: pass` patterns
   - Check logger is imported from `common.logger`
   - Check runnable scripts have -q and -v flag support

## Important Notes

- **Be surgical** - only modify logging-related code, don't refactor other logic
- **Preserve all existing comments** when editing
- **Use Edit tool** for existing files, Write tool only for new files
- **Read files first** before editing to understand context
- **Focus on exception handlers** - that's where logging is most critical
- **logs/app.log is created automatically** - no need to create logs/ directory manually
- **Print replacement priority**: Replace prints that are for logging/debugging, but keep prints that are intentional user-facing output (CLI tools showing results to user)

## Configuration File Standards

When a project needs config-based log level control (preferred over CLI flags for applications):

1. **Use INI format** with flat keys (not nested JSON):
   ```ini
   [app]
   log_level = INFO
   ```

2. **Config file location**: `config.ini` in project root (not inside source/)

3. **Always include `config.example.ini`** with all options documented:
   ```ini
   [app]
   # Log level for console output: DEBUG, INFO, WARNING, ERROR, CRITICAL
   log_level = INFO
   ```

4. **Use `configparser` with `interpolation=None`** to handle special characters:
   ```python
   config = configparser.ConfigParser(interpolation=None)
   ```

5. **Implement `set_console_level()` in logger.py**:
   ```python
   def set_console_level(level_name: str) -> None:
       level = LOG_LEVELS.get(level_name.upper(), logging.ERROR)
       for handler in logger.handlers:
           if handler.get_name() == "console":
               handler.setLevel(level)
   ```

6. **Add `--config` flag for custom config file path**:
   ```python
   import argparse

   parser = argparse.ArgumentParser()
   parser.add_argument('--config', type=str, default=None,
                       help='Path to config file (default: config.ini in project root)')
   args = parser.parse_args()

   config = load_config(args.config)  # Pass custom path or None for default
   ```

7. **Load config at startup and set log level before other initialization**:
   ```python
   from common.config import load_config, get_app_config
   from common.logger import logger, set_console_level

   config = load_config(args.config)
   app_config = get_app_config(config)
   set_console_level(app_config['log_level'])
   ```

8. **Add startup banner logging** to verify config is loaded:
   ```python
   logger.info("=" * 60)
   logger.info("Application starting")
   logger.info(f"Log level: {app_config['log_level']}")
   logger.info("=" * 60)
   ```

9. **Gitignore `config.ini`** but track `config.example.ini`

Auto-detect which files need logging work from the recent conversation context, or ask the user if unclear.
