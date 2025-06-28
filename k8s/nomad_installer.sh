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

# [Nomad - Orchestrate, deploy, and manage containers, binaries, and batch jobs in the cloud or on-prem](https://developer.hashicorp.com/nomad)
INSTALLER_APP_NAME="nomad"
INSTALLER_INSTALL_NAME="nomad"

INSTALLER_ARCHIVE_EXT="zip"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_INSTALL_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    colorEcho "${BLUE}Checking ${FUCHSIA}${INSTALLER_APP_NAME}${BLUE}..."
    INSTALLER_CHECK_URL="https://developer.hashicorp.com/nomad/install"
    App_Installer_Get_Remote_Version "${INSTALLER_CHECK_URL}" 'Nomad\s+([0-9]{1,}\.)+[0-9]{1,}\s+\(latest\)'
    if version_le "${INSTALLER_VER_REMOTE}" "${INSTALLER_VER_CURRENT}"; then
        INSTALLER_IS_INSTALL="no"
    fi
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    [[ -z "${OS_INFO_TYPE}" ]] && get_os_type
    [[ -z "${OS_INFO_ARCH}" ]] && get_arch

    INSTALLER_FILE_NAME="nomad_${INSTALLER_VER_REMOTE}_${OS_INFO_TYPE}_${OS_INFO_ARCH}.${INSTALLER_ARCHIVE_EXT}"
    INSTALLER_DOWNLOAD_URL="https://releases.hashicorp.com/nomad/${INSTALLER_VER_REMOTE}/${INSTALLER_FILE_NAME}"

    INSTALLER_DOWNLOAD_FILE="${WORKDIR}/${INSTALLER_FILE_NAME}"
    if ! App_Installer_Install "${INSTALLER_CHECK_URL}"; then
        colorEcho "${RED}  Install ${FUCHSIA}${INSTALLER_APP_NAME}${RED} failed!"
    fi
fi

cd "${CURRENT_DIR}" || exit
