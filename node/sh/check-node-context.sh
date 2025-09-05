#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="check-node-context"
_DETAILS="Executes functions to validate whether the current project is a valid Node project."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Node utils.
# shellcheck disable=SC1091
source ./node/sh/utils-node.sh

PROJECT=false
STAGED=()
INSTALL=false

if [ "$#" -eq 0 ]; then
    PROJECT=true
    STAGED=("--js" "--ts")
    INSTALL=true
fi

for FLAG in "$@"; do
    if [ "$FLAG" == "--project" ] || [ "$FLAG" == "--p" ]; then
        PROJECT=true
    fi
    if [ "$FLAG" == "--js-staged" ] || [ "$FLAG" == "--js" ]; then
        STAGED+=("--js")
    fi
    if [ "$FLAG" == "--ts-staged" ] || [ "$FLAG" == "--ts" ]; then
        STAGED+=("--ts")
    fi
    if [ "$FLAG" == "--install" ] || [ "$FLAG" == "--i" ]; then
        INSTALL=true
    fi
done

echo -e "\nChecking Node context..."

if $PROJECT; then
    echo -e "\nVerifying if this is a Node project..."
    ensure_node_project && echo -e "${GREEN}\nNode project verified.${RESET}"
fi

if [[ ${#STAGED[@]} -gt 0 ]]; then
    echo -e "\nChecking for staged Ecmascript ${STAGED[*]} files..."
    ensure_ecmascript_staged "${STAGED[@]}" && echo -e "${GREEN}\nStaged Ecmascript ${STAGED[*]} files found.${RESET}"
fi

if $INSTALL; then
    echo -e "\nVerifying if Node is installed..."
    ensure_node_installed && echo -e "${GREEN}\nNode is installed.${RESET}"
fi