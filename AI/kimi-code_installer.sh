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

# [Kimi Code CLI - The Starting Point for Next-Gen Agents](https://github.com/MoonshotAI/kimi-code)
INSTALLER_APP_NAME="kimi-code"
INSTALLER_GITHUB_REPO="MoonshotAI/kimi-code"
INSTALLER_BINARY_NAME="kimi"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."

    INSTALLER_CHECK_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" "jq=.tag_name@([0-9]{1,}\.)+[0-9]{1,}"
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}  Installing ${FUCHSIA}${INSTALLER_APP_NAME} ${YELLOW}${INSTALLER_VER_REMOTE}${BLUE}..."
    curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
fi
