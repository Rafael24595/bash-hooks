#!/bin/bash

_VERSION="1.0.1"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Go utils.
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

PROJECT=false
STAGED=false
INSTALL=false

if [ "$#" -eq 0 ];then
    PROJECT=true
    STAGED=true
    INSTALL=true
fi

# Parse args
for arg in "$@"; do
    if [ "$arg" == "--project" ] || [ "$arg" == "-p" ]; then
        PROJECT=true
    fi
    if [ "$arg" == "--staged" ] || [ "$arg" == "-s" ]; then
        STAGED=true
    fi
    if [ "$arg" == "--install" ] || [ "$arg" == "-i" ]; then
        INSTALL=true
    fi
done

echo -e "\nChecking Golang context..."

if $PROJECT; then
    echo -e "\nVerifying if this is a Go project..."
    ensure_go_project && echo -e "${GREEN}\nGo project verified.${RESET}"
fi

if $STAGED; then
    echo -e "\nChecking for staged Go files..."
    ensure_go_staged && echo -e "${GREEN}\nStaged Go files found.${RESET}"
fi

if $INSTALL; then
    echo -e "\nVerifying if Go is installed..."
    ensure_go_installed && echo -e "${GREEN}\nGo is installed.${RESET}"
fi
