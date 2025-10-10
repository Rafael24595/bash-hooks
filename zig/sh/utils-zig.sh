#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="utils-zig"
_DETAILS="Contains some utils to manage Zig contexts."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

ensure_zig_project() {
    if [ ! -f "build.zig" ]; then
        echo -e "${YELLOW}\nNot a Zig project: build.zig not found.${RESET}"
        exit 1
    fi
}

ensure_zig_installed() {
    if ! command -v zig version &> /dev/null; then
        echo -e "${RED}\nZig is not installed or not found in your system's PATH. Please install Zig to proceed.${RESET}"
        exit 1
    fi
}

ensure_zig_staged() {
    mapfile -t STAGED_FILES < <(git diff --name-only --cached --diff-filter=ACMR | grep -E '\.(zig|zon)$')
    if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}\nNo Zig files are staged.${RESET}"
        exit 1
    fi
}

ensure_zig_context() {
    ensure_zig_project
    ensure_zig_staged
    ensure_zig_installed
}
