#!/bin/bash

_VERSION="1.0.0"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

MAX_SIZE=$1 

echo -e "${BOLD}\nChecking for files greater than ${YELLOW}$MAX_SIZE${RESET}${BOLD} bytes...${RESET}"

large_files=$(git diff --cached --name-only --diff-filter=ACMR | while read -r file; do
    if [ -f "$file" ] && [ "$(stat -c %s "$file")" -gt "$MAX_SIZE" ]; then
        echo "$file"
    fi
done)

if [ -n "$large_files" ]; then
    echo -e "Error: The following files are too large to commit:"
    echo "$large_files"
    exit 1
else 
    echo -e "${GREEN}\nNo files found. Ready to commit.${RESET}"
fi
