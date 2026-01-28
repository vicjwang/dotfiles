#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
context_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Format current directory (basename only for brevity)
dir=$(basename "$cwd")

# Get git branch if in a git repo
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
      branch="$branch"
    fi
fi

# Format context usage
context_str=""
if [ -n "$context_used" ]; then
    # Convert to integer for display
    context_int=$(printf "%.0f" "$context_used")
    context_str=" | Context: ${context_int}%"
fi

# Build and print status line
printf "%s (%s) | %s%s" "$dir" "$branch" "$model" "$context_str"
