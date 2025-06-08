#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-govulncheck"
_DETAILS="Executes govulncheck to check for vulnerabilities in dependencies."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Go utils.
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

INSTALL=false

# Parse args
for arg in "$@"; do
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        INSTALL=true
    fi
done

# Ensure that govulncheck is installed
if ! command -v govulncheck &> /dev/null
then
    if $INSTALL; then
        echo -e "${GREEN}Installing govulncheck...${RESET}"
        ensure_go_installed
        go install golang.org/x/vuln/cmd/govulncheck@latest
        echo -e "${GREEN}govulncheck installed.${RESET}"
    else
        echo -e "${RED}\ngovulncheck could not be found. Please install it to proceed.${RESET}"
        exit 1
    fi
fi

govulncheck -show verbose ./...

# Capture the exit code of `govulncheck`
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}\nError: Some vulnerabilities has been found. Please fix them before committing.${RESET}"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}\nNo vulnerabilities has been found! Ready to commit.${RESET}"