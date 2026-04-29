#!/bin/bash

_VERSION="1.4.0"
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
OUTPUT=$(go test "${ARGS[@]}")

# Capture the exit code of `go test`
TEST_EXIT_CODE=$?

printf "%b\n" "$OUTPUT"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"
    exit 0
fi

FAILED_TESTS=$(echo "$OUTPUT" | grep '^--- FAIL:' | awk '{print $3}')
FAILED_PACKAGES=$(echo "$OUTPUT" | grep '^FAIL\s' | awk '{print $2}')

echo -e "${RED}\nSome tests failed. Please fix them before committing.${RESET}"

echo -e "${RED}\nFailed tests ($(echo "$FAILED_TESTS" | wc -l)):${RESET}"

# shellcheck disable=SC2001
echo "$FAILED_TESTS" | sed 's/^/  - /'

echo -e "${RED}\nFailed packages ($(echo "$FAILED_PACKAGES" | wc -l)):${RESET}"

# shellcheck disable=SC2001
echo "$FAILED_PACKAGES" | sed 's/^/  - /'

exit $TEST_EXIT_CODE
