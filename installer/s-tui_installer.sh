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

# s-tui: The Stress Terminal UI: s-tui
# https://github.com/amanusk/s-tui
INSTALLER_APP_NAME="s-tui"
INSTALLER_INSTALL_NAME="s-tui"
PIP_PACKAGE_NAME="s-tui"

if [[ -x "$(command -v pacman)" ]]; then
    PackagesList=(
        stress
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi

[[ ! -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]] && INSTALLER_IS_INSTALL="yes" || INSTALLER_IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"

[[ "${INSTALLER_IS_INSTALL}" == "yes" ]] && pip_Package_Install "${PIP_PACKAGE_NAME}"
