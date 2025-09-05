#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="utils-node"
_DETAILS="Contains some utils to manage Node contexts."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

ensure_node_project() {
    if [ ! -f "package.json" ] && [ ! -f "yarn.lock" ] && [ ! -f "pnpm-lock.yaml" ]; then
        echo -e "${YELLOW}\nNot a Node project: package.json, yarn.lock or pnpm-lock.yaml not found.${RESET}"
        exit 1
    fi
}

ensure_node_installed() {
    if ! command -v node -v &> /dev/null; then
        echo -e "${RED}\nNode is not installed or not found in your system's PATH. Please install Node to proceed.${RESET}"
        exit 1
    fi
}

ensure_ecmascript_staged() {
    local TYPES=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --js)
            TYPES+=("*.js" "*.mjs" "*.cjs" "*.jsx")
            ;;
            --ts)
            TYPES+=("*.ts" "*.mts" "*.cts" "*.tsx")
            ;;
        esac
        shift
    done

    if [[ ${#TYPES[@]} -gt 0 ]]; then
        staged_go_files=$(git diff --cached --name-only -- "${TYPES[@]}")
        if [ -z "$staged_go_files" ]; then
            echo -e "${YELLOW}\nNo Ecmascript ${TYPES[*]} files are staged.${RESET}"
            exit 1
        fi
    else
        echo -e "${RED}\nNo file type specified (use --js, --ts, or both).${RESET}"
        exit 1
    fi
}
