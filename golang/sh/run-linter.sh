#!/bin/bash

_VERSION="1.0.1"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Ensure that golangci-lint is installed
if ! command -v golangci-lint &> /dev/null
then
    echo -e "${RED}\ngolangci-lint could not be found. Please install it to proceed.${RESET}"
    exit 1
fi

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
# Check if no files are staged
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo valid files are staged for checking.${RESET}\n"
    exit 0
fi

# Run golangci-lint across the entire repository (all Go files)
echo -e "${BOLD}\nRunning golangci-lint on all Go files in the repository...${RESET}"

OUTPUT=$(golangci-lint run --color always ./...)

LINT_FILES=$(grep -o 'src[^ ]*\.go' <<< "$OUTPUT")
# Check if no files contains errors
if [ -z "$LINT_FILES" ]; then
    echo -e "${GREEN}\nNo files contains errors. Ready to commit.${RESET}\n"
    exit 0
fi

# Convert to Unix format
LINT_FILES=$(echo "$LINT_FILES" | sed 's/\\/\//g')

echo -e "${YELLOW}\nError report:${RESET}"
echo "$OUTPUT"

echo -e "${YELLOW}\nChecking stagged files:\n${RESET}"

HAS_ERRORS=false
while IFS= read -r FILE; do
    # Convert to Unix format
    FILE=$(echo "$FILE" | sed 's/\\/\//g')
    # Check if the file is in the list of staged files
    if grep -q "^$FILE$" <<< "$LINT_FILES"; then
        echo -e "File '${BOLD}$FILE${RESET}' contains errors."
        HAS_ERRORS=true
    fi
done <<< "$STAGED_FILES"

# Check the boolean variable after the loop
if [ "$HAS_ERRORS" = true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors, fix it before commit.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll Go files passed the linter. Ready to commit.${RESET}"
