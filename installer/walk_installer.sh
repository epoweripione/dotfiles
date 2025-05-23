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

# walk: Terminal file manager
# https://github.com/antonmedv/walk
INSTALLER_APP_NAME="walk"
INSTALLER_GITHUB_REPO="antonmedv/walk"

INSTALLER_INSTALL_NAME="walk"

INSTALLER_VERSION_TO_FILE="yes"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_INSTALL_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

REMOTE_URL="https://api.github.com/repos/${INSTALLER_GITHUB_REPO}/releases/latest"
if App_Installer_Get_Remote_URL "${REMOTE_URL}" 'walk_.*' "walk_.*"; then
    if App_Installer_Install; then
        :
    else
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi

# export walk_EDITOR=nano
# function llcd() {
#     walk "$@" 2> /tmp/path && cd "$(cat /tmp/path)" || return 0
# }

cd "${CURRENT_DIR}" || exit
