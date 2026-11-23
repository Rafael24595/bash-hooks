#!/bin/bash

_VERSION="1.1.0"
_PACKAGE="run-fieldalignment"
_DETAILS="Run fieldalignment analysis tool."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from string.sh
# shellcheck disable=SC1091
source ./tools/sh/string.sh
# Import utility functions from utils-golang.sh
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

# a finding of fieldalignment: "path:line:column: Name has …"
FINDING_LINE='^(.+\.go):([0-9]+):[0-9]+: ([^ ]+) has (.+)$'
# the waste computed by fieldalignment for a size finding: "… (33%)"
WASTE_PERCENT='\(([0-9]+)%\)$'
# a finding about pointer data instead of size: informational only
POINTER_FINDING='leading bytes of pointer data'
# a prefix to format the modules output
INDENT=" "

VERBOSE=false

PERCENT=25

DISCOVER=false
DECLARED=()

for FLAG in "$@"; do
    case "$FLAG" in
        --verbose | --v)
            VERBOSE=true
            ;;
        --percent=* | --p=*)
            PERCENT="${FLAG#*=}"
            ;;
        --discover | --d)
            DISCOVER=true
            ;;
        --module=* | --m=*)
            IFS=',' read -r -a PARTS <<< "${FLAG#*=}"
            DECLARED+=("${PARTS[@]}")
            ;;
        *)
            echo -e "${RED}\nError: unknown option: $FLAG${RESET}"
            exit 2
            ;;
    esac
done

# Ensure fieldalignment is available
if ! command -v fieldalignment &> /dev/null; then
    echo -e "${RED}\nfieldalignment could not be found. Please install it to proceed.${RESET}"
    exit 1
fi

if ! [[ "$PERCENT" =~ ^[0-9]+$ ]] || (( PERCENT > 100 )); then
    echo -e "${RED}\nError: --percent must be an integer between 0 and 100: $PERCENT${RESET}"
    exit 2
fi

echo -e "${BOLD}\nRunning fieldalignment...\n${RESET}"

REPO_ROOT=$(git rev-parse --show-toplevel)

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}\nNo Go files staged for commit. Cannot run fieldalignment.${RESET}"
    exit 0
fi

MODULES=$(resolve_go_modules "$DISCOVER" "${DECLARED[@]}") || exit $?

MODULE_LIST=()
while IFS= read -r MODULE; do
    MODULE_LIST+=("$MODULE")
done <<< "$MODULES"

MODULE_LABELS=()
for MODULE in "${MODULE_LIST[@]}"; do
    MODULE_LABELS+=("$(module_label "$MODULE")")
done

JOINED_MODULES=$(join_by ", " "${MODULE_LABELS[@]}")
if [[ "$DISCOVER" == true ]]; then
    echo -e "  ${GREEN}✓ Discovered modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
else
    echo -e "  ${GREEN}✓ Modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
fi

echo -e "  ${GREEN}✓ Threshold: ${YELLOW}${PERCENT}%${RESET}"

RESULT_MODULE=()
RESULT_STATUS=()
RESULT_STRUCTS=()
RESULT_BELOW=()
RESULT_POINTERS=()
RESULT_UNSTAGED=()
RESULT_REPORT=()
RESULT_DETAIL=()

record_result() {
    RESULT_MODULE+=("$1")
    RESULT_STATUS+=("$2")
    RESULT_STRUCTS+=("$3")
    RESULT_BELOW+=("$4")
    RESULT_POINTERS+=("$5")
    RESULT_UNSTAGED+=("$6")
    RESULT_REPORT+=("$7")
    RESULT_DETAIL+=("$8")
}

scan_module() {
    local MODULE=$1
    local POSITION=$2

    local LINE
    local OUTPUT
    local PLAIN
    local EXIT_CODE

    local FILE
    local LOCATION
    local NAME
    local MESSAGE
    local WASTE

    local TOTAL=0
    local STRUCTS=0
    local BELOW=0
    local POINTERS=0
    local UNSTAGED=0

    local REPORT=""

    echo -e "\n${BOLD}Module ${POSITION} - Checking alignment${RESET}\n"
    echo -e "${INDENT}- Module: ${YELLOW}$(module_label "$MODULE")${RESET}\n"

    OUTPUT=$(cd "$MODULE" && fieldalignment ./... 2>&1)
    EXIT_CODE=$?

    if [[ "$VERBOSE" == true ]]; then
        indent "$INDENT" "$OUTPUT"
    fi

    if (( EXIT_CODE != 0 && EXIT_CODE != 3 )); then
        record_result "$MODULE" error - - - - "" "$(tail -n 15 <<< "$OUTPUT")"
        return
    fi

    PLAIN=${OUTPUT//\\//}
    PLAIN=${PLAIN//$'\r'/}

    while IFS= read -r LINE; do
        if ! [[ $LINE =~ $FINDING_LINE ]]; then
            continue
        fi

        TOTAL=$((TOTAL + 1))

        FILE=${BASH_REMATCH[1]#"$REPO_ROOT"/}
        LOCATION="$FILE:${BASH_REMATCH[2]}"
        NAME=${BASH_REMATCH[3]}
        MESSAGE=${BASH_REMATCH[4]}

        if ! grep -Fxq -- "$FILE" <<< "$STAGED_FILES"; then
            UNSTAGED=$((UNSTAGED + 1))
            continue
        fi

        if [[ $MESSAGE == *"$POINTER_FINDING"* ]]; then
            POINTERS=$((POINTERS + 1))
            continue
        fi

        WASTE=0
        if [[ $MESSAGE =~ $WASTE_PERCENT ]]; then
            WASTE=${BASH_REMATCH[1]}
        fi

        if (( WASTE == 0 || WASTE < PERCENT )); then
            BELOW=$((BELOW + 1))
            continue
        fi

        STRUCTS=$((STRUCTS + 1))
        REPORT+="$LOCATION: $NAME has $MESSAGE"$'\n'
    done <<< "$PLAIN"

    echo -e "\n${INDENT}${BOLD}Findings: ${YELLOW}${TOTAL}${RESET}"

    if (( STRUCTS > 0 )); then
        record_result "$MODULE" failed "$STRUCTS" "$BELOW" "$POINTERS" "$UNSTAGED" "$REPORT" ""
    else
        record_result "$MODULE" passed 0 "$BELOW" "$POINTERS" "$UNSTAGED" "" ""
    fi
}

print_summary() {
    local FAILED=0
    local POINTERS_TOTAL=0
    local UNSTAGED_TOTAL=0

    local I
    local TEXT
    local COLOR

    local MODULE_WIDTH
    local STRUCTS_WIDTH
    local BELOW_WIDTH
    local POINTERS_WIDTH
    local UNSTAGED_WIDTH

    local -a LABELS=()

    for I in "${!RESULT_MODULE[@]}"; do
        LABELS+=("$(module_label "${RESULT_MODULE[I]}")")

        if [[ "${RESULT_STATUS[I]}" != error ]]; then
            POINTERS_TOTAL=$((POINTERS_TOTAL + RESULT_POINTERS[I]))
            UNSTAGED_TOTAL=$((UNSTAGED_TOTAL + RESULT_UNSTAGED[I]))
        fi
    done

    MODULE_WIDTH=$(longest_length 6 "${LABELS[@]}")
    STRUCTS_WIDTH=$(longest_length 7 "${RESULT_STRUCTS[@]}")
    BELOW_WIDTH=$(longest_length 5 "${RESULT_BELOW[@]}")
    POINTERS_WIDTH=$(longest_length 8 "${RESULT_POINTERS[@]}")
    UNSTAGED_WIDTH=$(longest_length 8 "${RESULT_UNSTAGED[@]}")

    echo -e "\n${BOLD}Summary:${RESET}\n"

    printf "  %-${MODULE_WIDTH}s  %${STRUCTS_WIDTH}s  %${BELOW_WIDTH}s  %${POINTERS_WIDTH}s  %${UNSTAGED_WIDTH}s  %s\n" \
        Module Structs Below Pointers Unstaged Result

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            passed) COLOR=$GREEN; TEXT="✓ passed" ;;
            failed) COLOR=$RED;   TEXT="✗ structs over ${PERCENT}%" ;;
            error)  COLOR=$RED;   TEXT="✗ fieldalignment failed" ;;
        esac

        if [[ "${RESULT_STATUS[I]}" != passed ]]; then
            FAILED=$((FAILED + 1))
        fi

        printf "  %-${MODULE_WIDTH}s  %${STRUCTS_WIDTH}s  %${BELOW_WIDTH}s  %${POINTERS_WIDTH}s  %${UNSTAGED_WIDTH}s  ${COLOR}%s${RESET}\n" \
            "${LABELS[I]}" "${RESULT_STRUCTS[I]}" "${RESULT_BELOW[I]}" "${RESULT_POINTERS[I]}" "${RESULT_UNSTAGED[I]}" "$TEXT"
    done

    LINE_JUMP="\n"
    if (( POINTERS_TOTAL > 0 )); then
        LINE_JUMP=""
        echo -e "\n  ${YELLOW}${POINTERS_TOTAL} struct(s) could reduce their pointer data; this does not fail the check.${RESET}"
    fi

    if (( UNSTAGED_TOTAL > 0 )); then
        echo -e "${LINE_JUMP}  ${YELLOW}${UNSTAGED_TOTAL} finding(s) in files that are not staged were not checked.${RESET}"
    fi

    if (( FAILED == 0 )); then
        echo -e "\n${GREEN}All ${#LABELS[@]} module(s) passed the alignment check. Ready to commit.${RESET}"
        return 0
    fi

    echo -e "\n${RED}${BOLD}Failures:${RESET}"

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            failed)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - ${RESULT_STRUCTS[I]} struct(s) waste ${PERCENT}% or more:\n"
                indent "    " "${RESULT_REPORT[I]}"
                ;;
            error)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - fieldalignment failed:\n"
                indent "    " "${RESULT_DETAIL[I]}"
                ;;
        esac
    done

    echo -e "\n${RED}${FAILED} of ${#LABELS[@]} module(s) failed. Please fix them before committing.${RESET}"

    return 1
}

TOTAL_MODULES=${#MODULE_LIST[@]}
MODULE_INDEX=0

for MODULE in "${MODULE_LIST[@]}"; do
    MODULE_INDEX=$((MODULE_INDEX + 1))
    scan_module "$MODULE" "${MODULE_INDEX}/${TOTAL_MODULES}"
done

print_summary

exit $?
