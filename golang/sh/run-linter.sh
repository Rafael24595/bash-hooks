#!/bin/bash

_VERSION="1.1.1"
_PACKAGE="run-linter"
_DETAILS="Runs golangci-lint to find errors in staged Go files."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

INSTALL=false

# Parse args
for arg in "$@"; do
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        INSTALL=true
    fi
done

# Ensure that golangci-lint is installed
if ! command -v golangci-lint &> /dev/null
then
    if $INSTALL; then
        echo -e "${GREEN}Installing golangci-lint...${RESET}"
        ensure_go_installed
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        echo -e "${GREEN}golangci-lint installed.${RESET}"
    else
        echo -e "${RED}\ngolangci-lint could not be found. Please install it to proceed.${RESET}"
        exit 1
    fi
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
    echo -e "${GREEN}\nNo files contain errors. Ready to commit.${RESET}\n"
    exit 0
fi

# Convert to Unix format
LINT_FILES=$(echo "$LINT_FILES" | sed 's/\\/\//g')

echo -e "${YELLOW}\nError report:${RESET}"
echo "$OUTPUT"

echo -e "${YELLOW}\nChecking staged files:\n${RESET}"

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
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll Go files passed the linter. Ready to commit.${RESET}"
