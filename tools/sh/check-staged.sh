#!/bin/bash

_VERSION="1.0.0"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

STAGED_FILES=$(git diff --name-only --cached)
# Check if no files are staged
if [ -z "$STAGED_FILES" ]; then
    echo -e "${RED}\nNo files are staged for commit.${RESET}\n"
    exit 1
fi
