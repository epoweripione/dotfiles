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

[[ -z "${CURL_CHECK_OPTS[*]}" ]] && Get_Installer_CURL_Options
[[ -z "${AXEL_DOWNLOAD_OPTS[*]}" ]] && Get_Installer_AXEL_Options

# Funky takes shell functions to the next level by making them easier to define, more flexible, and more interactive.
# https://github.com/bbugyi200/funky
INSTALLER_APP_NAME="funky"
INSTALLER_INSTALL_NAME="funky"
PIP_PACKAGE_NAME="pyfunky"

[[ ! -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]] && INSTALLER_IS_INSTALL="yes" || INSTALLER_IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"

[[ "${INSTALLER_IS_INSTALL}" == "yes" ]] && pip_Package_Install "${PIP_PACKAGE_NAME}"


# Integrate funky into shell environment
if [[ ! -s "$HOME/.local/share/funky/funky.sh" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}funky shell Integrate script${BLUE}..."

    INSTALLER_DOWNLOAD_URL="https://raw.githubusercontent.com/bbugyi200/funky/master/scripts/shell/funky.sh"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/funky.sh"
    if App_Installer_Download "${INSTALLER_DOWNLOAD_URL}" "${INSTALLER_DOWNLOAD_FILE}"; then
        mkdir -p "$HOME/.local/share/funky" && \
            cp -f "${INSTALLER_DOWNLOAD_FILE}" "$HOME/.local/share/funky/funky.sh"

        # Save downloaded file to cache
        App_Installer_Save_to_Cache "${INSTALLER_APP_NAME}" "${INSTALLER_VER_REMOTE}" "${INSTALLER_DOWNLOAD_FILE}"
    fi
fi

# [[ -s "$HOME/.local/share/funky/funky.sh" ]] && source "$HOME/.local/share/funky/funky.sh"
