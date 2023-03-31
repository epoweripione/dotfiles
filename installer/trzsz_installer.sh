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

# [trzsz is a simple file transfer tools, similar to lrzsz](https://trzsz.github.io/)
INSTALLER_APP_NAME="trzsz"
INSTALLER_GITHUB_REPO="trzsz/trzsz-go"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_ARCHIVE_EXEC_DIR="trzsz*"
INSTALLER_ARCHIVE_EXEC_NAME="trzsz trz tsz"

INSTALLER_INSTALL_NAME="trzsz"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -v 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if ! App_Installer_Install; then
    colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
fi

## Usage
## on Local
## Add trzsz before the shell to support trzsz (trz/tsz), e.g.:
# trzsz bash
# trzsz PowerShell
# trzsz ssh x.x.x.x

## Add trzsz --dragfile before the ssh to enable drag files and directories to upload, e.g.:
# trzsz -d ssh x.x.x.x
# trzsz --dragfile ssh x.x.x.x

## on Server
# Similar to lrzsz (rz/sz), command trz to upload files, command `tsz /path/to/file` to download files.

cd "${CURRENT_DIR}" || exit