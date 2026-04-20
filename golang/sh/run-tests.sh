#!/bin/bash

_VERSION="1.3.0"
_PACKAGE="run-tests"
_DETAILS="Run all Go tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

RACE=false
TAGS=()

for FLAG in "$@"; do
    case "$FLAG" in
        --tags=* | --t=*)
            TAGS+=("${FLAG#*=}")
            ;;
        --race | --r)
            RACE=true
            ;;
    esac
done

# Run Go tests on all the Go files in the project
echo -e "${BOLD}\nRunning Go tests...\n${RESET}"

ARGS=(-v -failfast ./...)
if [ "$RACE" = true ]; then
    ARGS=(-race "${ARGS[@]}")
fi

if (( ${#TAGS[@]} > 0 )); then
    JOINED=$(IFS=,; echo "${TAGS[*]}")
    ARGS=(-tags="$JOINED" "${ARGS[@]}")
fi

# Run tests on all Go files in the repository (including any test files)
# -v for verbose output to see detailed results
# -failfast to stop at the first test failure
go test "${ARGS[@]}"

# Capture the exit code of `go test`
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\nError: Some tests failed. Please fix them before committing.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"