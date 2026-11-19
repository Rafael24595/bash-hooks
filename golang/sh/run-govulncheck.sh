#!/bin/bash

_VERSION="1.2.0"
_PACKAGE="run-govulncheck"
_DETAILS="Executes govulncheck to check for vulnerabilities in dependencies."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh
# Import utility functions from string.sh
# shellcheck disable=SC1091
source ./tools/sh/string.sh
# Import utility functions from utils-golang.sh
# shellcheck disable=SC1091
source ./golang/sh/utils-golang.sh

# govulncheck's closing sentence, with or without findings
SUMMARY_LINE='^(Your code is affected by|No vulnerabilities found)'
# the heading of each vulnerability: "Vulnerability #1: GO-2024-0001"
VULNERABILITY_LINE='^Vulnerability #[0-9]+:'
# the start of a section of the verbose output: "=== Symbol Results ==="
SECTION_LINE='^=== ([A-Za-z]+) Results ==='
# where the call traces of a vulnerability start: not copied to the report
TRACES_LINE='^[[:space:]]*Example traces found'
# a prefix to format the modules output
INDENT=" "

INSTALL=false

DISCOVER=false
DECLARED=()

for FLAG in "$@"; do
    case "$FLAG" in
        --install | --i)
            INSTALL=true
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

if ! command -v govulncheck &> /dev/null; then
    if $INSTALL; then
        echo -e "${GREEN}Installing govulncheck...${RESET}"

        ensure_go_installed

        go install golang.org/x/vuln/cmd/govulncheck@latest || exit 1
        if ! command -v govulncheck &> /dev/null; then
            echo -e "${RED}\ngovulncheck was installed but is not in PATH (add \$(go env GOPATH)/bin).${RESET}"
            exit 1
        fi

        echo -e "${GREEN}govulncheck installed.${RESET}"
    else
        echo -e "${RED}\ngovulncheck could not be found. Please install it to proceed.${RESET}"
        exit 1
    fi
fi

echo -e "${BOLD}\nRunning govulncheck...\n${RESET}"

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

RESULT_MODULE=()
RESULT_STATUS=()
RESULT_CALLED=()
RESULT_IMPORTED=()
RESULT_REQUIRED=()
RESULT_REPORT=()
RESULT_DETAIL=()

record_result() {
    RESULT_MODULE+=("$1")
    RESULT_STATUS+=("$2")
    RESULT_CALLED+=("$3")
    RESULT_IMPORTED+=("$4")
    RESULT_REQUIRED+=("$5")
    RESULT_REPORT+=("$6")
    RESULT_DETAIL+=("$7")
}

scan_module() {
    local MODULE=$1
    local POSITION=$2

    local LINE
    local OUTPUT
    local EXIT_CODE

    local SECTION="Symbol"
    local IN_SECTION=false

    local CALLED=0
    local IMPORTED=0
    local REQUIRED=0

    local REPORT=""

    echo -e "\n${BOLD}Module ${POSITION} - Scanning${RESET}\n"
    echo -e "${INDENT}- Module: ${YELLOW}$(module_label "$MODULE")${RESET}\n"

    OUTPUT=$(cd "$MODULE" && govulncheck -show verbose ./... 2>&1)
    EXIT_CODE=$?

    indent "$INDENT" "$OUTPUT"

    if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 3 ]; then
        record_result "$MODULE" error - - - "" "$(tail -n 15 <<< "$OUTPUT")"
        return
    fi

    while IFS= read -r LINE; do
        if [[ $LINE =~ $SECTION_LINE ]]; then
            SECTION=${BASH_REMATCH[1]}
            IN_SECTION=false
            continue
        fi

        if [[ $LINE =~ $VULNERABILITY_LINE ]]; then
            case "$SECTION" in
                Symbol)
                    CALLED=$((CALLED + 1)); IN_SECTION=true
                    ;;
                Package)
                    IMPORTED=$((IMPORTED + 1)); IN_SECTION=false ; continue
                    ;;
                Module)
                    REQUIRED=$((REQUIRED + 1)); IN_SECTION=false ; continue
                    ;;
            esac
        fi

        if [[ $LINE =~ $TRACES_LINE ]] || [[ $LINE =~ $SUMMARY_LINE ]]; then
            IN_SECTION=false
            continue
        fi

        if $IN_SECTION; then
            REPORT+="$LINE"$'\n'
        fi
    done <<< "$OUTPUT"

    if [ "$EXIT_CODE" -eq 3 ]; then
        if [ -z "$REPORT" ]; then
            REPORT=$(tail -n 15 <<< "$OUTPUT")
        fi

        record_result "$MODULE" vulnerable "$CALLED" "$IMPORTED" "$REQUIRED" "$REPORT" ""
    else
        record_result "$MODULE" passed "$CALLED" "$IMPORTED" "$REQUIRED" "" ""
    fi
}

print_summary() {
    local FAILED=0

    local I
    local TEXT
    local COLOR

    local MODULE_WIDTH
    local CALLED_WIDTH
    local IMPORTED_WIDTH
    local REQUIRED_WIDTH

    local -a LABELS=()

    for I in "${!RESULT_MODULE[@]}"; do
        LABELS+=("$(module_label "${RESULT_MODULE[I]}")")
    done

    MODULE_WIDTH=$(longest_length 6 "${LABELS[@]}")
    CALLED_WIDTH=$(longest_length 6 "${RESULT_CALLED[@]}")
    IMPORTED_WIDTH=$(longest_length 8 "${RESULT_IMPORTED[@]}")
    REQUIRED_WIDTH=$(longest_length 8 "${RESULT_REQUIRED[@]}")

    echo -e "\n${BOLD}Summary:${RESET}\n"

    printf "  %-${MODULE_WIDTH}s  %${CALLED_WIDTH}s  %${IMPORTED_WIDTH}s  %${REQUIRED_WIDTH}s  %s\n" \
        Module Called Imported Required Result

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            passed)
                COLOR=$GREEN
                TEXT="✓ passed"
                ;;
            vulnerable)
                COLOR=$RED
                TEXT="✗ vulnerable"
                ;;
            error)
                COLOR=$RED
                TEXT="✗ govulncheck failed"
                ;;
        esac

        if [ "${RESULT_STATUS[I]}" != passed ]; then
            FAILED=$((FAILED + 1))
        fi

        printf "  %-${MODULE_WIDTH}s  %${CALLED_WIDTH}s  %${IMPORTED_WIDTH}s  %${REQUIRED_WIDTH}s  ${COLOR}%s${RESET}\n" \
            "${LABELS[I]}" "${RESULT_CALLED[I]}" "${RESULT_IMPORTED[I]}" "${RESULT_REQUIRED[I]}" "$TEXT"
    done

    if (( FAILED == 0 )); then
        echo -e "\n${GREEN}No vulnerabilities found in ${#LABELS[@]} module(s)! Ready to commit.${RESET}"
        return 0
    fi

    echo -e "\n${RED}${BOLD}Failures:${RESET}"

    for I in "${!LABELS[@]}"; do
        case "${RESULT_STATUS[I]}" in
            vulnerable)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - ${RESULT_CALLED[I]} vulnerability(ies) your code calls:\n"
                indent "    " "${RESULT_REPORT[I]}"
                ;;
            error)
                echo -e "\n  ${BOLD}${LABELS[I]}${RESET} - govulncheck failed:\n"
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
