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

# Ciphey: Automatically decrypt encryptions without knowing the key or cipher, decode encodings, and crack hashes
# https://github.com/Ciphey/Ciphey
APP_INSTALL_NAME="ciphey"
EXEC_INSTALL_NAME="ciphey"
PIP_PACKAGE_NAME="ciphey"

[[ ! -x "$(command -v ${EXEC_INSTALL_NAME})" ]] && IS_INSTALL="yes" || IS_INSTALL="no"
[[ "${IS_UPDATE_ONLY}" == "yes" ]] && IS_INSTALL="no"

[[ "${IS_INSTALL}" == "yes" ]] && pip_Package_Install "${PIP_PACKAGE_NAME}"
