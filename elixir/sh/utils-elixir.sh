#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="utils-elixir"
_DETAILS="Contains some utils to manage Elixir contexts."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Checks if inside a Mix project
ensure_mix_project() {
    if [ ! -f "mix.exs" ]; then
        echo -e "${YELLOW}\nNot an Elixir project: mix.exs not found.${RESET}"
        exit 1
    fi
}

# Checks if Elixir is installed
ensure_elixir_installed() {
    if ! command -v elixir &> /dev/null; then
        echo -e "${RED}\nElixir is not installed or not found in your system's PATH. Please install Elixir to proceed.${RESET}"
        exit 1
    fi
}

# Checks if Mix is installed
ensure_mix_installed() {
    if ! command -v mix &> /dev/null; then
        echo -e "${RED}\nMix (Elixir) is not installed or not found in your system's PATH. Please install Mix to proceed.${RESET}"
        exit 1
    fi
}

# Checks if there are any Elixir files staged
ensure_elixir_staged() {
    staged_elixir_files=$(git diff --cached --name-only -- "*.ex" "*.exs")
    if [ -z "$staged_elixir_files" ]; then
        echo -e "${YELLOW}\nNo Elixir files are staged.${RESET}"
        exit 1
    fi
}