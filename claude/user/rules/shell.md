# Shell Command Rules

## xargs: Never use `-I ... sh -c` antipattern

**Rule**: Never use `xargs -I{} sh -c '...'` unless the operation cannot be expressed as a single command accepting multiple file arguments.

**Why**: `-I` disables batching (runs one command per input), `sh -c` adds shell fork overhead per file—catastrophic at scale.

**Decision tree**:
1. Does the tool accept multiple paths? (`wc`, `rg`, `stat`, `du`, `ls`, `sed`, `awk`, `sg`) → pass files directly
2. Need per-file formatting? → use `awk`, `printf`, or tool's native formatting
3. Truly need per-file shell logic? → only then use `-I ... sh -c`

**Good**: `fd -e py | xargs wc -l` or `fd -e py -x wc -l`
**Bad**: `fd -e py | xargs -I{} sh -c 'wc -l "{}"'`

---

## Tool Preferences

| Task | Use | Not |
|------|-----|-----|
| Finding FILES | `fd` | `find` |
| Finding TEXT/strings | `rg` | `grep` |
| Finding CODE STRUCTURE | `ast-grep` | - |
| FIND & REPLACE | `sd` | `sed` |
| STRUCTURAL DIFFS | `difft` | `diff` |
| SELECTING from results | pipe to `fzf` | - |
| JSON | `jq` | - |
| YAML/XML | `yq` | - |
| CSV | `xsv` | - |
| COLUMN selection | `choose` | `cut`/`awk` |
| DISK USAGE | `dust` | `du` |
| CODE STATS | `tokei` | - |
| BENCHMARKING | `hyperfine` | `time` |
