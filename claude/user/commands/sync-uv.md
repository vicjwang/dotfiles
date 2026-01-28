---
description: Audit pyproject.toml against uv pip list and fix mismatches
model: haiku
allowed-tools: Bash, Read, Edit
---

Audit the project's `pyproject.toml` dependencies against the currently installed packages from `uv pip list`.

## Steps

1. Run `uv pip list --format=json` to get installed packages
2. Read `pyproject.toml` to get declared dependencies
3. Compare and identify:
   - **Missing**: Packages installed but not in pyproject.toml (excluding dev/build tools like pip, setuptools, wheel, uv itself)
   - **Extra**: Packages declared but not installed
   - **Version mismatches**: Different versions between installed and declared (if versions are pinned)

4. For each issue found, update `pyproject.toml`:
   - Add missing dependencies to the appropriate section
   - Remove extra dependencies that aren't installed
   - Update version specifiers if they conflict with installed versions

5. After making changes, run `uv pip compile pyproject.toml -o requirements.txt` to regenerate requirements.txt

## Important

- Ignore transitive dependencies (packages installed as deps of other packages)
- Focus on direct dependencies in `[project.dependencies]` and `[project.optional-dependencies]`
- Preserve existing version specifiers (>=, ~=, etc.) unless they conflict
- Do NOT add standard library packages or build tools (pip, setuptools, wheel, packaging, etc.)
