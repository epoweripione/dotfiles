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

# [ZeroClaw - Fast, small, and fully autonomous AI assistant infrastructure](https://github.com/zeroclaw-labs/zeroclaw)
INSTALLER_GITHUB_REPO="zeroclaw-labs/zeroclaw"
INSTALLER_BINARY_NAME="zeroclaw"

INSTALLER_ARCHIVE_EXT="tar.gz"
INSTALLER_MATCH_PATTERN="${INSTALLER_BINARY_NAME}*"

installPrebuiltBinary "${INSTALLER_BINARY_NAME}#${INSTALLER_GITHUB_REPO}#${INSTALLER_ARCHIVE_EXT}#${INSTALLER_MATCH_PATTERN}"
