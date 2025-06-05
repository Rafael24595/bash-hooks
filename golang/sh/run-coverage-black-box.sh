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

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --verbose | -v)
            VERBOSE=true
            ;;
        --success-empty | -se)
            SUCCESS_EMPTY=true
            ;;
    esac
done


if [ -f coverage.out ]; then
    rm -f coverage.out
fi

echo -e "\nRunning tests to calculate coverage...\n"

while read -r PACKAGE_TEST; do
    PACKAGE_SOURCE=${PACKAGE_TEST/test/src}

    if [ ! -d "$PACKAGE_SOURCE" ] || ! find "$PACKAGE_SOURCE" -maxdepth 1 -type f | read; then
        continue
    fi

    echo -e "${GREEN}Testing '$PACKAGE_TEST' against '$PACKAGE_SOURCE'${RESET}\n"

    echo -e "${YELLOW}Global view of coverage:${RESET}"
    go test -coverpkg=./${PACKAGE_SOURCE#./} -coverprofile=tmp_coverage.out ./${PACKAGE_TEST#./}
    if $VERBOSE; then
        echo -e "\n${YELLOW}Detailed coverage report:${RESET}"
        go tool cover -func=tmp_coverage.out
    fi
    
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
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
done < <(find ./test -type d)

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
