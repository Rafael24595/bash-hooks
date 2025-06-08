#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-npm-run"
_DETAILS="Executes an npm script command based on a configurable argument."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Ensure gofmt is available
if ! command -v npm &> /dev/null
then
    echo -e "${RED}\nnpm could not be found. Please install npm to proceed.${RESET}"
    exit 1
fi

echo -e "${BOLD}\nExecuting npm command...\n${RESET}"

COMMAND=$1 

npm run "${COMMAND}"

# Capture the exit code of `npm run`
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\nError: The command has been failed.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nThe command has been executed successfully.${RESET}"