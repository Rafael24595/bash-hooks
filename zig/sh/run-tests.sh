#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-tests"
_DETAILS="Run all Zig tests."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

SUMMARY="failures"

for FLAG in "$@"; do
    case "$FLAG" in
        --summary | --s)
            SUMMARY="all"
            ;;
        --summary=* | --s=*)
            SUMMARY="${FLAG#*=}"
            ;;
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 2
            ;;
    esac
done

echo -e "${BOLD}\nRunning Zig tests...${RESET}"

if ! zig build test --summary "$SUMMARY" ; then
    echo -e "${RED}\nError: Some tests failed. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll tests passed! Ready to commit.${RESET}"