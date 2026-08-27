#!/usr/bin/env bash

_VERSION="1.0.1"

# Color codes
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

set -euo pipefail

TARGET_DIR=".local/bin/bash-hooks"
SOURCE_SCRIPT="bash-hooks"

INSTALL_DIR="$HOME/$TARGET_DIR"
BASHRC="$HOME/.bashrc"
INSTALLER_NAME="$(basename "$0")"

DESTINATION="$INSTALL_DIR/$SOURCE_SCRIPT"
PATH_LINE="export PATH=\"\$HOME/$TARGET_DIR:\$PATH\""

print_help() {
    echo -e "\nUsage:"
    echo -e "  $INSTALLER_NAME [flags]"
    echo -e "\nFlags:"
    echo -e "  -h --help                   $YELLOW Help command. $RESET"
    echo -e "  -v --version                $YELLOW Shows actual installer version. $RESET"
    echo -e "  -i --install                $YELLOW Installs the script in the defined workspace. $RESET"
    echo -e "  -r --remote[=tag]           $YELLOW Downloads the script from GitHub and installs it in the defined workspace. $RESET"
    echo -e "                              $YELLOW If a version is not specified, it will be downloaded from the main branch. $RESET"
    echo -e "  -u --uninstall              $YELLOW Uninstalls the script from the defined workspace. $RESET"
    echo ""
}

validate_source() {
    local SCRIPT="$1"

    if [[ ! -f "$SCRIPT" ]]; then
        echo -e "\n${RED}Error: the file '$SCRIPT' does not exist.${RESET}" >&2
        exit 1
    fi

    if [[ ! -r "$SCRIPT" ]]; then
        echo -e "\n${RED}Error: cannot read '$SCRIPT'.${RESET}" >&2
        exit 1
    fi
}

get_installed_version() {
    local INSTALLED_VERSION

    INSTALLED_VERSION=$(grep '^_VERSION=' "$DESTINATION" | cut -d'=' -f2- | tr -d '"' || true)

    if [[ -z "$INSTALLED_VERSION" ]]; then
        echo "unknown"
    else
        echo "$INSTALLED_VERSION"
    fi
}

download() {
    local VERSION="$1"
    local SCRIPT="$2"

    local REFERENCE="heads/main"
    local FILE_URL

    if [[ -n "$VERSION" ]]; then
        REFERENCE="tags/${VERSION}"
    fi

    FILE_URL="https://raw.githubusercontent.com/Rafael24595/bash-hooks/refs/${REFERENCE}/${SOURCE_SCRIPT}"

    echo -e "\n${BOLD}Downloading $SOURCE_SCRIPT${RESET}"
    echo
    echo -e "  Download:     $SOURCE_SCRIPT"
    echo -e "  Destination:  ${YELLOW}$SCRIPT${RESET}"
    echo -e "  URL:          ${YELLOW}$FILE_URL${RESET}\n"

    if ! curl -fsS "$FILE_URL" -o "$SCRIPT"; then
        echo -e "\n${RED}Error: failed to download $SOURCE_SCRIPT from GitHub.${RESET}" >&2
        exit 1
    fi

    chmod +x "$SCRIPT"

    echo -e "  ${GREEN}✓ Script downloaded.${RESET}"
}

install() {
    local SOURCE="$1"
    
    validate_source "$SOURCE"

    echo -e "\n${BOLD}Installing $SOURCE_SCRIPT${RESET}"
    echo
    echo -e "  Source:       $SOURCE_SCRIPT"
    echo -e "  Destination:  ${YELLOW}~/$TARGET_DIR${RESET}\n"

    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        echo -e "  ${GREEN}✓ Installation directory created.${RESET}"
    fi

    if [[ -f "$DESTINATION" ]]; then
        OLD_VERSION="$(get_installed_version)"

        read -r -p "$(echo -e " Another version of the script (${YELLOW}$OLD_VERSION${RESET}) is already installed. Do you want to overwrite it? (y/n): ")" RESPONSE
        RESPONSE=$(echo "$RESPONSE" | tr '[:upper:]' '[:lower:]')

        echo

        case "$RESPONSE" in
            yes | y)
                cp "$SOURCE" "$DESTINATION"
                echo -e "  ${GREEN}✓ Script updated successfully.${RESET}"
                ;;
            no | n)
                echo -e "\nThe updating process has been canceled.\n\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid response. Please answer y/yes or n/no.${RESET}"
                exit 1
                ;;
        esac
    elif [[ -e "$DESTINATION" ]]; then
        echo -e "\n${RED}Error: '$DESTINATION' exists and is not a regular file.${RESET}" >&2
        exit 1
    else
        cp "$SOURCE" "$DESTINATION"
        echo -e "  ${GREEN}✓ Script installed successfully.${RESET}"
    fi

    chmod +x "$DESTINATION"

    if [[ ! -f "$BASHRC" ]]; then
        touch "$BASHRC"
        echo -e "  ${GREEN}✓ Bash configuration created.${RESET}"
    fi

    if ! grep -Fqx "$PATH_LINE" "$BASHRC"; then
        if [[ -n "$(tail -n 1 "$BASHRC")" ]]; then
            echo >> "$BASHRC"
        fi

        {
            echo "# Added by $INSTALLER_NAME on $(date)"
            echo "$PATH_LINE"
        } >> "$BASHRC"

        echo -e "  ${GREEN}✓ Bash PATH configured.${RESET}"
    else
        echo -e "  ${YELLOW}• ~/$TARGET_DIR is already configured in $BASHRC.${RESET}"
    fi

    echo -e "\n${BOLD}==========================================${RESET}"
    echo -e "${BOLD} Installation completed successfully${RESET}"
    echo -e "${BOLD}==========================================${RESET}\n"
    
    echo "Script installed in:"
    echo -e "  ${YELLOW}$DESTINATION${RESET}"
    echo
    echo "You can run it as:"
    echo -e "  ${YELLOW}$SOURCE_SCRIPT${RESET}"
    echo
    echo "To apply the change in the current terminal:"
    echo
    echo "  source ~/.bashrc"
    echo
    echo "Or simply open a new terminal."
    echo
}

remote_install() {
    local VERSION="${1:-}"
    local SCRIPT

    SCRIPT="$(mktemp "${TMPDIR:-/tmp}/bash-hooks.XXXXXX")"

    # shellcheck disable=SC2064
    trap "rm -f '$SCRIPT'" EXIT

    download "$VERSION" "$SCRIPT"
    install "$SCRIPT"
}

uninstall() {
    local SCRIPT_REMOVED=false
    local PATH_REMOVED=false

    echo -e "\n${BOLD}Uninstalling $SOURCE_SCRIPT${RESET}"
    echo
    echo -e "  Installation: ${YELLOW}~/$TARGET_DIR/$SOURCE_SCRIPT${RESET}"
    echo -e "  Configuration: ${YELLOW}$BASHRC${RESET}\n"

    if [[ -f "$DESTINATION" ]]; then
        rm "$DESTINATION"
        echo -e "  ${GREEN}✓ Script removed.${RESET}"

        if rmdir "$INSTALL_DIR" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Installation directory removed.${RESET}"
        fi

        SCRIPT_REMOVED=true
    elif [[ -e "$DESTINATION" ]]; then
        echo -e "\n${RED}Error: '$DESTINATION' exists and is not a regular file.${RESET}" >&2
        exit 1
    else
       echo -e "  ${YELLOW}• Script is not installed.${RESET}"
    fi

    if [[ -f "$BASHRC" ]]; then
        if grep -Fqx "$PATH_LINE" "$BASHRC" && grep -Fq "# Added by $INSTALLER_NAME on " "$BASHRC"; then
            sed -i -E -e '$!N; s/^[[:space:]]*\n(# Added by '"$INSTALLER_NAME"' on .*)/\1/; P; D' "$BASHRC"
            sed -i "\|^# Added by $INSTALLER_NAME on .*|d" "$BASHRC"
            sed -i "\|^${PATH_LINE}$|d" "$BASHRC"

            echo -e "  ${GREEN}✓ Bash PATH entry removed.${RESET}"

            PATH_REMOVED=true
        else
            echo -e "  ${YELLOW}• ~/$TARGET_DIR is not configured in $BASHRC.${RESET}"
        fi
    fi

    echo -e "\n${BOLD}==========================================${RESET}"
    echo -e "${BOLD} Uninstallation completed successfully${RESET}"
    echo -e "${BOLD}==========================================${RESET}\n"

    if [[ "$SCRIPT_REMOVED" == true ]]; then
        echo "Removed:"
        echo -e "  ${YELLOW}$DESTINATION${RESET}"
    else
        echo -e "Script was not found: ${YELLOW}$DESTINATION${RESET}"
    fi

    echo

    if [[ "$PATH_REMOVED" == true ]]; then
        echo -e "The ${YELLOW}~/$TARGET_DIR${RESET} entry was removed from $BASHRC."
    else
        echo -e "The ${YELLOW}~/$TARGET_DIR${RESET} entry in $BASHRC was left unchanged."
    fi

    echo
    echo "If necessary, reload your Bash configuration with:"
    echo
    echo "  source ~/.bashrc"
    echo
}

case "${1:-}" in
    --install | -i | "")
        install "$SOURCE_SCRIPT"
        ;;
    --remote | -r)
        remote_install
        ;;
    --remote=* | -r=*)
        remote_install "${1#*=}"
        ;;
    --uninstall | -u)
        uninstall
        ;;
    --version | -v)
        echo "$_VERSION"
        ;;
    --help | -h)
        print_help
        ;;
    *)
        echo -e "\n${RED}Error: unknown option '$1'.${RESET}" >&2
        exit 1
        ;;
esac
