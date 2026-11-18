#!/bin/bash

_VERSION="1.2.0"
_PACKAGE="check-go-context"
_DETAILS="Executes functions to validate whether the current project is a valid Go project."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Go utils.
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

INSTALL=false
PROJECT=false
STAGED=false

DISCOVER=false
DECLARED=()

for FLAG in "$@"; do
    case "$FLAG" in
        --install | --i)
            INSTALL=true
            ;;
        --project | --p)
            PROJECT=true
            ;;
        --staged | --s)
            STAGED=true
            ;;
        --discover | --d)
            DISCOVER=true
            ;;
        --module=* | --m=*)
            IFS=',' read -r -a PARTS <<< "${FLAG#*=}"
            DECLARED+=("${PARTS[@]}")
            ;;
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 2
            ;;
    esac
done

if ! $PROJECT && ! $STAGED && ! $INSTALL; then
    INSTALL=true
    PROJECT=true
    STAGED=true
fi

echo -e "\nChecking Golang context..."

if $DISCOVER; then
    echo -e "\nDiscovering Go modules..."
fi

MODULES=$(resolve_go_modules "$DISCOVER" "${DECLARED[@]}") || exit $?

if $INSTALL; then
    echo -e "\nVerifying if Go is installed..."
    ensure_go_installed && echo -e "${GREEN}\nGo is installed.${RESET}"
fi

if $PROJECT; then
    echo -e "\nVerifying if this is a Go project..."
    ensure_go_project "$MODULES" && echo -e "${GREEN}\nGo project verified.${RESET}"
fi

if $STAGED; then
    echo -e "\nChecking for staged Go files..."
    ensure_go_staged "$MODULES" && echo -e "${GREEN}\nStaged Go files found.${RESET}"
fi
