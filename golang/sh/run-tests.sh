#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-tests"
_DETAILS="Run all Go tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Run Go tests on all the Go files in the project
echo -e "${BOLD}\nRunning Go tests...\n${RESET}"

# Run tests on all Go files in the repository (including any test files)
# -v for verbose output to see detailed results
# -failfast to stop at the first test failure
go test -v -failfast ./...

# Capture the exit code of `go test`
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\nError: Some tests failed. Please fix them before committing.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"