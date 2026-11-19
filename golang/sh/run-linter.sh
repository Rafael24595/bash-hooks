#!/bin/bash

_VERSION="1.4.0"
_PACKAGE="run-linter"
_DETAILS="Runs golangci-lint to find errors in staged Go files."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from string.sh
# shellcheck disable=SC1091
source ./tools/sh/string.sh
# Import utility functions from utils-golang.sh
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

# an issue line of golangci-lint: "path/file.go:line:column: message (linter)"
ISSUE_LINE='^[^[:space:]]+\.go:[0-9]+:'
# a prefix to format the modules output
INDENT=" "

INSTALL=false
STRICT=false
ENABLE=()

DISCOVER=false
DECLARED=()

for FLAG in "$@"; do
    case "$FLAG" in
        --install | --i)
            INSTALL=true
            ;;
        --strict | --s)
            STRICT=true
            ;;
        --enable=* | --e=*)
            ENABLE+=("${FLAG#*=}")
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

if ! command -v golangci-lint &> /dev/null; then
    if $INSTALL; then
        echo -e "${GREEN}Installing golangci-lint...${RESET}"

        ensure_go_installed

        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest || exit 1
        if ! command -v golangci-lint &> /dev/null; then
            echo -e "${RED}\ngolangci-lint was installed but is not in PATH (add \$(go env GOPATH)/bin).${RESET}"
            exit 1
        fi

        echo -e "${GREEN}golangci-lint installed.${RESET}"
    else
        echo -e "${RED}\ngolangci-lint could not be found. Please install it to proceed.${RESET}"
        exit 1
    fi
fi

echo -e "${BOLD}\nRunning golangci-lint...\n${RESET}"

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

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
if $DISCOVER; then
    echo -e "  ${GREEN}✓ Discovered modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
else
    echo -e "  ${GREEN}✓ Modules (${#MODULE_LIST[@]}): ${YELLOW}${JOINED_MODULES}${RESET}"
fi

if $STRICT; then
    echo -e "  ${GREEN}✓ Strict mode: ${YELLOW}enabled${RESET}"
fi

ARGS=(--color always)

if (( ${#ENABLE[@]} > 0 )); then
    JOINED_LINTERS=$(join_by "," "${ENABLE[@]}")
    ARGS=(--enable "$JOINED_LINTERS" "${ARGS[@]}")

    JOINED_LINTERS=$(join_by ", " "${ENABLE[@]}")
    echo -e "  ${GREEN}✓ Enabled linters: ${YELLOW}${JOINED_LINTERS}${RESET}"
fi

RESULT_MODULE=()
RESULT_STATUS=()
RESULT_ISSUES=()
RESULT_UNSTAGED=()
RESULT_FILES=()
RESULT_DETAIL=()

record_result() {
    RESULT_MODULE+=("$1")
    RESULT_STATUS+=("$2")
    RESULT_ISSUES+=("$3")
    RESULT_UNSTAGED+=("$4")
    RESULT_FILES+=("$5")
    RESULT_REPORT+=("$6")
    RESULT_DETAIL+=("$7")
}

lint_module() {
    local MODULE=$1
    local POSITION=$2

    local OUTPUT
    local PLAIN
    local EXIT_CODE

    local LINE
    local FILE

    local TOTAL=0
    local ISSUES=0
    local FILES=""
    local REPORT=""

    local COUNTS=false

    echo -e "\n${BOLD}Module ${POSITION} - Linting${RESET}\n"
    echo -e "${INDENT}- Module: ${YELLOW}$(module_label "$MODULE")${RESET}\n"

    OUTPUT=$(cd "$MODULE" && golangci-lint run --path-prefix "$MODULE" "${ARGS[@]}" 2>&1)
    EXIT_CODE=$?

    indent "$INDENT" "$OUTPUT"

    PLAIN=$(sed -E -e 's/\x1B\[[0-9;]*[mK]//g' -e 's/\\/\//g' <<< "$OUTPUT" | tr -d '\r')

    if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 1 ]; then
        record_result "$MODULE" error 0 0 "" "" "$(tail -n 15 <<< "$PLAIN")"
        return
    fi

    while IFS= read -r LINE; do
        if [[ $LINE =~ $ISSUE_LINE ]]; then
            TOTAL=$((TOTAL + 1))
            FILE=${LINE%%:*}

            if $STRICT || grep -Fxq -- "$FILE" <<< "$STAGED_FILES"; then
                COUNTS=true
                ISSUES=$((ISSUES + 1))
                FILES+="$FILE"$'\n'
            else
                COUNTS=false
            fi
        elif [[ $LINE =~ $CLOSING_LINE ]]; then
            COUNTS=false
        fi

        if $COUNTS; then
            REPORT+="$LINE"$'\n'
        fi
    done <<< "$PLAIN"

    FILES=$(sort -u <<< "$FILES" | grep .)

    echo -e "\n${INDENT}${BOLD}Issues: ${YELLOW}${TOTAL}${RESET}"

    if (( ISSUES > 0 )); then
        record_result "$MODULE" failed "$ISSUES" "$((TOTAL - ISSUES))" "$FILES" "$REPORT" ""
    else
        record_result "$MODULE" passed 0 "$TOTAL" "" "" ""
    fi
}

print_summary() {
    local FAILED=0
    local UNSTAGED_TOTAL=0

    local I
    local TEXT
    local COLOR
    local UNSTAGED

    local MODULE_WIDTH
    local ISSUES_WIDTH
    local FILES_WIDTH
    local UNSTAGED_WIDTH

    local -a LABELS=()
    local -a FILE_COUNTS=()

    for I in "${!RESULT_MODULE[@]}"; do
        LABELS+=("$(module_label "${RESULT_MODULE[I]}")")
        FILE_COUNTS+=("$(grep -c . <<< "${RESULT_FILES[I]}")")
        UNSTAGED_TOTAL=$((UNSTAGED_TOTAL + RESULT_UNSTAGED[I]))
    done

    MODULE_WIDTH=$(longest_length 6 "${LABELS[@]}")
    ISSUES_WIDTH=$(longest_length 6 "${RESULT_ISSUES[@]}")
    FILES_WIDTH=$(longest_length 5 "${FILE_COUNTS[@]}")
    UNSTAGED_WIDTH=$(longest_length 8 "${RESULT_UNSTAGED[@]}")

    echo -e "\n${BOLD}Summary:${RESET}\n"

    printf "  %-${MODULE_WIDTH}s  %${ISSUES_WIDTH}s  %${FILES_WIDTH}s  %${UNSTAGED_WIDTH}s  %s\n" \
        Module Issues Files Unstaged Result

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            passed) COLOR=$GREEN; TEXT="✓ passed" ;;
            failed) COLOR=$RED;   TEXT="✗ files with issues" ;;
            error)  COLOR=$RED;   TEXT="✗ golangci-lint failed" ;;
        esac

        if [ "${RESULT_STATUS[I]}" != passed ]; then
            FAILED=$((FAILED + 1))
        fi

        UNSTAGED=${RESULT_UNSTAGED[I]}
        if $STRICT; then
            UNSTAGED="-"
        fi

        printf "  %-${MODULE_WIDTH}s  %${ISSUES_WIDTH}s  %${FILES_WIDTH}s  %${UNSTAGED_WIDTH}s  ${COLOR}%s${RESET}\n" \
            "${LABELS[I]}" "${RESULT_ISSUES[I]}" "${FILE_COUNTS[I]}" "$UNSTAGED" "$TEXT"
    done

    if ! $STRICT && (( UNSTAGED_TOTAL > 0 )); then
        echo -e "\n  ${YELLOW}${UNSTAGED_TOTAL} issue(s) in files that are not staged were not checked; --strict includes them.${RESET}"
    fi

    if (( FAILED == 0 )); then
        echo -e "\n${GREEN}All ${#LABELS[@]} module(s) passed the linter. Ready to commit.${RESET}"
        return 0
    fi

    echo -e "\n${RED}${BOLD}Failures:${RESET}"

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            failed)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - ${FILE_COUNTS[I]} file(s) with issues:\n"
                indent "    " "${RESULT_REPORT[I]}"
                ;;
            error)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - golangci-lint failed:\n"
                indent "    " "${RESULT_DETAIL[I]}"
                ;;
        esac
    done

    echo -e "${RED}${FAILED} of ${#LABELS[@]} module(s) failed. Please fix them before committing.${RESET}"

    return 1
}

TOTAL_MODULES=${#MODULE_LIST[@]}
MODULE_INDEX=0

for MODULE in "${MODULE_LIST[@]}"; do
    MODULE_INDEX=$((MODULE_INDEX + 1))
    lint_module "$MODULE" "${MODULE_INDEX}/${TOTAL_MODULES}"
done

print_summary

exit $?
