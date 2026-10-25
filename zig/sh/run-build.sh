#!/bin/bash

_VERSION="1.0.0"
_PACKAGE="run-build"
_DETAILS="Run build Zig project."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

CLEAN=false
OUTPUT="zig-out"

for FLAG in "$@"; do
    case "$FLAG" in
        --clean | --c)
            CLEAN=true
            ;;
        --output=* | --o=*)
            OUTPUT="${FLAG#*=}"
            ;;
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 1
            ;;
    esac
done

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${BOLD}\nRunning Zig build...\n${RESET}"

if ! zig build --prefix "$TEMP_DIR" ; then
    echo -e "${RED}\nError: Build failed. Please fix the issues before committing.${RESET}"
    exit 1
fi

if [[ "$CLEAN" == false ]]; then
    mkdir -p -- "$OUTPUT"
    cp -a -- "$TEMP_DIR"/. "$OUTPUT"/
fi

echo -e "${GREEN}\nBuild successful! Ready to commit.${RESET}"