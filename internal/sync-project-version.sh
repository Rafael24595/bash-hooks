#!/usr/bin/env bash

_VERSION="1.0.0"
_PACKAGE="sync-project-version"
_DETAILS="Sync project version in bash-hooks with the version in project.toml."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import sources from project.sh
# shellcheck disable=SC1091
source ./internal/scripts/project.sh

PROJECT_FILE="project.toml"
BASH_HOOKS="bash-hooks"

if ! git diff --cached --name-only | grep -q "^${PROJECT_FILE}$"; then
    exit 0
fi

echo -e "${BOLD}\nSyncing project version...${RESET}"

PROJECT_VERSION=$(read_staged_project_version "$PROJECT_FILE") || exit $?
SED_EXPR="s/^_PROJECT_VERSION=\".*\"$/_PROJECT_VERSION=\"${PROJECT_VERSION}\"/"

echo -e "${YELLOW}\n - Detected version: $PROJECT_VERSION${RESET}"

sed_stage "$SED_EXPR" "$BASH_HOOKS"

echo -e "${GREEN}\nProject version updated to $PROJECT_VERSION in $BASH_HOOKS.${RESET}"
