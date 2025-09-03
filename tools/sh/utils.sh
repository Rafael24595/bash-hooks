#!/bin/bash

# Transforms a flycheck warning string into a Unix-style relative file path.
#
# Parameters:
#   $1 -> ROOT directory to make the path relative. Example: "go-api-front"
#   $2 -> FILE_PATH from flycheck warning (Windows or Unix style)
#
# Returns:
#   Relative Unix-style path of the file
#
# Examples:
#   "E:\Projects\go-api-front\src\store\theme\Themes.ts:58:35: Unexpected ..." 
#       => "src/store/theme/Themes.ts"
#   "src/store/theme/Themes.ts:58:35: Unexpected ..." 
#       => "src/store/theme/Themes.ts"
flycheck_to_unix_relative() {
    local ROOT=$1
    local FILE_PATH=$2

    local CLEAN_PATH="${FILE_PATH%%:[0-9]*:[0-9]*:* *}"
    local RELATIVE_PATH="${CLEAN_PATH#*"$ROOT"}"
    local UNIX_PATH="${RELATIVE_PATH//\\//}"

    if [[ $UNIX_PATH == /* ]]; then
        UNIX_PATH="${UNIX_PATH:1}"
    fi

    echo "$UNIX_PATH"
}
