#!/usr/bin/env bash

_VERSION="1.0.0"
_PACKAGE="sync-temp-tags"
_DETAILS="Sync tags in pre-commit-build.template.yml with the version in project.toml."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

PROJECT_FILE="project.toml"
TEMPLATE_FILE="pre-commit-build.template.yml"

if ! git diff --cached --name-only | grep -q "^${PROJECT_FILE}$"; then
    exit 0
fi

echo -e "${BOLD}\nSyncing tags...${RESET}"

PROJECT_VERSION=$(grep -A 5 '^\[project\]' "$PROJECT_FILE" | grep '^version' | head -n 1 | cut -d'"' -f2)
if [ -z "$PROJECT_VERSION" ]; then
    echo -e "${RED}\nError: The project version was not found in $PROJECT_FILE.${RESET}"
    exit 1
fi

echo -e "${YELLOW}\n - Detected version: $PROJECT_VERSION${RESET}"

sed -i "/origin: https:\/\/github.com\/Rafael24595\/bash-hooks/{n; s/tag: .*/tag: $PROJECT_VERSION/}" "$TEMPLATE_FILE"

echo -e "${GREEN}\nTags updated to $PROJECT_VERSION in $TEMPLATE_FILE.${RESET}"

git add "$TEMPLATE_FILE"