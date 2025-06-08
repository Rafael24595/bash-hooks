#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-linter"
_DETAILS="Runs shellcheck to find errors in staged Shell files."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Ensure that shellcheck is installed
if ! command -v shellcheck &> /dev/null
then
    echo -e "${RED}\nshellcheck could not be found. Please install it to proceed.${RESET}"
    exit 1
fi

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
# Check if no files are staged
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo files are staged for commit.${RESET}\n"
    exit 0
fi

STAGED_FILES=$(echo "$STAGED_FILES" | grep -E '(^[^.]+$|\.sh$)')
# Check if no files are staged
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo Shell files are staged for commit.${RESET}\n"
    exit 0
fi

echo -e "${YELLOW}\nChecking staged files...${RESET}"

HAS_ERRORS=false
while IFS= read -r FILE; do
    # Convert to Unix format
    FILE=$(echo "$FILE" | sed 's/\\/\//g')
    # Check if the file is in the list of staged files
    if ! OUTPUT=$(shellcheck --color=always "$FILE"); then
        echo -e "\nFile '${BOLD}$FILE${RESET}' contains errors: \n $OUTPUT"
        HAS_ERRORS=true
    fi
done <<< "$STAGED_FILES"

# Check the boolean variable after the loop
if [ "$HAS_ERRORS" = true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors, fix it before commit.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll Shell files passed the linter. Ready to commit.${RESET}"
