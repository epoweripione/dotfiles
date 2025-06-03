#!/usr/local/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
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

App_Installer_Reset

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# pacapt - An Arch's pacman-like package manager for some Unices
# https://github.com/icy/pacapt
INSTALLER_APP_NAME="pacapt"
INSTALLER_GITHUB_REPO="icy/pacapt"

INSTALLER_INSTALL_NAME="pacapt"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    ECHO_TYPE="Updating"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
    ECHO_TYPE="Installing"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    # termux: PREFIX="/data/data/com.termux/files/usr"
    if [[ -z "${PREFIX}" ]]; then
        PREFIX="/usr/local"
        INSTALL_PACMAN_TO="/usr/bin"
    else
        INSTALL_PACMAN_TO="${PREFIX}/bin"
    fi

    [[ "$(readlink -f /usr/bin/pacman)" == "/usr/bin/pacapt" ]] && \
        sudo rm -f "/usr/bin/pacman" && sudo rm -f "/usr/bin/pacapt"

    colorEcho "${BLUE}  ${ECHO_TYPE} ${FUCHSIA}pacapt ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."

    INSTALLER_FILE_NAME="pacapt"

    INSTALLER_DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL:-https://github.com}/icy/pacapt/raw/ng/pacapt"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"
    if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}"; then
        sudo mv -f "${INSTALLER_DOWNLOAD_FILE}" "${PREFIX}/bin/pacapt" && \
            sudo chmod 755 "${PREFIX}/bin/pacapt" && \
            sudo ln -sv "${PREFIX}/bin/pacapt" "${INSTALL_PACMAN_TO}/pacman" || true

        # Save downloaded file to cache
        App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
    fi
fi