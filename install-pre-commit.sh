#!/bin/bash

INPUT_FILE=".pre-commit-hooks.yaml"
OUTPUT_FILE=".git/hooks/pre-commit"

REMOTE_LOCATION="./.remote-scripts"

log_script_execution() {
    local SCRIPT=$1
    local ARGS=$2

    echo -e "\nprintf \"\${BOLD}\\\\nExecuting '${SCRIPT}' script...\${RESET}\\\\n\"" >> "$OUTPUT_FILE"
    echo "$SCRIPT $ARGS" >> "$OUTPUT_FILE"
    echo 'if [ $? -ne 0 ]; then' >> "$OUTPUT_FILE"
    echo '    exit 1' >> "$OUTPUT_FILE"
    echo 'fi' >> "$OUTPUT_FILE"
    echo "printf \"\${BOLD}\\\\n <-----------------> \\\\n\${RESET}\"" >> "$OUTPUT_FILE"
}

load_remote_scripts() {
    REPO_IDS=$(yq eval '.hooks.remote.repos[].id' ${INPUT_FILE})
    for REPO_ID in $REPO_IDS; do
        NAME=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .name" ${INPUT_FILE})
        ORIGIN=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .origin" ${INPUT_FILE})
        TAG=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .tag" ${INPUT_FILE})
        TARGET=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .target" ${INPUT_FILE})
        LANG=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .lang" ${INPUT_FILE})
        ARGS=$(yq e ".hooks.remote.repos[] | select(.id == \"${REPO_ID}\") | .args[]" ${INPUT_FILE} | tr '\n' ' ')
        FILE_URL=""

        if [[ "${LANG^^}" != BASH ]]; then
            echo "Only Bash scripts are supported so far."
            exit 1
        fi

        if [[ "$ORIGIN" == https://github.com* ]]; then
            PROJECT="${ORIGIN#https://github.com/}"
            FILE_URL="https://raw.githubusercontent.com/${PROJECT}/refs/tags/${TAG}/${TARGET}/${NAME}"
        else
            echo "Currently, only GitHub repositories are supported."
            exit 1
        fi

        CONTENT=$(curl -s "$FILE_URL")
        if [ $? -ne 0 ]; then
            echo "Failed to retrieve file from GitHub."
            exit 1
        fi

        SCRIPT="${REMOTE_LOCATION}/${NAME}"

        mkdir -p "${REMOTE_LOCATION}"
        touch $SCRIPT

        > $SCRIPT
        echo "$CONTENT" >> "${SCRIPT}"
        chmod +x $SCRIPT

        log_script_execution "$SCRIPT" "$ARGS"
    done
}

load_local_scripts() {
    SOURCES=$(yq eval '.hooks.local.sources[].path' ${INPUT_FILE})
    for SOURCE in $SOURCES; do
        echo "\n# Import ${SOURCE}" >> "$OUTPUT_FILE"
        echo "source ${SOURCE}" >> "$OUTPUT_FILE"
    done

    SCRIPT_IDS=$(yq eval '.hooks.local.scripts[].id' ${INPUT_FILE})
    for SCRIPT_ID in $SCRIPT_IDS; do

        SCRIPT=$(yq e ".hooks.local.scripts[] | select(.id == \"${SCRIPT_ID}\") | .path" ${INPUT_FILE})
        ARGS=$(yq e ".hooks.local.scripts[] | select(.id == \"${SCRIPT_ID}\") | .args[]" ${INPUT_FILE} | tr '\n' ' ')

        log_script_execution "$SCRIPT" "$ARGS"
    done
}

> $OUTPUT_FILE

echo "#!/bin/sh" >> "$OUTPUT_FILE"

echo -e "\n# Color codes" >> "$OUTPUT_FILE"
echo "BOLD=\"\\\033[1m\"" >> "$OUTPUT_FILE"
echo "RESET=\"\\\033[0m\"" >> "$OUTPUT_FILE"


# --------------------#
# LOAD REMOTE SCRIPTS #
# ------------------- #

echo -e "\n# <-- REPOSITORY SCRIPTS -->" >> "$OUTPUT_FILE"
echo -e "\nprintf \"\${BOLD}\\\\nRepository scripts: \\\\n\${RESET}\"" >> "$OUTPUT_FILE"

load_remote_scripts

# -------------------#
# LOAD LOCAL SCRIPTS #
# ------------------ #

echo -e "\n# <-- LOCAL SCRIPTS -->" >> "$OUTPUT_FILE"
echo -e "\nprintf \"\${BOLD}\\\\nLocal scripts: \\\\n\${RESET}\"" >> "$OUTPUT_FILE"

load_local_scripts
