#!/bin/bash

_VERSION="1.0.2"
_PACKAGE="check-mix-context"
_DETAILS="Executes functions to validate whether the current project is a valid Mix (Elixir) project."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Node utils.
# shellcheck disable=SC1091
source ./elixir/sh/utils-elixir.sh

PROJECT=false
STAGED=false
INSTALL=false

if [ "$#" -eq 0 ]; then
    PROJECT=true
    STAGED=true
    INSTALL=true
fi

for FLAG in "$@"; do
    case "$FLAG" in
        --project | --p)
            PROJECT=true
            ;;
        --staged | --s)
            STAGED=true
            ;;
        --install | --i)
            INSTALL=true
            ;;
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 2
            ;;
    esac
done

echo -e "\nChecking Mix (Elixir) context..."

if $PROJECT; then
    echo -e "\nVerifying if this is a Mix project..."
    ensure_mix_project && echo -e "${GREEN}\nMix project verified.${RESET}"
fi

if $STAGED; then
    echo -e "\nChecking for staged Elixir files..."
    ensure_elixir_staged && echo -e "${GREEN}\nStaged Elixir files found.${RESET}"
fi

if $INSTALL; then
    echo -e "\nVerifying if Elixir and Mix are installed..."
    ensure_elixir_installed && ensure_mix_installed && echo -e "${GREEN}\nElixir and Mix are installed.${RESET}"
fi