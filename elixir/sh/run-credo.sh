#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-credo"
_DETAILS="Run Credo analysis tool."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

STRICT=""

for arg in "$@"; do
    if [ "$arg" == "--strict" ] || [ "$arg" == "-s" ]; then
        STRICT="--strict"
    fi
done

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo valid files are staged for checking.${RESET}\n"
    exit 0
fi

echo -e "${BOLD}\nRunning the Credo (Elixir) analysis tool...\n${RESET}"

# Run Credo
# --strict: Include all issues. Without it, only positive-priority issues (↑ ↗ →) will be reported
mix credo "$STRICT"

# Run Credo
# --format flycheck: Display the list in a resumed line format
OUTPUT=$(mix credo "$STRICT" --format flycheck)
if [ -z "$OUTPUT" ]; then
    echo -e "${GREEN}\nNo issues detected. Ready to commit.${RESET}\n"
    exit 0
fi

echo -e "${YELLOW}\nChecking staged files:\n${RESET}"

HAS_ERRORS=false
while IFS= read -r FILE; do
    if grep -q "^$FILE.*$" <<< "$OUTPUT"; then
        echo -e "File '${BOLD}$FILE${RESET}' contains errors."
        HAS_ERRORS=true
    fi
done <<< "$STAGED_FILES"

if [ "$HAS_ERRORS" = true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nNo issues found! Ready to commit.${RESET}"