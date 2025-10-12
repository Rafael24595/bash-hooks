#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-check"
_DETAILS="Run Zig's ast-check on staged Zig files to detect errors."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

mapfile -t STAGED_FILES < <(git diff --name-only --cached --diff-filter=ACMR | grep -E '\.(zig|zon)$')
if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}\nNo Zig files are staged. Nothing to check.${RESET}\n"
    exit 0
fi

echo -e "${BOLD}\nChecking staged Zig files status...\n${RESET}"

FILES=()
HAS_ERRORS=false
for FILE in "${STAGED_FILES[@]}"; do
    echo -e "Checking '${BOLD}$FILE${RESET}'..."
    if ! zig ast-check "$FILE"; then
        echo ""
        FILES+=("$FILE")
        HAS_ERRORS=true
    else
        echo -e "${GREEN}No errors found.${RESET}\n"    
    fi
done

for FILE in "${FILES[@]}"; do
    echo -e "File '${BOLD}$FILE${RESET}' contains errors."
done

if [ "$HAS_ERRORS" == true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nNo issues found! Ready to commit.${RESET}"
