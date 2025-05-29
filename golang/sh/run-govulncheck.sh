#!/bin/bash

_VERSION="1.0.0"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

AUTO_INSTALL=false

# Parse args
for arg in "$@"; do
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        AUTO_INSTALL=true
    fi
done

# Ensure that govulncheck is installed
if ! command -v govulncheck &> /dev/null
then
    if $AUTO_INSTALL; then
        echo -e "${GREEN}Installing govulncheck...${RESET}"
        eval "go install golang.org/x/vuln/cmd/govulncheck@latest"
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