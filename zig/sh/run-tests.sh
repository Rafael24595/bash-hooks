#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-tests"
_DETAILS="Run all Zig tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

echo -e "${BOLD}\nRunning Zig tests...\n${RESET}"

if ! zig build test ; then
    echo -e "${RED}\nError: Some tests failed. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"