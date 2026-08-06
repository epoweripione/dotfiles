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

# [Command Code with your taste](https://commandcode.ai/)
INSTALLER_APP_NAME="command-code"
INSTALLER_GITHUB_REPO="CommandCodeAI/command-code"
INSTALLER_BINARY_NAME="cmdc"

INSTALLER_NPM_PACKAGE="command-code"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

# install nodejs & npm using fnm
fnm_Install_Nodejs

if [[ -x "$(command -v node)" && -x "$(command -v npm)" ]]; then
    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

        INSTALLER_CHECK_URL="https://commandcode.ai/rss.xml"
        App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" 'v([0-9]{1,}\.)+[0-9]{1,}'
        if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
            INSTALLER_IS_INSTALL="no"
        fi
    fi

    if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
        colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
        npm_Install_Global "${INSTALLER_NPM_PACKAGE}"
    fi
fi
