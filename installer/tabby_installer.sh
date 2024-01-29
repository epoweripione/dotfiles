#!/usr/bin/env bash

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

# [Tabby - a terminal for a more modern age](https://tabby.sh/)
INSTALLER_APP_NAME="Tabby"
INSTALLER_GITHUB_REPO="Eugeny/tabby"

INSTALLER_INSTALL_NAME="tabby"
# INSTALLER_VER_FILE="/opt/tabby/${INSTALLER_INSTALL_NAME}.version"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} --version | grep -Eo '([0-9]{1,}\.)+[0-9a-zA-Z]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking latest version for ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}"
    version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}" && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    if check_os_arch; then
        if App_Installer_Get_Remote_URL "https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest" "tabby-.*\.pacman"; then
            if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "$(xdg-user-dir DOWNLOAD)/tabby.pacman"; then
                sudo pacman -U "$(xdg-user-dir DOWNLOAD)/tabby.pacman"
                [[ -n "${INSTALLER_VER_FILE}" ]] && echo "${INSTALLER_VER_REMOTE}" | sudo tee "${INSTALLER_VER_FILE}" >/dev/null || true
            else
                colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
            fi
        fi
    else
        colorEcho "The ${FUCHSIA}${INSTALLER_APP_NAME}${RED} installer only for Arch-Based Linux Distributions!"
    fi
fi
