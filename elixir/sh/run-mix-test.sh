#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-tests"
_DETAILS="Run Mix tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

echo -e "${BOLD}\nRunning Mix(Elixir) tests...\n${RESET}"

# Run all Mix tests
# --no-start: Does not start applications after compilation
# --warnings-as-errors: Treats compilation warnings (from loading the test suite) as errors and returns a non-zero exit status
mix test --no-start --warnings-as-errors

TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\nError: Some tests failed. Please fix them before committing.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"