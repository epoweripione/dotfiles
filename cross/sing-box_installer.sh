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

# sing-box: The universal proxy platform
# https://sing-box.sagernet.org/
APP_INSTALL_NAME="sing-box"
GITHUB_REPO_NAME="SagerNet/sing-box"

EXEC_INSTALL_NAME="sing-box"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR="sing-box-*"
ARCHIVE_EXEC_NAME="sing-box"

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} version 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
fi

cd "${CURRENT_DIR}" || exit
