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

# You-Get is a tiny command-line utility to download media contents (videos, audios, images) from the Web, in case there is no other handy way to do it.
# https://you-get.org/
INSTALLER_APP_NAME="You-Get"
INSTALLER_INSTALL_NAME="you-get"
PIP_PACKAGE_NAME="you-get"

[[ ! -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]] && INSTALLER_IS_INSTALL="yes" || INSTALLER_IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    pip_Package_Install "${PIP_PACKAGE_NAME}"

    # FFmpeg https://www.ffmpeg.org/
    PackagesList=(
        ffmpeg
    )
    InstallSystemPackages "" "${PackagesList[@]}"
fi
