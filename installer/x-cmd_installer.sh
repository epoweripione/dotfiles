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

# [x-cmd: Bootstrap 1000+ command line tools in seconds](https://github.com/x-cmd/x-cmd)
INSTALLER_APP_NAME="x-cmd"
INSTALLER_GITHUB_REPO="x-cmd/x-cmd"

INSTALLER_INSTALL_NAME="x"

if [[ -x "$(command -v ${INSTALLER_INSTALL_NAME})" ]]; then
    x upgrade
else
    eval "$(curl https://get.x-cmd.com)"
fi
