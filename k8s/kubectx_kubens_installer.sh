#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

[[ -z "${MY_SHELL_SCRIPTS}" ]] && MY_SHELL_SCRIPTS="$HOME/.dotfiles"

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

App_Installer_Reset

# [kubectx + kubens: Power tools for kubectl](https://github.com/ahmetb/kubectx)
INSTALLER_APP_NAME="kubectx"
INSTALLER_GITHUB_REPO="ahmetb/kubectx"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_INSTALL_NAME="kubectx"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    INSTALLER_VER_CURRENT=$(${INSTALLER_INSTALL_NAME} -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

installPrebuiltBinary "${INSTALLER_INSTALL_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_INSTALL_NAME}*"


# kubens
INSTALLER_APP_NAME="kubens"
INSTALLER_GITHUB_REPO="ahmetb/kubectx"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_INSTALL_NAME="kubens"

installPrebuiltBinary "${INSTALLER_INSTALL_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_INSTALL_NAME}*"


cd "${CURRENT_DIR}" || exit