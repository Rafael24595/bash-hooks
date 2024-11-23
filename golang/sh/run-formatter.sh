#!/bin/bash

_VERSION="1.0.0"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Ensure gofmt is available
if ! command -v gofmt &> /dev/null
then
    echo -e "${RED}\ngofmt could not be found. Please install Go to proceed.${RESET}"
    exit 1
fi

# Get a list of Go files that are staged for commit
STAGED_FILES=$(git diff --name-only --cached --diff-filter=AM)

# If no Go files are staged, exit early
if [ -z "$STAGED_FILES" ]; then
    echo -e "${RED}\nNo Go files staged for commit. Cannot formatting.${RESET}"
    exit 0
fi

# Show the staged Go files
echo -e "${BOLD}\nStaged Go files to format:\n${RESET}"

# Format each staged Go file
for FILE in $STAGED_FILES; do
    if [ -f "$FILE" ]; then
        echo -e "Formatting '${BOLD}$FILE${RESET}'..."
        gofmt -w "$FILE"  # The -w flag will overwrite the file with the formatted version

        # Stage the formatted file so it's included in the commit
        git add "$FILE"
    else
        echo -e "${RED}File not found: ${BOLD}$FILE${RESET}"
        exit 1
    fi
done

echo -e "${GREEN}\nAll staged Go files are formatted. Ready to commit.${RESET}"
