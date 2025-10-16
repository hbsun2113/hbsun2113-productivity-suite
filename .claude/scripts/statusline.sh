#!/bin/bash

# Read JSON input from stdin
input=$(cat)
# Use ~/.claude for storing statusline input log
echo "$input" >> ~/.claude/statusline-input.txt

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Get git branch if in a git repository
git_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch="${GREEN}(${branch})${RESET}"
    fi
fi

# Output the statusline with colors
echo -e "${BLUE}${CURRENT_DIR}${RESET} ${git_branch} ${YELLOW}[${MODEL_DISPLAY}]${RESET}"
