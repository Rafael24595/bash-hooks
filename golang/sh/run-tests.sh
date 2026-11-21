#!/bin/bash

_VERSION="1.8.0"
_PACKAGE="run-tests"
_DETAILS="Run all Go tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from math.sh
# shellcheck disable=SC1091
source ./tools/sh/math.sh
# Import utility functions from string.sh
# shellcheck disable=SC1091
source ./tools/sh/string.sh
# Import utility functions from utils-golang.sh
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

# a prefix to format the modules output
INDENT=" "

FLOWS=()

VERBOSE=false

RACE=false
TAGS=()

VARIANT_TAGS=()

COVERAGE_ENABLED=false
COVERAGE_THRESHOLD=0

DISCOVER=false
DECLARED=()

for FLAG in "$@"; do
    case "$FLAG" in
        --verbose | --v)
            VERBOSE=true
            ;;
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
        --discover | --d)
            DISCOVER=true
            ;;
        --module=* | --m=*)
            IFS=',' read -r -a PARTS <<< "${FLAG#*=}"
            DECLARED+=("${PARTS[@]}")
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

COVER_FILE=$(mktemp)
trap 'rm -f "$COVER_FILE"' EXIT

echo -e "\n${BOLD}Running Go tests...\n${RESET}"

MODULES=$(resolve_go_modules "$DISCOVER" "${DECLARED[@]}") || exit $?

MODULE_LIST=()
while IFS= read -r MODULE; do
    MODULE_LIST+=("$MODULE")
done <<< "$MODULES"

ARGS=(-v -failfast)

if [[ "$RACE" == true ]]; then
    echo -e "  ${GREEN}✓ Race detection: ${YELLOW}enabled${RESET}"
    ARGS=(-race "${ARGS[@]}")
fi

if [[ "$COVERAGE_ENABLED" == true ]]; then
    ARGS=(-coverprofile="$COVER_FILE" "${ARGS[@]}")

    if is_float_greater_than "$COVERAGE_THRESHOLD" 0; then
        echo -e "  ${GREEN}✓ Coverage reporting: ${YELLOW}enabled (threshold ${COVERAGE_THRESHOLD}%)${RESET}"
    else
        echo -e "  ${GREEN}✓ Coverage reporting: ${YELLOW}enabled${RESET}"
    fi
fi

if (( ${#TAGS[@]} > 0 )); then
    JOINED=$(IFS=,; echo "${TAGS[*]}")
    FLOWS+=("-tags=${JOINED}")
    echo -e "  ${GREEN}✓ Main tags: ${YELLOW}${JOINED}${RESET}"
else
    FLOWS+=("")
fi

for VARIANT_TAG in "${VARIANT_TAGS[@]}"; do
    FLOWS+=("-tags=${VARIANT_TAG}")
    echo -e "  ${GREEN}✓ Build variant: ${YELLOW}${VARIANT_TAG}${RESET}"
done

FLOW_NAMES=()
for FLOW in "${FLOWS[@]}"; do
    FLOW_NAMES+=("${FLOW:-default}")
done

MODULE_LABELS=()
for MODULE in "${MODULE_LIST[@]}"; do
    MODULE_LABELS+=("$(module_label "$MODULE")")
done

RUNS=$(( ${#MODULE_LIST[@]} * ${#FLOWS[@]} ))

JOINED_MODULES=$(join_by ", " "${MODULE_LABELS[@]}")
if [[ "$DISCOVER" == true ]]; then
    echo -e "  ${GREEN}✓ Discovered modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
else
    echo -e "  ${GREEN}✓ Modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
fi

JOINED_FLOWS=$(join_by ", " "${FLOW_NAMES[@]}")

echo -e "  ${GREEN}✓ Flows (${#FLOWS[@]}): ${YELLOW}${JOINED_FLOWS}${RESET}"
echo -e "  ${GREEN}✓ Runs: ${YELLOW}${RUNS}${RESET}${GREEN} (${#MODULE_LIST[@]} module(s) x ${#FLOWS[@]} flow(s))${RESET}"

RESULT_MODULE=()
RESULT_FLOW=()
RESULT_STATUS=()
RESULT_TESTS=()
RESULT_COVERAGE=()
RESULT_FAILED_TESTS=()
RESULT_FAILED_PACKAGES=()
RESULT_DETAIL=()

record_result() {
    RESULT_MODULE+=("$1")
    RESULT_FLOW+=("$2")
    RESULT_STATUS+=("$3")
    RESULT_TESTS+=("$4")
    RESULT_COVERAGE+=("$5")
    RESULT_FAILED_TESTS+=("$6")
    RESULT_FAILED_PACKAGES+=("$7")
    RESULT_DETAIL+=("$8")
}

run_flow() {
    local MODULE=$1
    local POSITION=$2
    local REFERENCE=$3
    local FLOW=$4

    local -a FLOW_ARGS=()
    local COVERAGE=""

    local OUTPUT
    local EXIT_CODE
    local TOTAL
    local FAILED_TESTS
    local FAILED_PACKAGES

    local LABEL
    local MESSAGE

    LABEL="${POSITION} ${REFERENCE}"

    if [ -n "$FLOW" ]; then
        FLOW_ARGS+=("$FLOW")
    fi

    FLOW_ARGS+=("${ARGS[@]}")

    echo -e "\n${BOLD}Flow ${POSITION} - Running${RESET}\n"
    echo -e "${INDENT}- Module: ${YELLOW}$(module_label "$MODULE")${RESET}"
    echo -e "${INDENT}- Flags: ${YELLOW}${FLOW_ARGS[*]}${RESET}\n"

    : > "$COVER_FILE"

    OUTPUT=$(cd "$MODULE" && go test "${FLOW_ARGS[@]}" ./... 2>&1)
    EXIT_CODE=$?

    if [[ "$VERBOSE" == true ]] || [ "$EXIT_CODE" -ne 0 ]; then
        indent "$INDENT" "$OUTPUT"
    fi

    TOTAL=$(grep -c '^=== RUN' <<< "$OUTPUT")

    if [[ "$COVERAGE_ENABLED" == true ]] && [ -s "$COVER_FILE" ]; then
        COVERAGE=$(cd "$MODULE" && go tool cover -func="$COVER_FILE" | awk '/^total:/ {print $3}')
    fi

    echo -e "\n${INDENT}${BOLD}Total tests run: ${YELLOW}${TOTAL}${RESET}"

    if [ -n "$COVERAGE" ]; then
        echo -e "${INDENT}${BOLD}Code coverage: ${YELLOW}${COVERAGE}${RESET}"
    fi

    if [ "$EXIT_CODE" -ne 0 ]; then
        FAILED_TESTS=$(grep '^--- FAIL:' <<< "$OUTPUT" | awk '{print $3}')

        if [ -z "$FAILED_TESTS" ]; then
            record_result "$MODULE" "$LABEL" error "$TOTAL" "$COVERAGE" "" "" "$(tail -n 15 <<< "$OUTPUT")"
            return
        fi

        FAILED_PACKAGES=$(grep '^FAIL[[:space:]]' <<< "$OUTPUT" | awk '{print $2}')
        record_result "$MODULE" "$LABEL" failed "$TOTAL" "$COVERAGE" "$FAILED_TESTS" "$FAILED_PACKAGES" ""

        return
    fi

    if [ -n "$COVERAGE" ] && is_float_less_than "${COVERAGE%\%}" "$COVERAGE_THRESHOLD"; then
        MESSAGE="Coverage ${COVERAGE} is below the required ${COVERAGE_THRESHOLD}%."
        record_result "$MODULE" "$LABEL" low-coverage "$TOTAL" "$COVERAGE" "" "" "$MESSAGE"
        return
    fi

    record_result "$MODULE" "$LABEL" passed "$TOTAL" "$COVERAGE" "" "" ""
}

print_summary() {
    local FAILED=0

    local I
    local TEXT
    local COLOR

    local FAILED_TESTS
    local FAILED_PACKAGES

    local TEST_COUNT
    local PACKAGE_COUNT

    local MODULE_WIDTH
    local FLOW_WIDTH
    local TESTS_WIDTH
    local COVERAGE_WIDTH
    local COVERAGE

    local -a LABELS=()

    for I in "${!RESULT_MODULE[@]}"; do
        LABELS+=("$(module_label "${RESULT_MODULE[I]}")")
    done

    MODULE_WIDTH=$(longest_length 6 "${LABELS[@]}")
    FLOW_WIDTH=$(longest_length 4 "${RESULT_FLOW[@]}")
    TESTS_WIDTH=$(longest_length 5 "${RESULT_TESTS[@]}")
    COVERAGE_WIDTH=$(longest_length 8 "${RESULT_COVERAGE[@]}")

    echo -e "\n${BOLD}Summary: ${RESET}\n"

    printf "  %-${MODULE_WIDTH}s  %-${FLOW_WIDTH}s  %${TESTS_WIDTH}s  %${COVERAGE_WIDTH}s  %s\n" \
        Module Flow Tests Coverage Result

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            passed)
                COLOR=$GREEN
                TEXT="✓ passed"
                ;;
            failed)
                COLOR=$RED
                TEXT="✗ tests failed"
                ;;
            error)
                COLOR=$RED
                TEXT="✗ did not build or run"
                ;;
            low-coverage)
                COLOR=$RED;
                TEXT="✗ coverage below ${COVERAGE_THRESHOLD}%"
                ;;
        esac

        if [ "${RESULT_STATUS[I]}" != passed ]; then
            FAILED=$((FAILED + 1))
        fi

        COVERAGE=${RESULT_COVERAGE[I]}
        if [ -z "$COVERAGE" ]; then
            COVERAGE="-"
        fi

        printf "  %-${MODULE_WIDTH}s  %-${FLOW_WIDTH}s  %${TESTS_WIDTH}s  %${COVERAGE_WIDTH}s  ${COLOR}%s${RESET}\n" \
            "${LABELS[I]}" "${RESULT_FLOW[I]}" "${RESULT_TESTS[I]}" "${COVERAGE}" "$TEXT"
    done

    if (( FAILED == 0 )); then
        echo -e "\n${GREEN}All tests passed across ${#MODULE_LIST[@]} module(s) and ${#FLOWS[@]} flow(s)! Ready to commit.${RESET}"
        return 0
    fi

    echo -e "\n${RED}${BOLD}Failures: ${RESET}"

    for I in "${!LABELS[@]}"; do
        if [ "${RESULT_STATUS[I]}" = passed ]; then
            continue
        fi

        echo -e "\n  ${BOLD}${LABELS[I]}${RESET} (${RESULT_FLOW[I]}):"

        FAILED_TESTS="${RESULT_FAILED_TESTS[I]}"
        FAILED_PACKAGES="${RESULT_FAILED_PACKAGES[I]}"

        TEST_COUNT=$(grep -c . <<< "$FAILED_TESTS")
        PACKAGE_COUNT=$(grep -c . <<< "$FAILED_PACKAGES")

        if [ "${RESULT_STATUS[I]}" = failed ]; then
            echo "    Failed tests (${TEST_COUNT}):"
            indent "      - " "$FAILED_TESTS"
            echo "    Failed packages (${PACKAGE_COUNT}):"
            indent "      - " "$FAILED_PACKAGES"
        else
            indent "    " "${RESULT_DETAIL[I]}"
        fi
    done

    echo -e "\n${RED}${FAILED} of ${#LABELS[@]} run(s) failed. Please fix them before committing.${RESET}"

    return 1
}

TOTAL_FLOWS=${#FLOWS[@]}

for MODULE in "${MODULE_LIST[@]}"; do
    FLOW_INDEX=0
    for FLOW in "${FLOWS[@]}"; do
        FLOW_INDEX=$((FLOW_INDEX + 1))

        POSITION="${FLOW_INDEX}/${TOTAL_FLOWS}"
        REFERENCE="${FLOW:-default}"

        run_flow "$MODULE" "$POSITION" "$REFERENCE" "$FLOW"
    done
done

print_summary

exit $?
