#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="check-zig-context"
_DETAILS="Executes functions to validate whether the current project is a valid Zig project."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Go utils.
# shellcheck disable=SC1091
source ./zig/sh/utils-zig.sh

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

echo -e "\nChecking Zig context..."

if $PROJECT; then
    echo -e "\nVerifying if this is a Zig project..."
    ensure_zig_project && echo -e "${GREEN}\nZig project verified.${RESET}"
fi

if $STAGED; then
    echo -e "\nChecking for staged Zig files..."
    ensure_zig_staged && echo -e "${GREEN}\nStaged Zig files found.${RESET}"
fi

if $INSTALL; then
    echo -e "\nVerifying if Zig is installed..."
    ensure_zig_installed && echo -e "${GREEN}\nZig is installed.${RESET}"
fi
