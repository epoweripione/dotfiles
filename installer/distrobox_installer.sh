#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options

# https://www.tecmint.com/distrobox-run-any-linux-distribution/
# Distrobox: Use any linux distribution inside your terminal
# https://github.com/89luca89/distrobox
APP_INSTALL_NAME="distrobox"
GITHUB_REPO_NAME="89luca89/distrobox"

EXEC_INSTALL_NAME="distrobox"

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    VERSION_FILENAME="$(which ${EXEC_INSTALL_NAME}).version"
    [[ -s "${VERSION_FILENAME}" ]] && CURRENT_VERSION=$(head -n1 "${VERSION_FILENAME}")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${APP_INSTALL_NAME}${BLUE}..."

    CHECK_URL="https://api.github.com/repos/${GITHUB_REPO_NAME}/releases/latest"
    REMOTE_VERSION=$(curl "${CURL_CHECK_OPTS[@]}" "${CHECK_URL}" | jq -r '.tag_name//empty' 2>/dev/null | cut -d'v' -f2)
    if version_le "${REMOTE_VERSION}" "${CURRENT_VERSION}"; then
        IS_INSTALL="no"
    fi
fi

# Install Latest Version
if [[ "${IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${APP_INSTALL_NAME} ${YELLOW}${REMOTE_VERSION}${BLUE}..."
    # curl -s  | sudo sh
    curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${WORKDIR}/get-distrobox.sh" "https://raw.githubusercontent.com/89luca89/distrobox/main/install" && \
        sudo bash "${WORKDIR}/get-distrobox.sh"

    if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
        VERSION_FILENAME="$(which ${EXEC_INSTALL_NAME}).version"
        echo "${REMOTE_VERSION}" | sudo tee "${VERSION_FILENAME}" >/dev/null || true
    fi
fi


cd "${CURRENT_DIR}" || exit