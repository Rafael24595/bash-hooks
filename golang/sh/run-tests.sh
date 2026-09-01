#!/bin/bash

_VERSION="1.6.0"
_PACKAGE="run-tests"
_DETAILS="Run all Go tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from math.sh
# shellcheck disable=SC1091
source ./tools/sh/math.sh

RACE=false
TAGS=()

COVERAGE_ENABLED=false
COVERAGE_THRESHOLD=0

for FLAG in "$@"; do
    case "$FLAG" in
        --tags=* | --t=*)
            TAGS+=("${FLAG#*=}")
            ;;
        --race | --r)
            RACE=true
            ;;
        --cover | --c)
            COVERAGE_ENABLED=true
            ;;
        --cover=* | --c=*)
            COVERAGE_ENABLED=true
            COVERAGE_THRESHOLD="${FLAG#*=}"
            ;;
    esac
done

if ! [[ "$COVERAGE_THRESHOLD" =~ ^([0-9]+([.][0-9]+)?)$ ]] || 
    is_float_less_than "$COVERAGE_THRESHOLD" 0 || 
    is_float_greater_than "$COVERAGE_THRESHOLD" 100; then
        echo -e "${RED}\n  ✗ Invalid coverage threshold: ${COVERAGE_THRESHOLD}%${RESET}"
        exit 1
fi

# Run Go tests on all the Go files in the project
echo -e "${BOLD}\nRunning Go tests...\n${RESET}"

ARGS=(-v -failfast ./...)

if [ "$RACE" = true ]; then
    echo -e "  ${GREEN}✓ Race detection enabled.${RESET}"
    ARGS=(-race "${ARGS[@]}")
fi

if [ "$COVERAGE_ENABLED" = true ]; then
    echo -e "  ${GREEN}✓ Coverage reporting enabled.${RESET}"
    ARGS=(-coverprofile=coverage.out "${ARGS[@]}")
fi

if is_float_greater_than "$COVERAGE_THRESHOLD" "0"; then
    echo -e "  ${GREEN}✓ Coverage threshold: ${YELLOW}${COVERAGE_THRESHOLD}%${RESET}"
fi

if (( ${#TAGS[@]} > 0 )); then
    JOINED=$(IFS=,; echo "${TAGS[*]}")
    echo -e "  ${GREEN}✓ Tags specified: ${YELLOW}${JOINED}${RESET}"
    ARGS=(-tags="$JOINED" "${ARGS[@]}")
fi

# Run tests on all Go files in the repository (including any test files)
# -v for verbose output to see detailed results
# -failfast to stop at the first test failure
OUTPUT=$(go test "${ARGS[@]}")

# Capture the exit code of `go test`
TEST_EXIT_CODE=$?

TOTAL_TESTS=$(echo "$OUTPUT" | grep -c 'RUN')

printf "%b\n" "$OUTPUT"

echo -e "${BOLD}\nTotal tests run: ${YELLOW}${TOTAL_TESTS}${RESET}"

if [ $TEST_EXIT_CODE -ne 0 ]; then
   FAILED_TESTS=$(echo "$OUTPUT" | grep '^--- FAIL:' | awk '{print $3}')

    if [ -z "$FAILED_TESTS" ]; then
        echo -e "${RED}\nNo specific failed tests found.${RESET}"
        exit $TEST_EXIT_CODE
    fi

    echo -e "${RED}\nSome tests failed. Please fix them before committing.${RESET}"

    FAILED_PACKAGES=$(echo "$OUTPUT" | grep '^FAIL\s' | awk '{print $2}')

    echo -e "${RED}\nFailed tests ($(echo "$FAILED_TESTS" | wc -l)):${RESET}"

    # shellcheck disable=SC2001
    echo "$FAILED_TESTS" | sed 's/^/  - /'

    echo -e "${RED}\nFailed packages ($(echo "$FAILED_PACKAGES" | wc -l)):${RESET}"

    # shellcheck disable=SC2001
    echo "$FAILED_PACKAGES" | sed 's/^/  - /'

    exit $TEST_EXIT_CODE
fi

COVERAGE_PERCENT=0
if [ "$COVERAGE_ENABLED" = true ] && [ -f coverage.out ]; then
    COVERAGE_PERCENT=$(go tool cover -func=coverage.out | grep total | awk '{print $3}')
    echo -e "${BOLD}Code coverage: ${YELLOW}${COVERAGE_PERCENT}${RESET}"
fi

if is_float_greater_than "$COVERAGE_THRESHOLD" "0" && [ -n "$COVERAGE_PERCENT" ]; then
    COVERAGE_VALUE="${COVERAGE_PERCENT%\%}"

    if is_float_less_than "$COVERAGE_VALUE" "$COVERAGE_THRESHOLD"; then
        echo -e "${RED}\nCode coverage ${COVERAGE_PERCENT} is below the required threshold of ${COVERAGE_THRESHOLD}%.${RESET}"
        exit 1
    else
        echo -e "${GREEN}\nCode coverage ${COVERAGE_PERCENT} meets the required threshold of ${COVERAGE_THRESHOLD}%.${RESET}"
    fi
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"
exit 0

