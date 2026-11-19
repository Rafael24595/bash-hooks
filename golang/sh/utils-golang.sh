#!/bin/bash

_VERSION="1.2.0"
_PACKAGE="utils-golang"
_DETAILS="Contains some utils to manage Go contexts."

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Check if Go is installed
ensure_go_installed() {
    if ! command -v go &> /dev/null; then
        echo -e "${RED}\nGo is not installed or not found in your system's PATH. Please install Go to proceed.${RESET}"
        exit 1
    fi
}

# Check if inside a Go project
ensure_go_project() {
    local MODULES
    local MODULE

    MODULES="$1"
    if [ "$MODULES" == "" ]; then
        MODULES="."
    fi

    while IFS= read -r MODULE; do
        if [ ! -f "${MODULE}/go.mod" ]; then
            echo -e "${YELLOW}\nNot a Go project: go.mod not found in ${MODULE}.${RESET}"
            exit 1
        fi
    done <<< "$MODULES"
}

# Check if there are any Go files staged
ensure_go_staged() {
    local MODULES
    local FILTERED

    MODULES="$1"
    if [ "$MODULES" == "" ]; then
        MODULES="."
    fi

    FILTERED=$(staged_go_modules "$MODULES")

    if [ -z "$FILTERED" ]; then
        echo -e "${YELLOW}\nNo Go files are staged in any of the specified modules.${RESET}"
        exit 1
    fi
}

# discover_go_modules prints the directory of every tracked or staged go.mod ("." for the root),
# skipping what `go ./...` skips: testdata, vendor and _ or . directories.
discover_go_modules() {
    local FILE
    local DIR

    while IFS= read -r -d '' FILE; do
        DIR=$(dirname "$FILE")
        if [ "$DIR" != "." ]; then
            case "/$DIR/" in */testdata/*|*/vendor/*|*/_*|*/.*) continue ;; esac
        fi
        printf '%s\n' "$DIR"
    done < <(git ls-files -z -- ':(glob)**/go.mod')
}

# discover_staged_go_modules prints, once each, the modules that the staged changes touch.
discover_staged_go_modules() {
     staged_go_modules "$(discover_go_modules)"
}

# staged_go_modules prints, once each, which of the given modules (one per line; "." is the
# root) the staged changes touch. Each file belongs to its nearest module.
staged_go_modules() {
    local MODULES
    local FILE
    local MODULE

    # one form per module: "./tools/a/" -> "tools/a"; "", "." and "./" -> "." (the root)
    MODULES=$(printf '%s\n' "$1" | sed -e 's|^\./||' -e 's|/*$||' -e 's|^$|.|')

    # nearest first: the first module that holds a file is the one it belongs to
    MODULES=$(printf '%s\n' "$MODULES" |
        awk '{ print ($0 == "." ? 0 : length($0)) "\t" $0 }' |
        sort -rn |
        cut -f2- |
        uniq)

    while IFS= read -r -d '' FILE; do
        while IFS= read -r MODULE; do
            if [ "$MODULE" = "." ] || [[ "$FILE" == "$MODULE/"* ]]; then
                printf '%s\n' "$MODULE"
                break
            fi
        done <<< "$MODULES"
    done < <(git diff --cached --name-only -z --diff-filter=ACMRD -- '*.go' '*go.mod' '*go.sum') | sort -u
}

# resolve_go_modules prints the Go modules to work on, one per line, relative to the
# repository root: the discovered ones when the first argument is "true"; otherwise the
# declared ones (the other arguments), or the root when none is declared.
# Returns 2 for a wrong use (--discover with --module, an invalid path) and 1 when discovery
# finds no module. Messages go to stderr: the output is meant to be captured.
resolve_go_modules() {
    local DISCOVER=$1
    local DECLARED=("${@:2}")

    local MODULE
    local MODULES

    if [ "$DISCOVER" = true ]; then
        if (( ${#DECLARED[@]} > 0 )); then
            echo -e "${RED}\nError: --discover cannot be used with --module${RESET}" >&2
            return 2
        fi

        MODULES=$(discover_go_modules)
        if [ -z "$MODULES" ]; then
            echo -e "${YELLOW}\nNo Go modules found.${RESET}" >&2
            return 1
        fi

        printf '%s\n' "$MODULES"
        return 0
    fi

    if (( ${#DECLARED[@]} == 0 )); then
        printf '.\n'
        return 0
    fi

    for MODULE in "${DECLARED[@]}"; do
        case "$MODULE" in
            "" | /* | [A-Za-z]:* | *\\* | .. | ../* | */.. | */../*)
                printf "${RED}\nError: invalid module path '%s': use a path inside the repository, with '/'${RESET}\n" "$MODULE" >&2
                return 2
                ;;
        esac
    done

    printf '%s\n' "${DECLARED[@]}" | sed -e 's|^\./||' -e 's|/*$||' -e 's|^$|.|' | awk '!seen[$0]++'
}

# module_label prints how a module is shown to people: "(root)" for the repository root,
# its path otherwise.
module_label() {
    if [ "$1" = "." ]; then
        printf '(root)\n'
    else
        printf '%s\n' "$1"
    fi
}
