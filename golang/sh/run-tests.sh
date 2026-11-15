#!/bin/bash

_VERSION="1.7.0"
_PACKAGE="run-tests"
_DETAILS="Run all Go tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from math.sh
# shellcheck disable=SC1091
source ./tools/sh/math.sh

FLOWS=()

RACE=false
TAGS=()

VARIANT_TAGS=()

COVERAGE_ENABLED=false
COVERAGE_THRESHOLD=0

for FLAG in "$@"; do
    case "$FLAG" in
        --tags=* | --t=*)
            TAGS+=("${FLAG#*=}")
            ;;
        --variant-tags=* | --vt=*)
            VARIANT_TAGS+=("${FLAG#*=}")
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
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 2
            ;;
    esac
done

if ! [[ "$COVERAGE_THRESHOLD" =~ ^([0-9]+([.][0-9]+)?)$ ]] || 
    is_float_less_than "$COVERAGE_THRESHOLD" 0 || 
    is_float_greater_than "$COVERAGE_THRESHOLD" 100; then
        echo -e "\n${RED}  ✗ Invalid coverage threshold: ${COVERAGE_THRESHOLD}%${RESET}"
        exit 1
fi

# Run Go tests on all the Go files in the project
echo -e "\n${BOLD}Running Go tests...\n${RESET}"

ARGS=(-v -failfast)
TARGET="./..."

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
    FLOWS+=("-tags=${JOINED}")
    echo -e "  ${GREEN}✓ Main tags specified: ${YELLOW}${JOINED}${RESET}"
else
    FLOWS+=("")
fi

for VARIANT_TAG in "${VARIANT_TAGS[@]}"; do
    FLOWS+=("-tags=${VARIANT_TAG}")
    echo -e "  ${GREEN}✓ Build variant specified: ${YELLOW}${VARIANT_TAG}${RESET}"
done

TOTAL_FLOWS=${#FLOWS[@]}
FLOW_INDEX=0

INDENT=" "

for FLOW in "${FLOWS[@]}"; do
    ((FLOW_INDEX++))

    echo -e "\n${BOLD}Flow ${FLOW_INDEX}/${TOTAL_FLOWS} - Running${RESET}"

    FLOW_ARGS=()

    if [ -n "$FLOW" ]; then
        FLOW_ARGS+=("$FLOW")
    fi

    FLOW_ARGS+=("${ARGS[@]}")

    echo -e "\n${INDENT}- Target: ${YELLOW}${TARGET}${RESET}"
    echo -e "${INDENT}- Flags: ${YELLOW}${FLOW_ARGS[*]}${RESET}\n"

    OUTPUT=$(go test "${FLOW_ARGS[@]}" "${TARGET}")

    TEST_EXIT_CODE=$?

    while IFS= read -r LINE; do
        printf '%s%s\n' "$INDENT" "$LINE"
    done <<< "$OUTPUT"

    TOTAL_TESTS=$(echo "$OUTPUT" | grep -c 'RUN')

    echo -e "\n${INDENT}${BOLD}Total tests run: ${YELLOW}${TOTAL_TESTS}${RESET}"

    if [ $TEST_EXIT_CODE -ne 0 ]; then
    FAILED_TESTS=$(echo "$OUTPUT" | grep '^--- FAIL:' | awk '{print $3}')

        if [ -z "$FAILED_TESTS" ]; then
            echo -e "\n${RED}No specific failed tests found.${RESET}"
            exit $TEST_EXIT_CODE
        fi

        echo -e "\n${RED}Some tests failed. Please fix them before committing.${RESET}"

        FAILED_PACKAGES=$(echo "$OUTPUT" | grep '^FAIL\s' | awk '{print $2}')

        echo -e "\n${RED}Failed tests ($(echo "$FAILED_TESTS" | wc -l)):${RESET}"

        # shellcheck disable=SC2001
        echo "$FAILED_TESTS" | sed 's/^/  - /'

        echo -e "\n${RED}Failed packages ($(echo "$FAILED_PACKAGES" | wc -l)):${RESET}"

        # shellcheck disable=SC2001
        echo "$FAILED_PACKAGES" | sed 's/^/  - /'

        exit $TEST_EXIT_CODE
    fi

    COVERAGE_PERCENT=0
    if [ "$COVERAGE_ENABLED" = true ] && [ -f coverage.out ]; then
        COVERAGE_PERCENT=$(go tool cover -func=coverage.out | grep total | awk '{print $3}')
        echo -e "${INDENT}${BOLD}Code coverage: ${YELLOW}${COVERAGE_PERCENT}${RESET}"
    fi

    if is_float_greater_than "$COVERAGE_THRESHOLD" "0" && [ -n "$COVERAGE_PERCENT" ]; then
        COVERAGE_VALUE="${COVERAGE_PERCENT%\%}"

        if is_float_less_than "$COVERAGE_VALUE" "$COVERAGE_THRESHOLD"; then
            echo -e "\n${RED}Code coverage ${COVERAGE_PERCENT} is below the required threshold of ${COVERAGE_THRESHOLD}%.${RESET}"
            exit 1
        else
            echo -e "\n${INDENT}${GREEN}Code coverage ${COVERAGE_PERCENT} meets the required threshold of ${COVERAGE_THRESHOLD}%.${RESET}"
        fi
    fi
done

echo -e "\n${GREEN}All tests passed across ${TOTAL_FLOWS} flows! Ready to commit.${RESET}"
