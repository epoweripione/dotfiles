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

# NCurses Disk Usage
# https://dev.yorhel.nl/ncdu
APP_INSTALL_NAME="ncdu"
GITHUB_REPO_NAME=""

EXEC_INSTALL_PATH="/usr/local/bin"
EXEC_INSTALL_NAME="ncdu"

ARCHIVE_EXT="tar.gz"
ARCHIVE_EXEC_DIR=""
ARCHIVE_EXEC_NAME=""

MAN1_FILE="*.1"
ZSH_COMPLETION_FILE=""

IS_INSTALL="yes"
IS_UPDATE="no"

CURRENT_VERSION="0.0.0"
REMOTE_VERSION=""
VERSION_FILENAME=""

REMOTE_DOWNLOAD_URL=""

if [[ -x "$(command -v ${EXEC_INSTALL_NAME})" ]]; then
    IS_UPDATE="yes"
    CURRENT_VERSION=$(${EXEC_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    EXEC_FULL_NAME=$(readlink -f "$(which ${EXEC_INSTALL_NAME})")
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"
fi

if App_Installer_Get_Remote "https://dev.yorhel.nl/ncdu" 'ncdu-[^<>:;,?"*|/]+\.tar\.gz' "ncdu-.*\.tar\.gz"; then
    REMOTE_DOWNLOAD_URL="https://dev.yorhel.nl/download/${REMOTE_DOWNLOAD_URL}"
    if ! App_Installer_Install "https://dev.yorhel.nl/ncdu"; then
        colorEcho "${RED}  Install ${FUCHSIA}${APP_INSTALL_NAME}${RED} failed!"
    fi
fi

cd "${CURRENT_DIR}" || exit
