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

# [Tailcat - like netcat, but over Tailscale's data plane, without Tailscale's control plane](https://github.com/tailscale/tailcat)
INSTALLER_APP_NAME="tailcat"
INSTALLER_GITHUB_REPO="tailscale/tailcat"

INSTALLER_INSTALL_NAME="tailcat"

INSTALLER_VERSION_TO_FILE="yes"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    INSTALLER_IS_UPDATE="yes"
else
    [[ "${IS_UPDATE_ONLY}" == "yes" ]] && INSTALLER_IS_INSTALL="no"
fi

[[ ! -x "$(command -v go)" ]] && INSTALLER_IS_INSTALL="no"

if [[ "${INSTALLER_IS_INSTALL}" == "yes" ]]; then
    installBuildBinary tailcat tailcat go "github.com/tailscale/tailcat/cmd/tailcat@latest"
fi

cd "${CURRENT_DIR}" || exit