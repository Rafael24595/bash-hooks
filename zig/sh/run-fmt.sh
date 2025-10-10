#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-fmt"
_DETAILS="Run Zig's fmt to check staged files for formatting issues and optionally fix them."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

APPLY=false

if [ "$#" -eq 0 ]; then
    APPLY=false
fi

for FLAG in "$@"; do
    if [ "$FLAG" == "--apply" ] || [ "$FLAG" == "--a" ]; then
        APPLY=true
    fi
done

mapfile -t STAGED_FILES < <(git diff --name-only --cached --diff-filter=ACMR | grep -E '\.(zig|zon)$')
if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}\nNo Zig files are staged. Nothing to check.${RESET}\n"
    exit 0
fi

echo -e "${BOLD}\nChecking staged Zig files format...${RESET}"

FILES=$(zig fmt --check "${STAGED_FILES[@]}")
if [ -z "$FILES" ]; then
  echo -e "${GREEN}\nNo unformatted files found.${RESET}"
  exit 0
fi

echo -e "\n The following files are not formatted:"
while IFS= read -r FILE; do
    echo -e "  ${BOLD}>${RESET} ${RED}$FILE${RESET}"
done <<< "$FILES"
echo -e ""

if [ "$APPLY" == false ]; then
  exit 1
fi

echo -e "${BOLD}Fix the unformatting files...${RESET}\n"

for FILE in $FILES; do
  if [ -f "$FILE" ]; then
      echo -e " Formatting '${BOLD}$FILE${RESET}'..."
      _=$(zig fmt "$FILE")
      git add "$FILE"
  else
      echo -e "${RED} File not found: ${BOLD}$FILE${RESET}"
      exit 1
  fi
done

echo -e "${GREEN}\nAll staged Zig files are formatted. Ready to commit.${RESET}"
