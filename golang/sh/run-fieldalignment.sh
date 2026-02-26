#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-fieldalignment"
_DETAILS="Run fieldalignment analysis tool."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

PERCENT=25

for FLAG in "$@"; do
    case "$FLAG" in
        --percent=* | --p=*)
            PERCENT="${FLAG#*=}"
            ;;
    esac
done

# Get a list of Go files that are staged for commit
STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)

# If no Go files are staged, exit early
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo Go files staged for commit. Cannot formatting.${RESET}"
    exit 0
fi

# Ensure fieldalignment is available
if ! command -v fieldalignment &> /dev/null; then
    echo -e "${RED}\nfieldalignment could not be found. Please install it to proceed.${RESET}"
    exit 1
fi

echo -e "${BOLD}\nMemory Alignment Check\n${RESET}"
echo -e "${CYAN}Target threshold: ${PERCENT}% saving per struct${RESET}"
echo -e "${GRAY}--------------------------------------------------------${RESET}"

# Run fieldalignment and remove absolute path prefix to make output cleaner and easier to parse.
OUTPUT=$(fieldalignment ./... 2>&1 | sed "s|$(pwd)/||g")

# If there is no output, no issues were detected.
if [ -z "$OUTPUT" ]; then
    echo -e "${GREEN}\nNo issues detected. Ready to commit.${RESET}\n"
    exit 0
fi

HAS_ERRORS=false

# Iterate over each staged file.
while IFS= read -r FILE; do

    # Filter tool output to include only lines for the current file
    INCIDENTS=$(echo "$OUTPUT" | grep "^$FILE")
    [[ -z "$INCIDENTS" ]] && continue

    # Process each detected incident for the file
    while IFS= read -r LINE; do
        [[ -z "$LINE" ]] && continue

        NATURAL=$(echo "$LINE" | awk '{print $(NF-5)}')
        OPTIMAL=$(echo "$LINE" | awk '{print $NF}')
        [[ ! "$NATURAL" =~ ^[0-9]+$ ]] || [[ ! "$OPTIMAL" =~ ^[0-9]+$ ]] && continue

        LIMIT=$(( (NATURAL * PERCENT) / 100 ))
        RATIO=$(( NATURAL - OPTIMAL ))

        LOCATION="${LINE%: struct*}"

        # Attempt to determine struct name from source code
        LINE_NUM=$(echo "$LOCATION" | cut -d: -f2)
        STRUCT_NAME=$(sed -n "${LINE_NUM}p" "$FILE" | awk '/type/ {for(i=1;i<=NF;i++) if($i=="type") print $(i+1)}')
        [[ -z "$STRUCT_NAME" ]] && STRUCT_NAME="anonymous struct"

        # If savings are below the configured threshold, accept it.
        if [ "$RATIO" -lt "$LIMIT" ]; then
            echo -e "\n${GREEN}✓${RESET} ${STRUCT_NAME} (${LOCATION})"
            echo -e "  ↳ ${GRAY}Current: ${NATURAL}B | Optimal: ${OPTIMAL}B | Savings: ${RATIO}B (Below limit)${RESET}"
                continue
        fi

        # If savings exceed the threshold, mark as error.
        echo -e "\n${RED}✗${RESET} ${BOLD}${STRUCT_NAME}${RESET} (${LOCATION})"
        echo -e "  ↳ ${RED}Overhead:${RESET} ${NATURAL}B → ${GREEN}Optimal:${RESET} ${OPTIMAL}B | ${BOLD}Savings: ${RATIO}B${RESET} (Limit: ${LIMIT}B)"
        HAS_ERRORS=true
    done <<< "$INCIDENTS"
done <<< "$STAGED_FILES"

# If at least one struct exceeded the threshold, block the commit.
if [ "$HAS_ERRORS" = true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nNo issues found! Ready to commit.${RESET}"
