#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="utils-golang"
_DETAILS="Contains some utils to manage Go contexts."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Check if inside a Go project
ensure_go_project() {
    if [ ! -f "go.mod" ]; then
        echo -e "${YELLOW}\nNot a Go project: go.mod not found.${RESET}"
        exit 1
    fi
}

# Check if Go is installed
ensure_go_installed() {
    if ! command -v go &> /dev/null; then
        echo -e "${RED}\nGo is not installed or not found in your system's PATH. Please install Go to proceed.${RESET}"
        exit 1
    fi
}

# Check if there are any Go files staged
ensure_go_staged() {
    staged_go_files=$(git diff --cached --name-only -- "*.go")
    if [ -z "$staged_go_files" ]; then
        echo -e "${YELLOW}\nNo Go files are staged.${RESET}"
        exit 1
    fi
}

# Check if it is a Go context
ensure_go_context() {
    ensure_go_project
    ensure_go_staged
    ensure_go_installed
}
