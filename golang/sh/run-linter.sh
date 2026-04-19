#!/bin/bash

_VERSION="1.2.0"
_PACKAGE="run-linter"
_DETAILS="Runs golangci-lint to find errors in staged Go files."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

INSTALL=false
ENABLE=()

for FLAG in "$@"; do
    case "$FLAG" in
        --install | --i)
            INSTALL=true
            ;;
        --enable=* | --e=*)
            ENABLE+=("${FLAG#*=}")
            ;;
    esac
done

# Ensure that golangci-lint is installed
if ! command -v golangci-lint &> /dev/null
then
    if $INSTALL; then
        echo -e "${GREEN}Installing golangci-lint...${RESET}"
        ensure_go_installed
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        echo -e "${GREEN}golangci-lint installed.${RESET}"
    else
        echo -e "${RED}\ngolangci-lint could not be found. Please install it to proceed.${RESET}"
        exit 1
    fi
fi

STAGED_FILES=$(git diff --name-only --cached --diff-filter=ACMR)
# Check if no files are staged
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo valid files are staged for checking.${RESET}\n"
    exit 0
fi

# Run golangci-lint across the entire repository (all Go files)
echo -e "${BOLD}\nRunning golangci-lint on all Go files in the repository...${RESET}"

ARGS=(--color always ./...)
if (( ${#ENABLE[@]} > 0 )); then
    JOINED=$(IFS=,; echo "${ENABLE[*]}")
    ARGS=(--enable "$JOINED" "${ARGS[@]}")
fi

OUTPUT=$(golangci-lint run "${ARGS[@]}")

LINT_FILES=$(grep -oE '[^[:space:]]+\.go' <<< "$OUTPUT")
# Check if no files contains errors
if [ -z "$LINT_FILES" ]; then
    echo -e "${GREEN}\nNo files contain errors. Ready to commit.${RESET}\n"
    exit 0
fi

echo -e "${YELLOW}\nError report:${RESET}"
echo "$OUTPUT"

echo -e "${YELLOW}\nChecking staged files:\n${RESET}"

LINT_FILES=$(echo "$LINT_FILES" \
  | sed 's/\\/\//g' \
  | tr -d '\r' \
  | sed -E 's/\x1B\[[0-9;]*[mK]//g')

STAGED_FILES=$(echo "$STAGED_FILES" \
    | tr -d '\r' \
    | sort -u)

HAS_ERRORS=false
while IFS= read -r FILE; do
    if grep -Fxq "$FILE" <<< "$LINT_FILES"; then
        echo -e "File '${BOLD}$FILE${RESET}' contains errors."
        HAS_ERRORS=true
    fi
done <<< "$STAGED_FILES"

# Check the boolean variable after the loop
if [ "$HAS_ERRORS" = true ]; then
    echo -e "${RED}\nError: At least one staged file contains errors. Please fix them before committing.${RESET}"
    exit 1
fi

echo -e "${GREEN}\nAll Go files passed the linter. Ready to commit.${RESET}"
