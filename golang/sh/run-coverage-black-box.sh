#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-coverage-black-box"
_DETAILS="This script runs black-box tests on Go packages and calculates code coverage."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

MIN_COVERAGE=$1
if [ -z "$MIN_COVERAGE" ]; then
    echo -e "${RED}Minimum coverage percentage not specified.${RESET}"
    exit 1
fi

VERBOSE=false
SUCCESS_EMPTY=false
INVALID_EMPTY=false
PACKAGE_LIST=()

# Parse flags
for ARG in "$@"; do
    case "$ARG" in
        --verbose | -v)
            VERBOSE=true
            ;;
        --success-empty | -se)
            SUCCESS_EMPTY=true
            ;;
        --invalid-empty | -ie)
            INVALID_EMPTY=true
            ;;
        --package=*)
            PACKAGE_LIST+=("${ARG#*=}")
            ;;
        --p=*)
            PACKAGE_LIST+=("${ARG#*=}")
            ;;
    esac
done


if [ -f coverage.out ]; then
    rm -f coverage.out
fi

echo -e "\nRunning tests to calculate coverage...\n"

process_package() {
    local PACKAGE_TEST="$1"
    local PACKAGE_SOURCE=${PACKAGE_TEST/test/src}

    if [ ! -d "$PACKAGE_SOURCE" ] || ! find "$PACKAGE_SOURCE" -maxdepth 1 -type f -name "*.go" | grep -q .; then
        return
    fi

    TEST_TARGET=""
    if $INVALID_EMPTY || find "$PACKAGE_TEST" -maxdepth 1 -type f -name "*.go" | grep -q .; then
        TEST_TARGET="./${PACKAGE_TEST#./}"
    fi

    echo -e "${GREEN}Testing '$PACKAGE_TEST' against '$PACKAGE_SOURCE'${RESET}\n"

    echo -e "${YELLOW}Global view of coverage:${RESET}"
    go test -coverpkg=./${PACKAGE_SOURCE#./} -coverprofile=tmp_coverage.out "$TEST_TARGET"
    EXIT_CODE_GLOBAL=$?
    if $VERBOSE; then
        echo -e "\n${YELLOW}Detailed coverage report:${RESET}"
        go tool cover -func=tmp_coverage.out
        EXIT_CODE_VERBOSE=$?
    fi
    
    EXIT_CODE_GLOBAL=${EXIT_CODE_GLOBAL:-0}
    EXIT_CODE_VERBOSE=${EXIT_CODE_VERBOSE:-0}
    if [ "$EXIT_CODE_GLOBAL" -ne 0 ] || [ "$EXIT_CODE_VERBOSE" -ne 0 ]; then
        echo -e "${RED}Something went wrong during testing coverage calculation.${RESET}"
        exit $EXIT_CODE
    fi

    if [ -f tmp_coverage.out ]; then
        if [ ! -f coverage.out ]; then
            cat tmp_coverage.out > coverage.out
        else
            tail -n +2 tmp_coverage.out >> coverage.out
        fi
        rm tmp_coverage.out
    fi

    echo -e "\n"
}

if [[ ${#PACKAGE_LIST[@]} -gt 0 ]]; then
    for PACKAGE_TEST in "${PACKAGE_LIST[@]}"; do
        process_package "$PACKAGE_TEST"
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo -e "${RED}Something went wrong during testing coverage calculation.${RESET}"
            exit $EXIT_CODE
        fi
    done
else
    while read -r PACKAGE_TEST; do
        process_package "$PACKAGE_TEST"
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo -e "${RED}Something went wrong during testing coverage calculation.${RESET}"
            exit $EXIT_CODE
        fi
    done < <(find ./test -type d)
fi


if [ ! -f coverage.out ]; then
    if $SUCCESS_EMPTY; then
        echo -e "${GREEN}No tests found, but success is allowed.${RESET}"
        exit 0
    else
        echo -e "${RED}No tests found, coverage file not generated.${RESET}"
        exit 1
    fi
    exit 1
fi

COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
    echo -e "${RED}Coverage $COVERAGE% is below threshold of $MIN_COVERAGE%${RESET}"
    exit 1
else
    echo -e "${GREEN}Coverage $COVERAGE% meets the threshold of $MIN_COVERAGE%${RESET}"
fi
