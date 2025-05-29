#!/bin/bash

_VERSION="1.0.0"

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import Go utils.
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

echo -e "\nChecking Golang context...\n"

echo -e "Verifying if this is a Go project..."
ensure_go_project && echo -e "${GREEN}Go project verified.${RESET}"

echo -e "\nChecking for staged Go files..."
ensure_go_stagged && echo -e "${GREEN}Staged Go files found.${RESET}"

echo -e "\nVerifying if Go is installed..."
ensure_go_installed && echo -e "${GREEN}Go is installed.${RESET}"