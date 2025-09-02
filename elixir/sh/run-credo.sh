#!/bin/bash

_VERSION="1.0.0"
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

echo -e "${BOLD}\nRunning the Credo (Elixir) analysis tool...\n${RESET}"

# Run Credo
# --strict: Include all issues. Without it, only positive-priority issues (↑ ↗ →) will be reported
mix credo "$STRICT"

TEST_EXIT_CODE=$?

if [ "$TEST_EXIT_CODE" -ne 0 ]; then
    echo -e "${RED}\nError: Some issues have been found. Please fix them before committing.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nNo issues found! Ready to commit.${RESET}"