#!/bin/bash

_VERSION="1.1.1"
_PACKAGE="check-go-context"
_DETAILS="Executes functions to validate whether the current project is a valid Go project."

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

for FLAG in "$@"; do
    if [ "$FLAG" == "--project" ] || [ "$FLAG" == "--p" ]; then
        PROJECT=true
    fi
    if [ "$FLAG" == "--staged" ] || [ "$FLAG" == "--s" ]; then
        STAGED=true
    fi
    if [ "$FLAG" == "--install" ] || [ "$FLAG" == "--i" ]; then
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
