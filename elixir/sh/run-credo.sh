#!/bin/bash

_VERSION="1.3.0"
_PACKAGE="run-credo"
_DETAILS="Run Credo analysis tool."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

STRICT=""
FORCE_ALL=false

for FLAG in "$@"; do
    if [ "$FLAG" == "--strict" ] || [ "$FLAG" == "--s" ]; then
        STRICT="--strict"
    fi
    if [ "$FLAG" == "--force-all" ] || [ "$FLAG" == "--fa" ]; then
        FORCE_ALL=true
    fi
done

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo valid files are staged for checking.${RESET}\n"
    exit 0
fi

CREDO_TARGET=(".")
if ! $FORCE_ALL ; then
    readarray -t CREDO_TARGET <<< "$STAGED_FILES"
fi

if ! command -v mix credo -v &> /dev/null; then
    echo -e "${RED}\nCredo could not be found. Please install it to proceed.${RESET}"
    exit 1
fi

echo -e "${BOLD}\nRunning the Credo (Elixir) analysis tool...\n${RESET}"

# Run Credo
# --strict: Include all issues. Without it, only positive-priority issues (↑ ↗ →) will be reported
mix credo "$STRICT" "${CREDO_TARGET[@]}"

# Run Credo
# --format flycheck: Display the list in a resumed line format
OUTPUT=$(mix credo "$STRICT" --format flycheck "${CREDO_TARGET[@]}")
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