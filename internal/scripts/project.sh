#!/bin/bash

# Import color codes from colors.sh
# shellcheck disable=SC1091
source ./scripts/colors.sh

# Prints the project version from the staged copy of a TOML file (not the
# one on disk), so it matches what is being committed.
#
# Arguments: $1 - path of the TOML file, relative to the repository root.
# Outputs:   the version on stdout; errors on stderr.
# Returns:   1 if the version is missing or is not MAJOR.MINOR.PATCH.
read_staged_project_version() {
    local PROJECT_FILE="$1"
    local PROJECT_VERSION

    PROJECT_VERSION=$(git cat-file blob ":$PROJECT_FILE" |
        grep -A 5 '^\[project\]' |
        grep '^version' |
        head -n 1 |
        cut -d'"' -f2)

    if [ -z "$PROJECT_VERSION" ]; then
        echo -e "${RED}\nError: The project version was not found in $PROJECT_FILE.${RESET}" >&2
        return 1
    fi

    if [[ ! "$PROJECT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}\nError: invalid project version '$PROJECT_VERSION' in $PROJECT_FILE.${RESET}" >&2
        return 1
    fi

    printf '%s\n' "$PROJECT_VERSION"
}

# Applies a sed expression to a file both on disk and in the index, without
# staging any other pending change in that file. The staged copy is edited
# separately and written back as a new blob with the same mode, instead of
# running `git add`, which would stage the whole file.
#
# Arguments: $1 - sed expression; $2 - path of the file.
sed_stage() {
    local SED_EXPR="$1"
    local TARGET="$2"

    local MODE
    local BLOB

    sed -i "$SED_EXPR" "$TARGET"

    if ! git ls-files --error-unmatch -- "$TARGET" > /dev/null 2>&1; then
        git add "$TARGET"
        return 0
    fi

    MODE=$(git ls-files -s -- "$TARGET" |
        cut -d' ' -f1)

    BLOB=$(git cat-file blob ":$TARGET" |
        sed "$SED_EXPR" |
        git hash-object -w --stdin --path="$TARGET")

    git update-index --cacheinfo "$MODE,$BLOB,$TARGET"
}