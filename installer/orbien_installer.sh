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

# [orbien - Intranet penetration built with Rust and Tokio](https://github.com/orbien-org/orbien)
INSTALLER_APP_NAME="orbien"
INSTALLER_GITHUB_REPO="orbien-org/orbien"

INSTALLER_BINARY_NAME="orbien"
INSTALLER_ARCHIVE_EXT="tar.gz"

INSTALLER_VERSION_TO_FILE="yes"

if [[ -x "$(command -v ${INSTALLER_BINARY_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
    App_Installer_Get_Installed_Version "${INSTALLER_BINARY_NAME}"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    # Server
    INSTALLER_VERSION_TO_FILE="yes"
    INSTALLER_BINARY_NAME="orbien-server"
    INSTALLER_MATCH_PATTERN="${INSTALLER_BINARY_NAME}_*"
    installPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"

    # Client
    INSTALLER_VERSION_TO_FILE="yes"
    INSTALLER_BINARY_NAME="orbien"
    INSTALLER_MATCH_PATTERN="${INSTALLER_BINARY_NAME}_*"
    installPrebuiltBinary "${INSTALLER_BINARY_NAME}" "${INSTALLER_GITHUB_REPO}" "${INSTALLER_MATCH_PATTERN}"
fi
