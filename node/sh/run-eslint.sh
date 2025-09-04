#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-eslint"
_DETAILS="Run ESLint analysis tool."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import sh utils from utils.sh
# shellcheck disable=SC1091
source ./tools/sh/utils.sh

FORCE_ALL=false

for FLAG in "$@"; do
    if [ "$FLAG" == "--force-all" ] || [ "$FLAG" == "--fa" ]; then
        FORCE_ALL=true
    fi
done

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo valid files are staged for checking.${RESET}\n"
    exit 0
fi

ESLINT_TARGET=(".")
if ! $FORCE_ALL ; then
    readarray -t ESLINT_TARGET <<< "$STAGED_FILES"
fi

echo -e "${BOLD}\nRunning the ESLint (JavaScript) analysis tool...\n${RESET}"

# Run ESLint
npx eslint "${ESLINT_TARGET[@]}"

# Run ESLint
# -f: Format the output with eslint-formatter-unix lib.
OUTPUT=$(npx eslint -f unix "${ESLINT_TARGET[@]}")
if [ -z "$OUTPUT" ]; then
    echo -e "${GREEN}\nNo issues detected. Ready to commit.${RESET}\n"
    exit 0
fi

echo -e "${YELLOW}\nChecking staged files:\n${RESET}"

ROOT=$(basename "$(pwd)")

CLEAN_OUTPUT=""
while IFS= read -r FILE; do
    CLEAN_PATH=$(flycheck_to_unix_relative "$ROOT" "$FILE")
    if $FORCE_ALL || [[ ! "$FILE" =~ ^[A-Za-z]:\\.*:0:0: ]]; then
        CLEAN_OUTPUT="$CLEAN_OUTPUT"$'\n'"$CLEAN_PATH"
    fi
done <<< "$OUTPUT"

HAS_ERRORS=false
while IFS= read -r FILE; do
    if grep -q "^$FILE.*$" <<< "$CLEAN_OUTPUT"; then
        echo -e "File '${BOLD}$FILE${RESET}' contains errors."
        HAS_ERRORS=true
    fi
done <<< "$STAGED_FILES"

if "$HAS_ERRORS"; then
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nNo issues found! Ready to commit.${RESET}"