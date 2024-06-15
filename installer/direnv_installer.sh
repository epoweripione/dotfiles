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

# # [direnv – unclutter your .profile](https://direnv.net/)
INSTALLER_GITHUB_REPO="direnv/direnv"
INSTALLER_BINARY_NAME="direnv"

INSTALLER_MATCH_PATTERN="direnv*"

INSTALLER_ARCHIVE_EXT=""

installPrebuiltBinary "${INSTALLER_BINARY_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_MATCH_PATTERN}"
