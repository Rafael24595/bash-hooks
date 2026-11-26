#!/usr/bin/env bash

_VERSION="1.1.0"
_PACKAGE="sync-temp-tags"
_DETAILS="Sync tags in pre-commit-build.template.yml with the version in project.toml."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import sources from project.sh
# shellcheck disable=SC1091
source ./internal/scripts/project.sh

PROJECT_FILE="project.toml"
TEMPLATE_FILE="pre-commit-build.template.yml"

if ! git diff --cached --name-only | grep -q "^${PROJECT_FILE}$"; then
    exit 0
fi

echo -e "${BOLD}\nSyncing tags...${RESET}"

PROJECT_VERSION=$(read_staged_project_version "$PROJECT_FILE") || exit $?
SED_EXPR="/origin: https:\/\/github.com\/Rafael24595\/bash-hooks/{n; s/tag: .*/tag: $PROJECT_VERSION/}"

echo -e "${YELLOW}\n - Detected version: $PROJECT_VERSION${RESET}"

sed_stage "$SED_EXPR" "$TEMPLATE_FILE"

echo -e "${GREEN}\nTags updated to $PROJECT_VERSION in $TEMPLATE_FILE.${RESET}"
