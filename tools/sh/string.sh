#!/bin/bash

# Prints the length of the longest of the given strings, or the minimum when none is longer.
#
# Parameters:
#   $1  -> Minimum length
#   $2… -> Strings to measure
#
# Examples:
#   longest_length 6 "." "tools/a" "tools/longer"  => 12
#   longest_length 6 "."                           => 6
#   longest_length 6 "${MODULES[@]}"
longest_length() {
    local MIN_WIDTH=$1
    shift

    local STRING
    local WIDTH=$MIN_WIDTH

    for STRING in "$@"; do
        if (( ${#STRING} > WIDTH )); then
            WIDTH=${#STRING}
        fi
    done

    printf '%d\n' "$WIDTH"
}

# join_by prints the given strings joined by a separator.
#
# Parameters:
#   $1  -> Separator
#   $2… -> Strings to join
#
# Examples:
#   join_by ", " default g_ast_dbg  => default, g_ast_dbg
#   join_by ", " default            => default
join_by() {
    local SEPARATOR=$1
    shift

    local RESULT=""
    local FIRST=true

    local ITEM

    for ITEM in "$@"; do
        if $FIRST; then
            FIRST=false
        else
            RESULT+=$SEPARATOR
        fi
        RESULT+=$ITEM
    done

    printf '%s\n' "$RESULT"
}

# indent prints every line of a text with a prefix in front.
#
# Parameters:
#   $1 -> Prefix
#   $2 -> Text, one or more lines
#
# Examples:
#   indent "  - " $'a\nb'  => "  - a" and "  - b", each on its own line
indent() {
    local PREFIX=$1
    local LINE

    while IFS= read -r LINE; do
        printf '%s%s\n' "$PREFIX" "$LINE"
    done <<< "$2"
}
